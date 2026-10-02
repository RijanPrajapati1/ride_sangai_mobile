import { SignJWT, errors as joseErrors, jwtVerify } from 'jose';
import type { AppConfig } from '../config/env.js';
import type { AuthRepository } from '../repositories/auth.repository.js';
import type { UserRole } from '../constants/enums.js';
import { unauthorized } from '../utils/errors.js';
import { TtlCache } from '../utils/ttl-cache.js';

/** The authenticated caller, available as `request.user` on protected routes. */
export interface AuthContext {
  id: string;
  role: UserRole;
  name: string;
  sessionId: string;
}

interface AccessTokenClaims {
  sub: string;
  sid: string;
  role: UserRole;
}

/**
 * Access tokens are short-lived HS256 JWTs carrying the user id (`sub`) and
 * the session id (`sid`). Every request re-checks that the session is still
 * active, so logout, "log out everywhere", password resets and account
 * removal take effect immediately. A short in-memory cache (default 5s)
 * absorbs bursts of requests from the same client.
 */
export class TokenService {
  private readonly secret: Uint8Array;
  private readonly sessionCache: TtlCache<string, AuthContext>;

  constructor(
    private readonly config: AppConfig['auth'],
    private readonly authRepo: AuthRepository,
  ) {
    this.secret = new TextEncoder().encode(config.accessTokenSecret);
    this.sessionCache = new TtlCache(config.sessionCacheTtlMs);
  }

  async signAccessToken(claims: AccessTokenClaims): Promise<{ token: string; expiresAt: Date }> {
    const expiresAt = new Date(Date.now() + this.config.accessTokenTtlSeconds * 1000);
    const token = await new SignJWT({ sid: claims.sid, role: claims.role })
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setSubject(claims.sub)
      .setIssuer(this.config.issuer)
      .setIssuedAt()
      .setExpirationTime(Math.floor(expiresAt.getTime() / 1000))
      .sign(this.secret);
    return { token, expiresAt };
  }

  /** Verifies signature, expiry and that the session is still active. Throws 401 otherwise. */
  async authenticate(token: string): Promise<AuthContext> {
    let sub: string | undefined;
    let sid: unknown;
    try {
      const { payload } = await jwtVerify(token, this.secret, {
        issuer: this.config.issuer,
        algorithms: ['HS256'],
      });
      sub = payload.sub;
      sid = payload.sid;
    } catch (err) {
      if (err instanceof joseErrors.JWTExpired) {
        throw unauthorized('Your session has expired. Please refresh your token.', 'TOKEN_EXPIRED');
      }
      throw unauthorized('The access token is invalid.', 'TOKEN_INVALID');
    }
    if (typeof sub !== 'string' || typeof sid !== 'string') {
      throw unauthorized('The access token is invalid.', 'TOKEN_INVALID');
    }

    const cached = this.sessionCache.get(sid);
    if (cached && cached.id === sub) return cached;

    const session = await this.authRepo.findActiveSessionUser(sid, sub);
    if (!session) throw unauthorized('Your session has ended. Please sign in again.', 'SESSION_REVOKED');

    const context: AuthContext = { id: session.user.id, role: session.user.role, name: session.user.name, sessionId: sid };
    this.sessionCache.set(sid, context);
    return context;
  }

  /** Drops cached sessions so revocations are visible immediately on this instance. */
  forgetSession(sessionId: string): void {
    this.sessionCache.delete(sessionId);
  }

  forgetUser(userId: string): void {
    this.sessionCache.deleteWhere((context) => context.id === userId);
  }
}
