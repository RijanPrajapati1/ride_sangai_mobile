import { Type } from 'typebox';
import { NOTIFICATION_ENTITY_TYPES } from '../constants/enums.js';
import { paginationQuery } from '../utils/pagination.js';
import { DateTimeInput, IdParams, NoContent, NotificationTypeSchema, Nullable, Timestamp, Uuid, errorResponses } from './common.schema.js';

/** Mirrors the Dart `NotificationItem` entity, plus actor and navigation target. */
export const NotificationItem = Type.Object({
  id: Uuid,
  type: NotificationTypeSchema,
  title: Type.String(),
  description: Type.String(),
  time: Timestamp,
  isRead: Type.Boolean(),
  actorId: Nullable(Uuid),
  actorName: Nullable(Type.String()),
  actorAvatarUrl: Nullable(Type.String({ description: 'null when there is no actor (show the type icon).' })),
  entityType: Nullable(Type.Enum(NOTIFICATION_ENTITY_TYPES)),
  entityId: Nullable(Uuid),
});

export const NotificationPage = Type.Object({
  items: Type.Array(NotificationItem),
  nextCursor: Nullable(Type.String()),
  unreadCount: Type.Integer({ description: 'Unread notifications in total (for the bell badge).' }),
});

export const Count = Type.Object({ count: Type.Integer() });

const tags = ['Notifications'];

export const notificationSchemas = {
  list: {
    tags,
    summary: 'My notifications, newest first',
    querystring: Type.Object({ unreadOnly: Type.Optional(Type.Boolean()), ...paginationQuery }),
    response: { 200: NotificationPage, ...errorResponses(400, 401) },
  },
  unreadCount: { tags, summary: 'Unread notification count (bell badge)', response: { 200: Count, ...errorResponses(401) } },
  markRead: {
    tags,
    summary: 'Mark one notification read (idempotent)',
    description: 'Returns the new unread count, so the client need not refetch the list.',
    params: IdParams,
    response: { 200: Count, ...errorResponses(401, 404) },
  },
  markAllRead: {
    tags,
    summary: 'Mark all notifications read',
    body: Type.Optional(Type.Object({ before: Type.Optional(DateTimeInput) }, { additionalProperties: false })),
    response: { 200: Type.Object({ updated: Type.Integer() }), ...errorResponses(401) },
  },
  remove: { tags, summary: 'Delete a notification', params: IdParams, response: { 204: NoContent, ...errorResponses(401, 404) } },
  registerDevice: {
    tags,
    summary: 'Register this device for push notifications',
    body: Type.Object(
      { token: Type.String({ minLength: 10, maxLength: 4096 }), platform: Type.Enum(['android', 'ios', 'web']) },
      { additionalProperties: false },
    ),
    response: { 204: NoContent, ...errorResponses(400, 401) },
  },
  unregisterDevice: {
    tags,
    summary: 'Stop push notifications to this device',
    body: Type.Object({ token: Type.String({ minLength: 10, maxLength: 4096 }) }, { additionalProperties: false }),
    response: { 204: NoContent, ...errorResponses(400, 401) },
  },
};
