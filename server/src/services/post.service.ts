import type { UnitOfWork } from '../db/prisma.js';
import type { CommentRecord, PostRecord, PostRepository } from '../repositories/post.repository.js';
import { audit } from '../utils/audit.js';
import { forbidden, notFound } from '../utils/errors.js';
import { decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';
import { assertImageUrl, blankToNull } from '../utils/validation.js';
import type { NotificationService } from './notification.service.js';
import type { Actor } from './ride.service.js';

const POST_NOT_FOUND = () => notFound('This post could not be found.', 'POST_NOT_FOUND');
const COMMENT_NOT_FOUND = () => notFound('This comment could not be found.', 'COMMENT_NOT_FOUND');

/** Maps a post to the API shape (the Dart `CommunityPost` entity). */
export function toPostDto(post: PostRecord, viewerId: string | null) {
  return {
    id: post.id,
    userId: post.author.id,
    userName: post.author.name,
    userAvatarUrl: post.author.avatarUrl,
    time: post.createdAt,
    text: post.text,
    imageUrl: post.imageUrl,
    likeCount: post.likeCount,
    commentCount: post.commentCount,
    isLiked: Array.isArray(post.likes) && post.likes.length > 0,
    isMine: viewerId === post.author.id,
  };
}

/** Maps a comment to the API shape (the Dart `Comment` entity). */
export function toCommentDto(comment: CommentRecord, viewerId: string | null) {
  return {
    id: comment.id,
    postId: comment.postId,
    userId: comment.author.id,
    userName: comment.author.name,
    userAvatarUrl: comment.author.avatarUrl,
    text: comment.text,
    time: comment.createdAt,
    likeCount: comment.likeCount,
    isLiked: Array.isArray(comment.likes) && comment.likes.length > 0,
    isMine: viewerId === comment.author.id,
  };
}

function cleanImage(url: string | null | undefined): string | null {
  const image = blankToNull(url);
  if (image) assertImageUrl(image, 'imageUrl');
  return image;
}

/** Community feed: posts, comments and likes. */
export class PostService {
  constructor(
    private readonly uow: UnitOfWork,
    readonly repo: PostRepository,
    private readonly notifications: NotificationService,
  ) {}

  async feed(viewerId: string, query: { authorId?: string; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findPage({
      viewerId,
      ...(query.authorId ? { authorId: query.authorId } : {}),
      after: decodeTimeCursor(query.cursor),
      limit,
    });
    return toPage(
      rows,
      limit,
      (post) => timeCursor(post.createdAt, post.id),
      (post) => toPostDto(post, viewerId),
    );
  }

  async get(postId: string, viewerId: string) {
    const post = await this.repo.findById(postId, viewerId);
    if (!post) throw POST_NOT_FOUND();
    return toPostDto(post, viewerId);
  }

  async create(author: Actor, input: { text: string; imageUrl?: string | null }) {
    const post = await this.repo.create({
      authorId: author.id,
      text: input.text.trim(),
      imageUrl: cleanImage(input.imageUrl),
    });
    return toPostDto(post, author.id);
  }

  async update(actor: Actor, postId: string, input: { text?: string; imageUrl?: string | null }) {
    const post = await this.repo.findOwner(postId);
    if (!post) throw POST_NOT_FOUND();
    if (post.authorId !== actor.id) throw forbidden('Only the author can edit this post.', 'NOT_POST_AUTHOR');
    const updated = await this.repo.update(
      postId,
      {
        ...(input.text !== undefined ? { text: input.text.trim() } : {}),
        ...(input.imageUrl !== undefined ? { imageUrl: cleanImage(input.imageUrl) } : {}),
      },
      actor.id,
    );
    return toPostDto(updated, actor.id);
  }

  /** The author, or an admin moderating. Comments and likes go with it. */
  async remove(actor: Actor, postId: string): Promise<void> {
    await this.uow.run(async ({ db }) => {
      const post = await this.repo.findOwner(postId, db);
      if (!post) throw POST_NOT_FOUND();
      if (post.authorId !== actor.id && actor.role !== 'superadmin')
        throw forbidden('Only the author can delete this post.', 'NOT_POST_AUTHOR');
      if (post.authorId !== actor.id) {
        await audit(db, {
          actorId: actor.id,
          action: 'post.delete',
          targetType: 'post',
          targetId: postId,
          details: { text: post.text.slice(0, 120) },
        });
      }
      await this.repo.delete(postId, db);
    });
  }

  async like(actor: Actor, postId: string) {
    return this.uow.run(async (ctx) => {
      const post = await this.repo.findOwner(postId, ctx.db);
      if (!post) throw POST_NOT_FOUND();
      if (await this.repo.like(postId, actor.id, ctx.db)) {
        await this.notifications.notify(ctx, {
          recipientId: post.authorId,
          actorId: actor.id,
          type: 'like',
          title: 'New like',
          body: `${actor.name} liked your post.`,
          entityType: 'post',
          entityId: postId,
          // like → unlike → like does not stack notifications.
          collapseKey: `like:${postId}:${actor.id}`,
        });
      }
      return { isLiked: true, likeCount: await this.repo.likeCount(postId, ctx.db) };
    });
  }

  async unlike(actor: Actor, postId: string) {
    if (!(await this.repo.findOwner(postId))) throw POST_NOT_FOUND();
    await this.repo.unlike(postId, actor.id);
    return { isLiked: false, likeCount: await this.repo.likeCount(postId) };
  }

  async comments(postId: string, viewerId: string, query: { limit?: number; cursor?: string }) {
    if (!(await this.repo.findOwner(postId))) throw POST_NOT_FOUND();
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findCommentsPage(postId, viewerId, decodeTimeCursor(query.cursor), limit);
    return toPage(
      rows,
      limit,
      (comment) => timeCursor(comment.createdAt, comment.id),
      (comment) => toCommentDto(comment, viewerId),
    );
  }

  async addComment(actor: Actor, postId: string, text: string) {
    return this.uow.run(async (ctx) => {
      const post = await this.repo.findOwner(postId, ctx.db);
      if (!post) throw POST_NOT_FOUND();
      const comment = await this.repo.createComment(ctx.db, {
        postId,
        authorId: actor.id,
        text: text.trim(),
      });
      await this.notifications.notify(ctx, {
        recipientId: post.authorId,
        actorId: actor.id,
        type: 'comment',
        title: 'New comment',
        body: `${actor.name} commented on your post: "${comment.text.slice(0, 80)}"`,
        entityType: 'post',
        entityId: postId,
      });
      return toCommentDto(comment, actor.id);
    });
  }

  /** The comment's author, the post's author, or an admin. */
  async removeComment(actor: Actor, commentId: string): Promise<void> {
    const comment = await this.repo.findComment(commentId);
    if (!comment) throw COMMENT_NOT_FOUND();
    const allowed =
      comment.authorId === actor.id || comment.post.authorId === actor.id || actor.role === 'superadmin';
    if (!allowed) throw forbidden('You cannot delete this comment.', 'NOT_COMMENT_AUTHOR');
    await this.repo.deleteComment(commentId);
  }

  async likeComment(actor: Actor, commentId: string) {
    if (!(await this.repo.findComment(commentId))) throw COMMENT_NOT_FOUND();
    await this.repo.likeComment(commentId, actor.id);
    return { isLiked: true, likeCount: await this.repo.commentLikeCount(commentId) };
  }

  async unlikeComment(actor: Actor, commentId: string) {
    if (!(await this.repo.findComment(commentId))) throw COMMENT_NOT_FOUND();
    await this.repo.unlikeComment(commentId, actor.id);
    return { isLiked: false, likeCount: await this.repo.commentLikeCount(commentId) };
  }
}
