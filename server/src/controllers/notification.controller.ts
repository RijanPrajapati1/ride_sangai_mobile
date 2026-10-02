import { currentUser } from '../middlewares/authenticate.js';
import type { notificationSchemas } from '../schemas/notification.schema.js';
import type { NotificationService } from '../services/notification.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof notificationSchemas;

export class NotificationController {
  constructor(private readonly notifications: NotificationService) {}

  list = async (request: Req<S['list']>) => this.notifications.list(currentUser(request).id, request.query);

  unreadCount = async (request: Req<S['unreadCount']>) => ({ count: await this.notifications.unreadCount(currentUser(request).id) });

  markRead = async (request: Req<S['markRead']>) => ({
    count: await this.notifications.markRead(currentUser(request).id, request.params.id),
  });

  markAllRead = async (request: Req<S['markAllRead']>) => {
    const before = request.body?.before ? new Date(request.body.before) : undefined;
    return { updated: await this.notifications.markAllRead(currentUser(request).id, before) };
  };

  remove = async (request: Req<S['remove']>, reply: Rep<S['remove']>) => {
    await this.notifications.remove(currentUser(request).id, request.params.id);
    return reply.status(204).send();
  };

  registerDevice = async (request: Req<S['registerDevice']>, reply: Rep<S['registerDevice']>) => {
    await this.notifications.registerDevice(currentUser(request).id, request.body.token, request.body.platform);
    return reply.status(204).send();
  };

  unregisterDevice = async (request: Req<S['unregisterDevice']>, reply: Rep<S['unregisterDevice']>) => {
    await this.notifications.unregisterDevice(currentUser(request).id, request.body.token);
    return reply.status(204).send();
  };
}
