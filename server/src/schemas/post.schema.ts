import { Type } from 'typebox';
import { paginationQuery } from '../utils/pagination.js';
import { IdParams, NoContent, Nullable, Paginated, Text, Timestamp, Uuid, errorResponses } from './common.schema.js';

/** Mirrors the Dart `CommunityPost` entity. */
export const CommunityPost = Type.Object({
  id: Uuid,
  userId: Uuid,
  userName: Type.String(),
  userAvatarUrl: Type.String(),
  time: Timestamp,
  text: Type.String(),
  imageUrl: Nullable(Type.String({ description: 'null when the post has no image.' })),
  likeCount: Type.Integer(),
  commentCount: Type.Integer(),
  isLiked: Type.Boolean(),
  isMine: Type.Boolean(),
});

/** Mirrors the Dart `Comment` entity. */
export const Comment = Type.Object({
  id: Uuid,
  postId: Uuid,
  userId: Uuid,
  userName: Type.String(),
  userAvatarUrl: Type.String(),
  text: Type.String(),
  time: Timestamp,
  likeCount: Type.Integer(),
  isLiked: Type.Boolean(),
  isMine: Type.Boolean(),
});

export const LikeState = Type.Object({ isLiked: Type.Boolean(), likeCount: Type.Integer() });

const imageUrl = Nullable(Type.String({ maxLength: 2048, description: 'http(s) URL; null or "" for no image.' }));

export const CreatePostBody = Type.Object({ text: Text(2000), imageUrl: Type.Optional(imageUrl) }, { additionalProperties: false });
export const UpdatePostBody = Type.Object(
  { text: Type.Optional(Text(2000)), imageUrl: Type.Optional(imageUrl) },
  { additionalProperties: false, minProperties: 1 },
);
export const CreateCommentBody = Type.Object({ text: Text(1000) }, { additionalProperties: false });
export const FeedQuery = Type.Object({ authorId: Type.Optional(Uuid), ...paginationQuery });

const tags = ['Community'];
const PageQuery = Type.Object(paginationQuery);

export const postSchemas = {
  feed: {
    tags,
    summary: 'Community feed, newest first',
    description: 'Use `limit=2` for the home preview; `authorId` for one rider’s posts.',
    querystring: FeedQuery,
    response: { 200: Paginated(CommunityPost), ...errorResponses(400, 401) },
  },
  create: { tags, summary: 'Share a post', body: CreatePostBody, response: { 201: CommunityPost, ...errorResponses(400, 401) } },
  get: { tags, summary: 'A post', params: IdParams, response: { 200: CommunityPost, ...errorResponses(401, 404) } },
  update: { tags, summary: 'Edit my post', params: IdParams, body: UpdatePostBody, response: { 200: CommunityPost, ...errorResponses(400, 401, 403, 404) } },
  remove: { tags, summary: 'Delete a post (author or admin)', params: IdParams, response: { 204: NoContent, ...errorResponses(401, 403, 404) } },
  like: { tags, summary: 'Like a post (idempotent)', params: IdParams, response: { 200: LikeState, ...errorResponses(401, 404) } },
  unlike: { tags, summary: 'Remove my like (idempotent)', params: IdParams, response: { 200: LikeState, ...errorResponses(401, 404) } },
  comments: {
    tags,
    summary: "A post's comments, oldest first",
    params: IdParams,
    querystring: PageQuery,
    response: { 200: Paginated(Comment), ...errorResponses(401, 404) },
  },
  addComment: { tags, summary: 'Comment on a post', params: IdParams, body: CreateCommentBody, response: { 201: Comment, ...errorResponses(400, 401, 404) } },
  removeComment: {
    tags,
    summary: 'Delete a comment (its author, the post author, or an admin)',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  likeComment: { tags, summary: 'Like a comment (idempotent)', params: IdParams, response: { 200: LikeState, ...errorResponses(401, 404) } },
  unlikeComment: { tags, summary: 'Remove my comment like (idempotent)', params: IdParams, response: { 200: LikeState, ...errorResponses(401, 404) } },
};
