import type { AppConfig } from '../config/env.js';
import type { UserRole } from '../constants/enums.js';
import type { PrismaClient } from '../db/prisma.js';
import type { RealtimeHub } from '../realtime/hub.js';
import type { Services } from '../services/index.js';
import type { AuthContext } from '../services/token.service.js';

/**
 * Route-level access control, set per route via `config`:
 *   - 'required' (default) — a valid access token is needed; `request.user` is set.
 *   - 'optional' — `request.user` is set when a valid token is sent, else null.
 *   - 'none'     — public; no token is read.
 * `roles` additionally restricts the route (e.g. `['superadmin']`).
 * Secure by default: a route that forgets `config.auth` requires a login.
 */
export type AuthMode = 'required' | 'optional' | 'none';

declare module 'fastify' {
  interface FastifyInstance {
    config: AppConfig;
    prisma: PrismaClient;
    realtime: RealtimeHub;
    services: Services;
  }

  interface FastifyRequest {
    /** The authenticated caller; null on public routes or when no token was sent to an optional route. */
    user: AuthContext | null;
  }

  interface FastifyContextConfig {
    auth?: AuthMode;
    roles?: readonly UserRole[];
    /** Allow the access token in `?access_token=` (WebSocket upgrades only). */
    allowQueryToken?: boolean;
  }
}

export {};
