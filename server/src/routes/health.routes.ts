import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { Type } from 'typebox';

const tags = ['Health'];

/**
 * Liveness (`/health`) never touches dependencies, so a slow database does not
 * get the process killed; readiness (`/health/ready`) checks Postgres so load
 * balancers stop routing traffic to an instance that cannot serve it.
 */
const healthRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const started = Date.now();

  app.get(
    '/health',
    {
      config: { auth: 'none', rateLimit: false },
      schema: {
        tags,
        summary: 'Liveness probe',
        response: { 200: Type.Object({ status: Type.Literal('ok'), uptimeSeconds: Type.Integer() }) },
      },
    },
    async () => ({ status: 'ok' as const, uptimeSeconds: Math.floor((Date.now() - started) / 1000) }),
  );

  app.get(
    '/health/ready',
    {
      config: { auth: 'none', rateLimit: false },
      schema: {
        tags,
        summary: 'Readiness probe (checks the database)',
        response: {
          200: Type.Object({ status: Type.Literal('ready'), database: Type.Literal('up'), latencyMs: Type.Number() }),
          503: Type.Object({ status: Type.Literal('unavailable'), database: Type.Literal('down') }),
        },
      },
    },
    async (_request, reply) => {
      const t0 = performance.now();
      try {
        await app.prisma.$queryRaw`SELECT 1`;
        return { status: 'ready' as const, database: 'up' as const, latencyMs: Math.round((performance.now() - t0) * 100) / 100 };
      } catch (err) {
        app.log.error({ err }, 'Readiness check failed');
        return reply.status(503).send({ status: 'unavailable' as const, database: 'down' as const });
      }
    },
  );
};

export default healthRoutes;
