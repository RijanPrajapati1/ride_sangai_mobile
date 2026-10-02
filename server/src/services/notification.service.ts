import type { NotificationType } from '../constants/enums.js';
import type { TxContext } from '../db/prisma.js';
import type { NotificationEntityType } from '../constants/enums.js';
import type { RealtimeHub } from '../realtime/hub.js';
import type { NotificationRepository, NotificationRecord } from '../repositories/notification.repository.js';
import { notFound } from '../utils/errors.js';
import { decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';

export type { NotificationEntityType };

export interface NotifyInput {
  recipientId: string;
  type: NotificationType;
  title: string;
  /** Maps to the Dart `NotificationItem.description`. */
  body: string;
  actorId?: string | null;
  entityType?: NotificationEntityType | null;
  entityId?: string | null;
  /**
   * When set, an existing *unread* notification of the recipient with the same
   * key is updated (and bumped to the top) instead of adding another row —
   * e.g. one "new messages" notification per conversation, not one per message.
   */
  collapseKey?: string | null;
}

/** API shape; mirrors the Dart `NotificationItem` plus actor and navigation fields. */
export interface NotificationDto {
  id: string;
  type: NotificationType;
  title: string;
  description: string;
  time: Date;
  isRead: boolean;
  actorId: string | null;
  actorName: string | null;
  /** null when there is no actor (the app then shows the type icon). */
  actorAvatarUrl: string | null;
  entityType: NotificationEntityType | null;
  entityId: string | null;
}

export function toNotificationDto(row: NotificationRecord): NotificationDto {
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    description: row.body,
    time: row.createdAt,
    isRead: row.readAt !== null,
    actorId: row.actorId,
    actorName: row.actor?.name ?? null,
    actorAvatarUrl: row.actor ? row.actor.avatarUrl : null,
    entityType: row.entityType,
    entityId: row.entityId,
  };
}

/** Optional device push (FCM/APNs). Called after commit; must never throw. */
export interface PushSender {
  send(recipientId: string, notification: NotificationDto): Promise<void>;
}

/**
 * Creates in-app notifications. Pass the TxContext of the transaction doing
 * the triggering write, so the notification commits (or rolls back) with it;
 * the realtime push happens only after commit.
 */
export class NotificationService {
  constructor(
    private readonly repo: NotificationRepository,
    private readonly realtime: RealtimeHub,
    private readonly push?: PushSender,
  ) {}

  async notify(ctx: TxContext, input: NotifyInput): Promise<NotificationDto | null> {
    // Never notify people about their own actions.
    if (input.actorId && input.actorId === input.recipientId) return null;
    const row = await this.repo.createOrCollapse(ctx.db, {
      recipientId: input.recipientId,
      type: input.type,
      title: input.title.slice(0, 200),
      body: input.body.slice(0, 1000),
      actorId: input.actorId ?? null,
      entityType: input.entityType ?? null,
      entityId: input.entityId ?? null,
      collapseKey: input.collapseKey ?? null,
    });
    const dto = toNotificationDto(row);
    ctx.afterCommit(async () => {
      this.realtime.publish([input.recipientId], { type: 'notification.created', data: dto });
      if (this.push) await this.push.send(input.recipientId, dto);
    });
    return dto;
  }

  async notifyMany(ctx: TxContext, inputs: readonly NotifyInput[]): Promise<void> {
    for (const input of inputs) await this.notify(ctx, input);
  }

  // --- The recipient's inbox -----------------------------------------------------

  async list(recipientId: string, query: { unreadOnly?: boolean; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const [rows, unreadCount] = await Promise.all([
      this.repo.list(recipientId, { unreadOnly: query.unreadOnly ?? false, after: decodeTimeCursor(query.cursor), limit }),
      this.repo.countUnread(recipientId),
    ]);
    return { ...toPage(rows, limit, (row) => timeCursor(row.createdAt, row.id), toNotificationDto), unreadCount };
  }

  unreadCount(recipientId: string): Promise<number> {
    return this.repo.countUnread(recipientId);
  }

  /** Idempotent: reading an already-read notification is fine. */
  async markRead(recipientId: string, id: string): Promise<number> {
    const notification = await this.repo.findOwned(id, recipientId);
    if (!notification) throw notFound('This notification could not be found.', 'NOTIFICATION_NOT_FOUND');
    await this.repo.markRead(id);
    return this.repo.countUnread(recipientId);
  }

  /** `before` lets the client avoid marking notifications it has not seen yet. */
  async markAllRead(recipientId: string, before?: Date): Promise<number> {
    return this.repo.markAllRead(recipientId, before);
  }

  async remove(recipientId: string, id: string): Promise<void> {
    if (!(await this.repo.delete(id, recipientId))) throw notFound('This notification could not be found.', 'NOTIFICATION_NOT_FOUND');
  }

  registerDevice(userId: string, token: string, platform: 'android' | 'ios' | 'web'): Promise<void> {
    return this.repo.upsertDevice(userId, token, platform);
  }

  unregisterDevice(userId: string, token: string): Promise<void> {
    return this.repo.deleteDevice(userId, token);
  }
}
