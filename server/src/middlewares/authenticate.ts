import type { FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';
import type { AuthContext } from '../services/token.service.js';
import { forbidden, unauthorized } from '../utils/errors.js';

function bearerToken(request: FastifyRequest): string | undefined {
  const header = request.headers.authorization;
  if (header) {
    const [scheme, token] = header.split(' ');
    if (scheme?.toLowerCase() === 'bearer' && token) return token.trim();
    return undefined;
  }
  if (request.routeOptions.config.allowQueryToken) {
    const token = (request.query as Record<string, unknown> | undefined)?.access_token;
    if (typeof token === 'string' && token) return token;
  }
  return undefined;
}

/**
 * Authenticates every request according to the route's `config.auth`
 * (see types/fastify.ts). Runs in `onRequest`, before the body is parsed, so
 * unauthenticated requests are rejected as cheaply as possible.
 */
export default fp(
  async (app) => {
    app.decorateRequest('user', null);

    app.addHook('onRequest', async (request) => {
      if (request.is404) return;
      // CORS preflights never carry a token; @fastify/cors answers them.
      if (request.method === 'OPTIONS') return;
      const config = request.routeOptions.config;
      const mode = config.auth ?? 'required';
      if (mode === 'none') return;

      const token = bearerToken(request);
      if (!token) {
        if (mode === 'optional') return;
        throw unauthorized();
      }
      // An invalid or expired token is a 401 even on optional routes, so the
      // client knows to refresh instead of silently getting anonymous data.
      const user = await app.services.tokens.authenticate(token);
      if (config.roles && !config.roles.includes(user.role)) throw forbidden();
      request.user = user;
    });
  },
  { name: 'authenticate' },
);

/** The caller on a route with `auth: 'required'` (the default). */
export function currentUser(request: FastifyRequest): AuthContext {
  if (!request.user) throw unauthorized();
  return request.user;
}
