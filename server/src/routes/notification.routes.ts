import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { NotificationController } from '../controllers/notification.controller.js';
import { notificationSchemas as s } from '../schemas/notification.schema.js';

/** /api/v1/notifications… and /api/v1/me/devices */
const notificationRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new NotificationController(app.services.notification);

  app.get('/notifications', { schema: s.list }, c.list);
  app.get('/notifications/unread-count', { schema: s.unreadCount }, c.unreadCount);
  app.post('/notifications/read-all', { schema: s.markAllRead }, c.markAllRead);
  app.post('/notifications/:id/read', { schema: s.markRead }, c.markRead);
  app.delete('/notifications/:id', { schema: s.remove }, c.remove);

  app.post('/me/devices', { schema: s.registerDevice }, c.registerDevice);
  app.delete('/me/devices', { schema: s.unregisterDevice }, c.unregisterDevice);
};

export default notificationRoutes;
