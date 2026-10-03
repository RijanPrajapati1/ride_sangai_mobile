import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { Type } from 'typebox';
import { currentUser } from '../middlewares/authenticate.js';
import { PgFanout } from '../realtime/pg-fanout.js';

const HEARTBEAT_MS = 30_000;
const SESSION_CHECK_MS = 60_000;

/**
 * GET /api/v1/ws — WebSocket for live events.
 *
 * Authenticate with `Authorization: Bearer <accessToken>` or, where headers
 * cannot be set, `?access_token=`. The server pushes
 *   { type: 'ready' | 'notification.created' | 'message.created' | 'conversation.read' | 'groupMessage.created', data }
 * and answers `{ "type": "ping" }` with `{ "type": "pong" }`. Delivery is
 * best-effort; after reconnecting, refetch via REST.
 */
const realtimeRoutes: FastifyPluginAsyncTypebox = async (app) => {
  if (!app.config.realtime.enabled) return;

  if (app.config.realtime.pgFanout) {
    const fanout = new PgFanout(app.config.db.url, app.realtime, app.log);
    await fanout.start();
    app.addHook('onClose', () => fanout.stop());
  }

  app.get(
    '/ws',
    {
      websocket: true,
      config: { allowQueryToken: true, rateLimit: false },
      schema: {
        tags: ['Realtime'],
        summary: 'Live events (WebSocket)',
        querystring: Type.Object({ access_token: Type.Optional(Type.String()) }),
      },
    },
    (socket, request) => {
      const user = currentUser(request);
      const { realtime } = app;
      realtime.attach(user.id, socket);
      socket.send(JSON.stringify({ type: 'ready', data: { userId: user.id } }));

      let alive = true;
      socket.on('pong', () => {
        alive = true;
      });
      const heartbeat = setInterval(() => {
        if (!alive) {
          socket.terminate();
          return;
        }
        alive = false;
        socket.ping();
      }, HEARTBEAT_MS);
      // Revoked sessions (logout, password change, account removal) lose their socket.
      const sessionCheck = setInterval(async () => {
        try {
          const session = await app.services.repositories.auth.findActiveSessionUser(user.sessionId, user.id);
          if (!session) socket.close(4001, 'session ended');
        } catch (err) {
          request.log.warn({ err }, 'Realtime session check failed');
        }
      }, SESSION_CHECK_MS);

      socket.on('message', (raw) => {
        try {
          const message = JSON.parse(raw.toString()) as { type?: string };
          if (message.type === 'ping') socket.send(JSON.stringify({ type: 'pong' }));
        } catch {
          socket.send(JSON.stringify({ type: 'error', data: { message: 'Messages must be JSON.' } }));
        }
      });
      socket.on('close', () => {
        clearInterval(heartbeat);
        clearInterval(sessionCheck);
        realtime.detach(user.id, socket);
      });
    },
  );
};

export default realtimeRoutes;
