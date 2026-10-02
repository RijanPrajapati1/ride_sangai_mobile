import type { Db, PrismaClient } from '../db/prisma.js';
import { Prisma } from '../db/prisma.js';

export interface ConversationRow {
  id: string;
  created_at: Date;
  last_message_at: Date;
  last_text: string | null;
  last_sender_id: string | null;
  other_id: string;
  other_name: string;
  other_avatar_url: string;
  unread: number;
}

/** Data access for 1:1 conversations and their messages. */
export class ConversationRepository {
  constructor(private readonly prisma: PrismaClient) {}

  /**
   * The inbox in one query: the other participant, the last message and the
   * viewer's unread count (messages from the other person after the viewer's
   * read marker) for each conversation.
   */
  private inboxQuery(viewerId: string, extra: Prisma.Sql, limit: number | null) {
    return this.prisma.$queryRaw<ConversationRow[]>`
      SELECT c.id, c.created_at, c.last_message_at,
             m.text AS last_text, m.sender_id AS last_sender_id,
             o.id AS other_id, o.name AS other_name, o.avatar_url AS other_avatar_url,
             (SELECT count(*)::int FROM messages um
               WHERE um.conversation_id = c.id AND um.created_at > me.last_read_at AND um.sender_id <> me.user_id) AS unread
        FROM conversation_participants me
        JOIN conversations c ON c.id = me.conversation_id
        JOIN users o ON o.id = CASE WHEN c.user_a_id = me.user_id THEN c.user_b_id ELSE c.user_a_id END
        LEFT JOIN messages m ON m.id = c.last_message_id
       WHERE me.user_id = ${viewerId}::uuid ${extra}
       ORDER BY c.last_message_at DESC, c.id DESC
       ${limit === null ? Prisma.empty : Prisma.sql`LIMIT ${limit}`}`;
  }

  inbox(viewerId: string, after: [Date, string] | null, limit: number): Promise<ConversationRow[]> {
    const keyset = after
      ? Prisma.sql`AND (c.last_message_at, c.id) < (${after[0]}::timestamptz, ${after[1]}::uuid)`
      : Prisma.empty;
    return this.inboxQuery(viewerId, keyset, limit + 1);
  }

  async findForViewer(conversationId: string, viewerId: string): Promise<ConversationRow | null> {
    const rows = await this.inboxQuery(viewerId, Prisma.sql`AND c.id = ${conversationId}::uuid`, null);
    return rows[0] ?? null;
  }

  async totalUnread(viewerId: string): Promise<number> {
    const rows = await this.prisma.$queryRaw<Array<{ total: number }>>`
      SELECT COALESCE(sum((SELECT count(*) FROM messages um
                            WHERE um.conversation_id = me.conversation_id
                              AND um.created_at > me.last_read_at AND um.sender_id <> me.user_id)), 0)::int AS total
        FROM conversation_participants me
       WHERE me.user_id = ${viewerId}::uuid`;
    return rows[0]?.total ?? 0;
  }

  /** Get-or-create for an unordered pair; safe when both users start it at once. */
  async findOrCreate(userA: string, userB: string): Promise<{ id: string; created: boolean }> {
    const [a, b] = userA < userB ? [userA, userB] : [userB, userA];
    const existing = await this.prisma.conversation.findUnique({
      where: { userAId_userBId: { userAId: a, userBId: b } },
      select: { id: true },
    });
    if (existing) return { id: existing.id, created: false };
    try {
      const created = await this.prisma.conversation.create({
        data: { userAId: a, userBId: b, participants: { create: [{ userId: a }, { userId: b }] } },
        select: { id: true },
      });
      return { id: created.id, created: true };
    } catch (err) {
      // Lost the race: the other request created it first.
      const row = await this.prisma.conversation.findUnique({
        where: { userAId_userBId: { userAId: a, userBId: b } },
        select: { id: true },
      });
      if (row) return { id: row.id, created: false };
      throw err;
    }
  }

  /** The participant ids if the viewer belongs to the conversation, else null. */
  async participants(conversationId: string, db: Db = this.prisma): Promise<[string, string] | null> {
    const row = await db.conversation.findUnique({
      where: { id: conversationId },
      select: { userAId: true, userBId: true },
    });
    return row ? [row.userAId, row.userBId] : null;
  }

  /** Newest first (keyset on createdAt, id); callers reverse for display. */
  messagesPage(conversationId: string, before: [Date, string] | null, limit: number) {
    return this.prisma.message.findMany({
      where: {
        conversationId,
        ...(before
          ? { OR: [{ createdAt: { lt: before[0] } }, { createdAt: before[0], id: { lt: before[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      select: { id: true, conversationId: true, senderId: true, text: true, createdAt: true },
    });
  }

  createMessage(db: Db, data: { conversationId: string; senderId: string; text: string }) {
    return db.message.create({
      data,
      select: { id: true, conversationId: true, senderId: true, text: true, createdAt: true },
    });
  }

  async markRead(conversationId: string, userId: string, at: Date, db: Db = this.prisma): Promise<void> {
    await db.conversationParticipant.updateMany({
      where: { conversationId, userId, lastReadAt: { lt: at } },
      data: { lastReadAt: at },
    });
  }
}
