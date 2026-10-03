import type { UnitOfWork } from '../db/prisma.js';
import type { RealtimeHub } from '../realtime/hub.js';
import type { ConversationRepository, ConversationRow } from '../repositories/conversation.repository.js';
import type { UserRepository } from '../repositories/user.repository.js';
import { badRequest, notFound } from '../utils/errors.js';
import { decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';
import type { NotificationService } from './notification.service.js';
import type { Actor } from './ride.service.js';

/** Shown as the last message of a conversation nobody has written in yet. */
export const EMPTY_CONVERSATION_PREVIEW = 'Say hello 👋';

const CONVERSATION_NOT_FOUND = () =>
  notFound('This conversation could not be found.', 'CONVERSATION_NOT_FOUND');

/** Maps an inbox row to the API shape (the Dart `Conversation` entity), seen by the viewer. */
export function toConversationDto(row: ConversationRow) {
  return {
    id: row.id,
    userId: row.other_id,
    userName: row.other_name,
    userAvatarUrl: row.other_avatar_url,
    lastMessage: row.last_text ?? EMPTY_CONVERSATION_PREVIEW,
    lastMessageTime: row.last_message_at,
    lastMessageSenderId: row.last_sender_id,
    unreadCount: row.unread,
  };
}

interface MessageRecord {
  id: string;
  conversationId: string;
  senderId: string;
  text: string;
  createdAt: Date;
}

/** Maps a message to the API shape (the Dart `Message` entity) for one viewer. */
export function toMessageDto(message: MessageRecord, viewerId: string) {
  return {
    id: message.id,
    conversationId: message.conversationId,
    senderId: message.senderId,
    text: message.text,
    sentAt: message.createdAt,
    isMe: message.senderId === viewerId,
  };
}

/** Direct messages between two riders. */
export class ConversationService {
  constructor(
    private readonly uow: UnitOfWork,
    private readonly repo: ConversationRepository,
    private readonly users: UserRepository,
    private readonly notifications: NotificationService,
    private readonly realtime: RealtimeHub,
  ) {}

  async inbox(viewerId: string, query: { limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.inbox(viewerId, decodeTimeCursor(query.cursor), limit);
    return toPage(rows, limit, (row) => timeCursor(row.last_message_at, row.id), toConversationDto);
  }

  async get(conversationId: string, viewerId: string) {
    const row = await this.repo.findForViewer(conversationId, viewerId);
    if (!row) throw CONVERSATION_NOT_FOUND();
    return toConversationDto(row);
  }

  /** "Message" button: the existing conversation with that rider, or a new empty one. */
  async open(viewerId: string, otherUserId: string) {
    if (otherUserId === viewerId) throw badRequest('You cannot message yourself.', 'CANNOT_MESSAGE_SELF');
    if (!(await this.users.exists(otherUserId)))
      throw notFound('This rider could not be found.', 'USER_NOT_FOUND');
    const { id, created } = await this.repo.findOrCreate(viewerId, otherUserId);
    return { conversation: await this.get(id, viewerId), created };
  }

  private async assertParticipant(conversationId: string, viewerId: string): Promise<string> {
    const pair = await this.repo.participants(conversationId);
    if (!pair || !pair.includes(viewerId)) throw CONVERSATION_NOT_FOUND();
    return pair[0] === viewerId ? pair[1] : pair[0];
  }

  /**
   * One page of history, oldest → newest within the page; `nextCursor` loads
   * older messages. Loading the latest page marks the conversation read.
   */
  async messages(
    conversationId: string,
    viewerId: string,
    query: { limit?: number; cursor?: string; markRead?: boolean },
  ) {
    const otherId = await this.assertParticipant(conversationId, viewerId);
    const limit = pageLimit(query.limit);
    const rows = await this.repo.messagesPage(conversationId, decodeTimeCursor(query.cursor), limit);
    const page = toPage(
      rows,
      limit,
      (row) => timeCursor(row.createdAt, row.id),
      (row) => toMessageDto(row, viewerId),
    );
    page.items.reverse();
    if (!query.cursor && query.markRead !== false) await this.markRead(conversationId, viewerId, otherId);
    return page;
  }

  async send(sender: Actor, conversationId: string, text: string) {
    const recipientId = await this.assertParticipant(conversationId, sender.id);
    return this.uow.run(async (ctx) => {
      const message = await this.repo.createMessage(ctx.db, {
        conversationId,
        senderId: sender.id,
        text: text.trim(),
      });
      // Writing in a conversation means you have read it.
      await this.repo.markRead(conversationId, sender.id, message.createdAt, ctx.db);
      await this.notifications.notify(ctx, {
        recipientId,
        actorId: sender.id,
        type: 'newMessage',
        title: 'New message',
        body: `${sender.name}: ${message.text.slice(0, 120)}`,
        entityType: 'conversation',
        entityId: conversationId,
        // One unread notification per conversation, updated with the latest message.
        collapseKey: `conversation:${conversationId}`,
      });
      ctx.afterCommit(() => {
        this.realtime.publish([recipientId], {
          type: 'message.created',
          data: toMessageDto(message, recipientId),
        });
        this.realtime.publish([sender.id], {
          type: 'message.created',
          data: toMessageDto(message, sender.id),
        });
      });
      return toMessageDto(message, sender.id);
    });
  }

  async markRead(conversationId: string, viewerId: string, otherId?: string): Promise<void> {
    const other = otherId ?? (await this.assertParticipant(conversationId, viewerId));
    const readAt = new Date();
    await this.repo.markRead(conversationId, viewerId, readAt);
    this.realtime.publish([other], {
      type: 'conversation.read',
      data: { conversationId, userId: viewerId, readAt },
    });
  }

  totalUnread(viewerId: string): Promise<number> {
    return this.repo.totalUnread(viewerId);
  }
}
