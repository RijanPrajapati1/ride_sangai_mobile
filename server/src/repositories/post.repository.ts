import type { Db, PrismaClient } from '../db/prisma.js';
import type { Prisma } from '../db/prisma.js';

const author = { select: { id: true, name: true, avatarUrl: true } } as const;

function postInclude(viewerId: string | null) {
  return {
    author,
    likes: viewerId ? { where: { userId: viewerId }, select: { userId: true }, take: 1 } : false,
  } satisfies Prisma.PostInclude;
}

function commentInclude(viewerId: string | null) {
  return {
    author,
    likes: viewerId ? { where: { userId: viewerId }, select: { userId: true }, take: 1 } : false,
  } satisfies Prisma.CommentInclude;
}

export type PostRecord = Prisma.PostGetPayload<{ include: ReturnType<typeof postInclude> }>;
export type CommentRecord = Prisma.CommentGetPayload<{ include: ReturnType<typeof commentInclude> }>;

/** Data access for community posts, comments and likes. */
export class PostRepository {
  constructor(private readonly prisma: PrismaClient) {}

  /** Newest first (keyset on createdAt, id). */
  findPage(options: {
    viewerId: string | null;
    authorId?: string;
    after: [Date, string] | null;
    limit: number;
  }) {
    const { after } = options;
    return this.prisma.post.findMany({
      where: {
        ...(options.authorId ? { authorId: options.authorId } : {}),
        ...(after
          ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], id: { lt: after[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: options.limit + 1,
      include: postInclude(options.viewerId),
    });
  }

  findById(id: string, viewerId: string | null, db: Db = this.prisma): Promise<PostRecord | null> {
    return db.post.findUnique({ where: { id }, include: postInclude(viewerId) });
  }

  findOwner(id: string, db: Db = this.prisma) {
    return db.post.findUnique({ where: { id }, select: { id: true, authorId: true, text: true } });
  }

  create(data: { authorId: string; text: string; imageUrl: string | null }): Promise<PostRecord> {
    return this.prisma.post.create({ data, include: postInclude(data.authorId) });
  }

  update(id: string, data: Prisma.PostUpdateInput, viewerId: string): Promise<PostRecord> {
    return this.prisma.post.update({ where: { id }, data, include: postInclude(viewerId) });
  }

  async delete(id: string, db: Db = this.prisma): Promise<void> {
    await db.post.deleteMany({ where: { id } });
  }

  /** Returns true when the like was new. */
  async like(postId: string, userId: string, db: Db = this.prisma): Promise<boolean> {
    const result = await db.postLike.createMany({ data: [{ postId, userId }], skipDuplicates: true });
    return result.count > 0;
  }

  async unlike(postId: string, userId: string, db: Db = this.prisma): Promise<void> {
    await db.postLike.deleteMany({ where: { postId, userId } });
  }

  async likeCount(postId: string, db: Db = this.prisma): Promise<number> {
    const row = await db.post.findUniqueOrThrow({ where: { id: postId }, select: { likeCount: true } });
    return row.likeCount;
  }

  /** Oldest first, like a conversation thread (keyset on createdAt, id). */
  findCommentsPage(postId: string, viewerId: string, after: [Date, string] | null, limit: number) {
    return this.prisma.comment.findMany({
      where: {
        postId,
        ...(after
          ? { OR: [{ createdAt: { gt: after[0] } }, { createdAt: after[0], id: { gt: after[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      take: limit + 1,
      include: commentInclude(viewerId),
    });
  }

  createComment(db: Db, data: { postId: string; authorId: string; text: string }): Promise<CommentRecord> {
    return db.comment.create({ data, include: commentInclude(data.authorId) });
  }

  findComment(id: string, db: Db = this.prisma) {
    return db.comment.findUnique({
      where: { id },
      select: { id: true, authorId: true, postId: true, post: { select: { authorId: true } } },
    });
  }

  async deleteComment(id: string, db: Db = this.prisma): Promise<void> {
    await db.comment.deleteMany({ where: { id } });
  }

  async likeComment(commentId: string, userId: string): Promise<void> {
    await this.prisma.commentLike.createMany({ data: [{ commentId, userId }], skipDuplicates: true });
  }

  async unlikeComment(commentId: string, userId: string): Promise<void> {
    await this.prisma.commentLike.deleteMany({ where: { commentId, userId } });
  }

  async commentLikeCount(commentId: string): Promise<number> {
    const row = await this.prisma.comment.findUniqueOrThrow({
      where: { id: commentId },
      select: { likeCount: true },
    });
    return row.likeCount;
  }
}
