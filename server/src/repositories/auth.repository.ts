import type { UserRole } from '../constants/enums.js';
import type { Db, PrismaClient } from '../db/prisma.js';

export interface AuthUserRecord {
  id: string;
  email: string;
  name: string;
  avatarUrl: string;
  role: UserRole;
  passwordHash: string;
}

const authUserSelect = {
  id: true,
  email: true,
  name: true,
  avatarUrl: true,
  role: true,
  passwordHash: true,
} as const;

/** Data access for accounts, sessions and auth tokens. */
export class AuthRepository {
  constructor(private readonly prisma: PrismaClient) {}

  findUserByEmail(email: string, db: Db = this.prisma): Promise<AuthUserRecord | null> {
    return db.user.findUnique({ where: { email }, select: authUserSelect });
  }

  findUserById(id: string, db: Db = this.prisma): Promise<AuthUserRecord | null> {
    return db.user.findUnique({ where: { id }, select: authUserSelect });
  }

  /** Creates the user together with their default preferences row. */
  createUser(db: Db, user: { email: string; name: string; passwordHash: string }): Promise<AuthUserRecord> {
    return db.user.create({
      data: { ...user, preferences: { create: {} } },
      select: authUserSelect,
    });
  }

  async touchLastLogin(userId: string, db: Db = this.prisma): Promise<void> {
    await db.user.update({ where: { id: userId }, data: { lastLoginAt: new Date() }, select: { id: true } });
  }

  async updatePasswordHash(userId: string, passwordHash: string, db: Db = this.prisma): Promise<void> {
    await db.user.update({ where: { id: userId }, data: { passwordHash }, select: { id: true } });
  }

  async createSession(
    db: Db,
    session: { userId: string; userAgent: string | null; ip: string | null; expiresAt: Date },
  ): Promise<string> {
    const row = await db.session.create({ data: session, select: { id: true } });
    return row.id;
  }

  async createRefreshToken(
    db: Db,
    token: { sessionId: string; tokenHash: string; expiresAt: Date },
  ): Promise<void> {
    await db.refreshToken.create({ data: token, select: { id: true } });
  }

  /**
   * Loads a refresh token with row locks on the token and its session, so two
   * concurrent refreshes of the same token are serialised.
   */
  async findRefreshTokenForUpdate(db: Db, tokenHash: string) {
    const rows = await db.$queryRaw<
      Array<{
        id: string;
        session_id: string;
        used_at: Date | null;
        expires_at: Date;
        user_id: string;
        session_revoked_at: Date | null;
        session_expires_at: Date;
      }>
    >`SELECT rt.id, rt.session_id, rt.used_at, rt.expires_at,
             s.user_id, s.revoked_at AS session_revoked_at, s.expires_at AS session_expires_at
        FROM refresh_tokens rt
        JOIN sessions s ON s.id = rt.session_id
       WHERE rt.token_hash = ${tokenHash}
       FOR UPDATE OF rt, s`;
    return rows[0] ?? null;
  }

  async markRefreshTokenUsed(db: Db, id: string): Promise<void> {
    await db.refreshToken.update({ where: { id }, data: { usedAt: new Date() }, select: { id: true } });
  }

  async extendSession(db: Db, sessionId: string, expiresAt: Date): Promise<void> {
    await db.session.update({
      where: { id: sessionId },
      data: { lastUsedAt: new Date(), expiresAt },
      select: { id: true },
    });
  }

  /** Validates an access token's session; returns the caller or null if revoked/expired. */
  findActiveSessionUser(sessionId: string, userId: string) {
    return this.prisma.session.findFirst({
      where: { id: sessionId, userId, revokedAt: null, expiresAt: { gt: new Date() } },
      select: { user: { select: { id: true, role: true, name: true } } },
    });
  }

  async revokeSession(sessionId: string, reason: string, db: Db = this.prisma): Promise<boolean> {
    const result = await db.session.updateMany({
      where: { id: sessionId, revokedAt: null },
      data: { revokedAt: new Date(), revokedReason: reason },
    });
    return result.count > 0;
  }

  async revokeUserSessions(
    userId: string,
    reason: string,
    options: { exceptSessionId?: string } = {},
    db: Db = this.prisma,
  ) {
    await db.session.updateMany({
      where: {
        userId,
        revokedAt: null,
        ...(options.exceptSessionId ? { id: { not: options.exceptSessionId } } : {}),
      },
      data: { revokedAt: new Date(), revokedReason: reason },
    });
  }

  listActiveSessions(userId: string) {
    return this.prisma.session.findMany({
      where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { lastUsedAt: 'desc' },
      select: { id: true, userAgent: true, ip: true, createdAt: true, lastUsedAt: true, expiresAt: true },
    });
  }

  /** Issues a reset token and invalidates any earlier unused ones. */
  async createPasswordResetToken(
    db: Db,
    reset: { userId: string; tokenHash: string; expiresAt: Date },
  ): Promise<void> {
    await db.passwordResetToken.updateMany({
      where: { userId: reset.userId, usedAt: null },
      data: { usedAt: new Date() },
    });
    await db.passwordResetToken.create({ data: reset, select: { id: true } });
  }

  async findUsablePasswordResetForUpdate(db: Db, tokenHash: string) {
    const rows = await db.$queryRaw<Array<{ id: string; user_id: string }>>`
      SELECT id, user_id FROM password_reset_tokens
       WHERE token_hash = ${tokenHash} AND used_at IS NULL AND expires_at > now()
       FOR UPDATE`;
    return rows[0] ?? null;
  }

  async markPasswordResetUsed(db: Db, id: string): Promise<void> {
    await db.passwordResetToken.update({ where: { id }, data: { usedAt: new Date() }, select: { id: true } });
  }

  /** Housekeeping: removes expired/revoked sessions and stale tokens. Returns rows removed. */
  async purgeExpired(): Promise<number> {
    const now = Date.now();
    const dayAgo = new Date(now - 86_400_000);
    const weekAgo = new Date(now - 7 * 86_400_000);
    const [sessions, tokens, resets] = await this.prisma.$transaction([
      this.prisma.session.deleteMany({
        where: { OR: [{ expiresAt: { lt: dayAgo } }, { revokedAt: { lt: dayAgo } }] },
      }),
      // Used refresh tokens are kept for a week so replaying one is still detected as reuse.
      this.prisma.refreshToken.deleteMany({
        where: { OR: [{ expiresAt: { lt: new Date(now) } }, { usedAt: { lt: weekAgo } }] },
      }),
      this.prisma.passwordResetToken.deleteMany({ where: { expiresAt: { lt: dayAgo } } }),
    ]);
    return sessions.count + tokens.count + resets.count;
  }
}
