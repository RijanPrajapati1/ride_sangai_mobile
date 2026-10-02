import { constants as zlib } from 'node:zlib';
import compress from '@fastify/compress';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import underPressure from '@fastify/under-pressure';
import fp from 'fastify-plugin';
import type { AppError } from '../utils/errors.js';
import { tooManyRequests } from '../utils/errors.js';

/**
 * Transport hardening and protection:
 *  - helmet: safe default security headers (CSP off — this is a JSON API).
 *  - cors: native mobile apps ignore CORS; the allow-list matters for web clients.
 *  - compress: gzip/brotli for JSON over mobile networks (bodies >= 1 KB).
 *  - rate-limit: per user when authenticated, otherwise per IP. Credential
 *    endpoints add a stricter per-route limit (see modules/auth).
 *  - under-pressure: sheds load with 503 when the event loop is saturated
 *    instead of letting every request slow to a crawl.
 */
export default fp(
  async (app) => {
    const { config } = app;

    await app.register(helmet, {
      contentSecurityPolicy: false,
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      hsts: config.isProduction,
    });

    await app.register(cors, {
      origin: config.corsOrigins,
      methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['authorization', 'content-type', 'x-request-id'],
      exposedHeaders: [
        'x-request-id',
        'retry-after',
        'x-ratelimit-limit',
        'x-ratelimit-remaining',
        'x-ratelimit-reset',
      ],
      maxAge: 86_400,
    });

    await app.register(compress, {
      global: true,
      threshold: 1024,
      encodings: ['br', 'gzip', 'deflate'],
      brotliOptions: { params: { [zlib.BROTLI_PARAM_QUALITY]: 4 } },
    });

    if (config.rateLimit.enabled) {
      await app.register(rateLimit, {
        global: true,
        max: config.rateLimit.max,
        timeWindow: config.rateLimit.windowMs,
        keyGenerator: (request) => (request.user ? `user:${request.user.id}` : `ip:${request.ip}`),
        errorResponseBuilder: (_request, context): AppError => {
          const error = tooManyRequests(`Too many requests. Try again in ${context.after}.`);
          return Object.assign(error, { statusCode: context.statusCode });
        },
      });
    }

    await app.register(underPressure, {
      maxEventLoopDelay: 1_000,
      maxEventLoopUtilization: 0.98,
      retryAfter: 10,
      exposeStatusRoute: false,
    });
  },
  { name: 'security', dependencies: ['authenticate'] },
);
