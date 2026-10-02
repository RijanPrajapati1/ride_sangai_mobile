import type { FastifyInstance } from 'fastify';
import adminRoutes from './admin.routes.js';
import authRoutes from './auth.routes.js';
import conversationRoutes from './conversation.routes.js';
import groupRoutes from './group.routes.js';
import healthRoutes from './health.routes.js';
import homeRoutes from './home.routes.js';
import notificationRoutes from './notification.routes.js';
import postRoutes from './post.routes.js';
import realtimeRoutes from './realtime.routes.js';
import rideRoutes from './ride.routes.js';
import uploadRoutes from './upload.routes.js';
import userRoutes from './user.routes.js';

export const API_PREFIX = '/api/v1';

/** Mounts every route group. Each route file declares its own sub-paths. */
export async function registerRoutes(app: FastifyInstance): Promise<void> {
  await app.register(healthRoutes);
  await app.register(authRoutes, { prefix: `${API_PREFIX}/auth` });
  await app.register(userRoutes, { prefix: API_PREFIX });
  await app.register(rideRoutes, { prefix: API_PREFIX });
  await app.register(postRoutes, { prefix: API_PREFIX });
  await app.register(conversationRoutes, { prefix: API_PREFIX });
  await app.register(groupRoutes, { prefix: API_PREFIX });
  await app.register(notificationRoutes, { prefix: API_PREFIX });
  await app.register(homeRoutes, { prefix: API_PREFIX });
  await app.register(adminRoutes, { prefix: `${API_PREFIX}/admin` });
  await app.register(uploadRoutes);
  await app.register(realtimeRoutes, { prefix: API_PREFIX });
}
