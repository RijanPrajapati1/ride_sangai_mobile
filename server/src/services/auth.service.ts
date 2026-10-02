import type { FastifyBaseLogger } from 'fastify';
import type { AppConfig } from '../config/env.js';
import type { Db, UnitOfWork } from '../db/prisma.js';
import type { RealtimeHub } from '../realtime/hub.js';
import type { AuthRepository, AuthUserRecord } from '../repositories/auth.repository.js';
import { generateToken, hashToken } from '../utils/crypto.js';
import { isUniqueViolation } from '../utils/db-errors.js';
import { badRequest, conflict, notFound, unauthorized } from '../utils/errors.js';
import type { Mailer } from '../utils/mailer.js';
import type { PasswordHasher } from '../utils/password.js';
import type { TokenService } from './token.service.js';

export interface ClientInfo {
  userAgent: string | null;
  ip: string | null;
}

/** Mirrors the Dart `AuthUser` entity. */
export interface AuthUserDto {
  id: string;
  name: string;
  email: string;
  avatarUrl: string;
  isAdmin: boolean;
}

export interface AuthResult {
  user: AuthUserDto;
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  accessTokenExpiresAt: Date;
  refreshTokenExpiresAt: Date;
}

type RefreshOutcome =
  | { ok: true; result: AuthResult }
  | { ok: false; error: 'invalid' | 'revoked' | 'expired' }
  | { ok: false; error: 'reused'; sessionId: string };

export function toAuthUser(
  user: Pick<AuthUserRecord, 'id' | 'name' | 'email' | 'avatarUrl' | 'role'>,
): AuthUserDto {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    avatarUrl: user.avatarUrl,
    isAdmin: user.role === 'admin',
  };
}

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

/** Registration, login, token rotation, logout and password reset. */
export class AuthService {
  constructor(
    private readonly uow: UnitOfWork,
    private readonly repo: AuthRepository,
    private readonly config: AppConfig['auth'],
    private readonly passwords: PasswordHasher,
    private readonly tokens: TokenService,
    private readonly mailer: Mailer,
    private readonly realtime: RealtimeHub,
    private readonly log: FastifyBaseLogger,
  ) {}

  async register(
    input: { name: string; email: string; password: string },
    client: ClientInfo,
  ): Promise<AuthResult> {
    const email = normalizeEmail(input.email);
    const passwordHash = await this.passwords.hash(input.password);
    try {
      return await this.uow.run(async ({ db }) => {
        const user = await this.repo.createUser(db, { email, name: input.name.trim(), passwordHash });
        return this.issueSession(db, user, client);
      });
    } catch (err) {
      if (isUniqueViolation(err)) throw conflict('An account with this email already exists.', 'EMAIL_TAKEN');
      throw err;
    }
  }

  async login(input: { email: string; password: string }, client: ClientInfo): Promise<AuthResult> {
    const user = await this.repo.findUserByEmail(normalizeEmail(input.email));
    // Unknown emails still pay for a hash verification so timing does not reveal accounts.
    const valid = user
      ? await this.passwords.verify(user.passwordHash, input.password)
      : await this.passwords.verifyDummy(input.password);
    if (!user || !valid) throw unauthorized('Invalid email or password.', 'INVALID_CREDENTIALS');

    if (this.passwords.needsRehash(user.passwordHash)) {
      await this.repo.updatePasswordHash(user.id, await this.passwords.hash(input.password));
    }
    const result = await this.uow.run(({ db }) => this.issueSession(db, user, client));
    await this.repo.touchLastLogin(user.id);
    return result;
  }

  /**
   * Rotates a refresh token. Each refresh token is single-use; presenting one
   * that was already used means it leaked (or a client replayed it), so the
   * whole session is revoked and the user must sign in again.
   */
  async refresh(refreshToken: string): Promise<AuthResult> {
    const tokenHash = hashToken(refreshToken);
    const outcome = await this.uow.run(async ({ db }): Promise<RefreshOutcome> => {
      const token = await this.repo.findRefreshTokenForUpdate(db, tokenHash);
      if (!token) return { ok: false, error: 'invalid' };
      if (token.session_revoked_at || token.session_expires_at <= new Date())
        return { ok: false, error: 'revoked' };
      if (token.used_at) {
        await this.repo.revokeSession(token.session_id, 'refresh_token_reuse', db);
        return { ok: false, error: 'reused', sessionId: token.session_id };
      }
      if (token.expires_at <= new Date()) return { ok: false, error: 'expired' };

      const user = await this.repo.findUserById(token.user_id, db);
      if (!user) return { ok: false, error: 'revoked' };

      await this.repo.markRefreshTokenUsed(db, token.id);
      const next = await this.createRefreshToken(db, token.session_id);
      await this.repo.extendSession(db, token.session_id, next.expiresAt);
      const access = await this.tokens.signAccessToken({
        sub: user.id,
        sid: token.session_id,
        role: user.role,
      });
      return { ok: true, result: this.toResult(user, access, next) };
    });

    if (outcome.ok) return outcome.result;
    switch (outcome.error) {
      case 'reused':
        this.tokens.forgetSession(outcome.sessionId);
        this.log.warn({ sessionId: outcome.sessionId }, 'Refresh token reuse detected; session revoked');
        throw unauthorized(
          'This session was ended for your security. Please sign in again.',
          'REFRESH_TOKEN_REUSED',
        );
      case 'expired':
        throw unauthorized('Your session has expired. Please sign in again.', 'REFRESH_TOKEN_EXPIRED');
      case 'revoked':
        throw unauthorized('Your session has ended. Please sign in again.', 'SESSION_REVOKED');
      case 'invalid':
        throw unauthorized('The refresh token is invalid.', 'REFRESH_TOKEN_INVALID');
    }
  }

  async logout(sessionId: string): Promise<void> {
    await this.repo.revokeSession(sessionId, 'logout');
    this.tokens.forgetSession(sessionId);
  }

  async logoutAll(userId: string): Promise<void> {
    await this.repo.revokeUserSessions(userId, 'logout_all');
    this.tokens.forgetUser(userId);
    this.realtime.disconnectUser(userId, 'logged out everywhere');
  }

  listSessions(userId: string) {
    return this.repo.listActiveSessions(userId);
  }

  async revokeOwnSession(userId: string, sessionId: string): Promise<void> {
    const sessions = await this.repo.listActiveSessions(userId);
    if (!sessions.some((session) => session.id === sessionId))
      throw notFound('Session not found.', 'SESSION_NOT_FOUND');
    await this.repo.revokeSession(sessionId, 'revoked_by_user');
    this.tokens.forgetSession(sessionId);
  }

  /** Always "succeeds" for the caller, so the endpoint cannot reveal which emails have accounts. */
  async requestPasswordReset(rawEmail: string): Promise<void> {
    const user = await this.repo.findUserByEmail(normalizeEmail(rawEmail));
    if (!user) return;
    const token = generateToken();
    const ttl = this.config.passwordResetTtlMinutes;
    await this.uow.run(({ db }) =>
      this.repo.createPasswordResetToken(db, {
        userId: user.id,
        tokenHash: hashToken(token),
        expiresAt: new Date(Date.now() + ttl * 60_000),
      }),
    );
    try {
      await this.mailer.sendPasswordReset({
        to: user.email,
        name: user.name,
        resetUrl: this.config.passwordResetUrl.replace('{token}', encodeURIComponent(token)),
        expiresInMinutes: ttl,
      });
    } catch (err) {
      this.log.error({ err, userId: user.id }, 'Failed to send password reset email');
    }
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const passwordHash = await this.passwords.hash(newPassword);
    const userId = await this.uow.run(async ({ db }) => {
      const reset = await this.repo.findUsablePasswordResetForUpdate(db, hashToken(token));
      if (!reset) return null;
      await this.repo.markPasswordResetUsed(db, reset.id);
      await this.repo.updatePasswordHash(reset.user_id, passwordHash, db);
      await this.repo.revokeUserSessions(reset.user_id, 'password_reset', {}, db);
      return reset.user_id;
    });
    if (!userId) throw badRequest('This reset link is invalid or has expired.', 'INVALID_RESET_TOKEN');
    this.tokens.forgetUser(userId);
    this.realtime.disconnectUser(userId, 'password changed');
  }

  async changePassword(
    user: { id: string; sessionId: string },
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const record = await this.repo.findUserById(user.id);
    if (!record) throw unauthorized();
    if (!(await this.passwords.verify(record.passwordHash, currentPassword))) {
      throw badRequest('Your current password is incorrect.', 'WRONG_PASSWORD');
    }
    const passwordHash = await this.passwords.hash(newPassword);
    await this.uow.run(async ({ db }) => {
      await this.repo.updatePasswordHash(user.id, passwordHash, db);
      await this.repo.revokeUserSessions(
        user.id,
        'password_changed',
        { exceptSessionId: user.sessionId },
        db,
      );
    });
    this.tokens.forgetUser(user.id);
  }

  async me(userId: string): Promise<AuthUserDto> {
    const user = await this.repo.findUserById(userId);
    if (!user) throw unauthorized('Your account no longer exists.', 'SESSION_REVOKED');
    return toAuthUser(user);
  }

  private async issueSession(db: Db, user: AuthUserRecord, client: ClientInfo): Promise<AuthResult> {
    const refreshExpiresAt = this.refreshExpiry();
    const sessionId = await this.repo.createSession(db, {
      userId: user.id,
      userAgent: client.userAgent?.slice(0, 255) ?? null,
      ip: client.ip?.slice(0, 64) ?? null,
      expiresAt: refreshExpiresAt,
    });
    const refresh = await this.createRefreshToken(db, sessionId, refreshExpiresAt);
    const access = await this.tokens.signAccessToken({ sub: user.id, sid: sessionId, role: user.role });
    return this.toResult(user, access, refresh);
  }

  private async createRefreshToken(db: Db, sessionId: string, expiresAt = this.refreshExpiry()) {
    const token = generateToken();
    await this.repo.createRefreshToken(db, { sessionId, tokenHash: hashToken(token), expiresAt });
    return { token, expiresAt };
  }

  private refreshExpiry(): Date {
    return new Date(Date.now() + this.config.refreshTokenTtlDays * 86_400_000);
  }

  private toResult(
    user: AuthUserRecord,
    access: { token: string; expiresAt: Date },
    refresh: { token: string; expiresAt: Date },
  ): AuthResult {
    return {
      user: toAuthUser(user),
      accessToken: access.token,
      refreshToken: refresh.token,
      tokenType: 'Bearer',
      expiresIn: this.config.accessTokenTtlSeconds,
      accessTokenExpiresAt: access.expiresAt,
      refreshTokenExpiresAt: refresh.expiresAt,
    };
  }
}
