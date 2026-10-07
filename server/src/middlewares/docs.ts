import swagger from '@fastify/swagger';
import swaggerUi, { type FastifySwaggerUiOptions } from '@fastify/swagger-ui';
import type { RouteOptions } from 'fastify';
import fp from 'fastify-plugin';
import { documentFor, type DocsVariant } from '../docs/openapi.js';
import { rememberToken } from '../docs/auth-token.js';

/**
 * OpenAPI 3 documents generated from the route schemas.
 *   - Interactive docs:   GET /docs  (dropdown: Mobile app / Superadmin web)
 *   - Per-audience specs: GET /docs/mobile.json, GET /docs/superadmin.json
 *   - Full spec:          GET /docs/json
 * Routes that need a token are marked with the bearer security scheme
 * automatically, based on their `config.auth`.
 */
export default fp(
  async (app) => {
    await app.register(swagger, {
      openapi: {
        openapi: '3.1.0',
        info: {
          title: 'Yatrix API',
          version: '1.0.0',
          description: 'Mobile app and superadmin dashboard API. Pick a definition at the top of /docs.',
        },
        servers: [{ url: app.config.publicUrl, description: 'This server' }],
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

      const cache = new Map<DocsVariant, unknown>();
      const variant = (name: DocsVariant) => () => {
        if (!cache.has(name)) {
          cache.set(name, documentFor(app.swagger() as Parameters<typeof documentFor>[0], name, app.config));
        }
        return cache.get(name);
      };
      child.get('/docs/mobile.json', { schema: { hide: true } }, variant('mobile'));
      child.get('/docs/superadmin.json', { schema: { hide: true } }, variant('superadmin'));

      await child.register(swaggerUi, {
        routePrefix: '/docs',
        uiConfig: {
          urls: [
            { url: '/docs/mobile.json', name: 'Mobile app API' },
            { url: '/docs/superadmin.json', name: 'Superadmin (web) API' },
          ],
          docExpansion: 'list',
          deepLinking: true,
          persistAuthorization: true,
          // Serialised into the page as source; it runs in the browser, not here.
          responseInterceptor: rememberToken as unknown as NonNullable<
            FastifySwaggerUiOptions['uiConfig']
          >['responseInterceptor'],
        },
      });
    });
  },
  { name: 'docs' },
);

/** `onRoute` hook that makes every route in its context public (no token read). */
export function markPublic(route: RouteOptions): void {
  route.config = { ...(route.config ?? {}), auth: 'none' } as RouteOptions['config'];
}
