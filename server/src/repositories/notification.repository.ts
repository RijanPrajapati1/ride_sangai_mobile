import type { NotificationType } from '../constants/enums.js';
import type { Db, PrismaClient } from '../db/prisma.js';
import type { NotificationEntityType } from '../constants/enums.js';

const notificationInclude = { actor: { select: { name: true, avatarUrl: true } } } as const;

export interface NotificationRecord {
  id: string;
  recipientId: string;
  type: NotificationType;
  title: string;
  body: string;
  actorId: string | null;
  actor: { name: string; avatarUrl: string } | null;
  entityType: NotificationEntityType | null;
  entityId: string | null;
  readAt: Date | null;
  createdAt: Date;
}

export interface NewNotification {
  recipientId: string;
  type: NotificationType;
  title: string;
  body: string;
  actorId: string | null;
  entityType: NotificationEntityType | null;
  entityId: string | null;
  collapseKey: string | null;
}

export class NotificationRepository {
  constructor(private readonly prisma: PrismaClient) {}

  /** Inserts, or — with a collapse key — updates the matching unread notification. */
  createOrCollapse(db: Db, data: NewNotification): Promise<NotificationRecord> {
    if (!data.collapseKey) {
      return db.notification.create({ data, include: notificationInclude });
    }
    const { collapseKey, recipientId, ...rest } = data;
    return db.notification.upsert({
      where: { recipientId_collapseKey: { recipientId, collapseKey } },
      create: data,
      update: { ...rest, createdAt: new Date() },
      include: notificationInclude,
    });
  }

  list(recipientId: string, options: { unreadOnly?: boolean; after: [Date, string] | null; limit: number }) {
    const { after } = options;
    return this.prisma.notification.findMany({
      where: {
        recipientId,
        ...(options.unreadOnly ? { readAt: null } : {}),
        ...(after
          ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], id: { lt: after[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: options.limit + 1,
      include: notificationInclude,
    });
  }

  countUnread(recipientId: string): Promise<number> {
    return this.prisma.notification.count({ where: { recipientId, readAt: null } });
  }

  findOwned(id: string, recipientId: string) {
    return this.prisma.notification.findFirst({
      where: { id, recipientId },
      select: { id: true, readAt: true },
    });
  }

  async markRead(id: string): Promise<void> {
    await this.prisma.notification.updateMany({ where: { id, readAt: null }, data: { readAt: new Date() } });
  }

  async markAllRead(recipientId: string, before?: Date): Promise<number> {
    const result = await this.prisma.notification.updateMany({
      where: { recipientId, readAt: null, ...(before ? { createdAt: { lte: before } } : {}) },
      data: { readAt: new Date() },
    });
    return result.count;
  }

  async delete(id: string, recipientId: string): Promise<boolean> {
    const result = await this.prisma.notification.deleteMany({ where: { id, recipientId } });
    return result.count > 0;
  }

  async upsertDevice(userId: string, token: string, platform: 'android' | 'ios' | 'web'): Promise<void> {
    await this.prisma.deviceToken.upsert({
      where: { token },
      create: { token, userId, platform },
      update: { userId, platform, lastSeenAt: new Date() },
    });
  }

  async deleteDevice(userId: string, token: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({ where: { token, userId } });
  }
}
