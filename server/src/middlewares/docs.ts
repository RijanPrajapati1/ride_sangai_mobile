import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import type { RouteOptions } from 'fastify';
import fp from 'fastify-plugin';

/**
 * OpenAPI 3 document generated from the route schemas.
 *   - Interactive docs: GET /docs
 *   - Raw spec:         GET /docs/json
 * Routes that need a token are marked with the bearer security scheme
 * automatically, based on their `config.auth`.
 */
export default fp(
  async (app) => {
    await app.register(swagger, {
      openapi: {
        openapi: '3.1.0',
        info: {
          title: 'Ride Sangai API',
          version: '1.0.0',
          description:
            'Backend for the Ride Sangai mobile app: group rides, treks, hikes and motorbike meetups, ' +
            'with community posts, direct messages, groups and notifications.\n\n' +
            'Authenticate with `POST /api/v1/auth/login`, then send `Authorization: Bearer <accessToken>`. ' +
            'Errors always use the envelope `{ error: { code, message, details? }, requestId }`.',
        },
        servers: [{ url: app.config.publicUrl }],
        components: {
          securitySchemes: {
            bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
          },
        },
      },
      transform: ({ schema, url, route }) => {
        const auth = route.config?.auth ?? 'required';
        const transformed = { ...(schema ?? {}) } as Record<string, unknown>;
        if (auth !== 'none' && !transformed.security) {
          transformed.security = [{ bearerAuth: [] }];
        }
        return { schema: transformed, url };
      },
    });

    // The docs pages themselves are public.
    await app.register(async (child) => {
      child.addHook('onRoute', markPublic);
      await child.register(swaggerUi, {
        routePrefix: '/docs',
        uiConfig: { docExpansion: 'list', deepLinking: true, persistAuthorization: true },
      });
    });
  },
  { name: 'docs' },
);

/** `onRoute` hook that makes every route in its context public (no token read). */
export function markPublic(route: RouteOptions): void {
  route.config = { ...(route.config ?? {}), auth: 'none' } as RouteOptions['config'];
}
