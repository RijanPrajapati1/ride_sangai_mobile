import { Type } from 'typebox';
import { paginationQuery } from '../utils/pagination.js';
import {
  IdParams,
  NoContent,
  Nullable,
  Paginated,
  Text,
  Timestamp,
  Uuid,
  errorResponses,
} from './common.schema.js';

/** Mirrors the Dart `Group` entity, for the viewer. */
export const Group = Type.Object({
  id: Uuid,
  name: Type.String(),
  description: Type.String(),
  coverImageUrl: Nullable(Type.String()),
  memberCount: Type.Integer(),
  isJoined: Type.Boolean(),
  myRole: Nullable(Type.Enum(['owner', 'member'])),
  organizerId: Uuid,
  organizerName: Type.String(),
  lastMessageAt: Nullable(Timestamp),
  createdAt: Timestamp,
});

/** Mirrors the Dart `GroupMessage` entity. */
export const GroupMessage = Type.Object({
  id: Uuid,
  groupId: Uuid,
  senderId: Uuid,
  senderName: Type.String(),
  senderAvatarUrl: Type.String(),
  text: Type.String(),
  sentAt: Timestamp,
  isMe: Type.Boolean(),
});

export const GroupMember = Type.Object({
  userId: Uuid,
  name: Type.String(),
  avatarUrl: Type.String(),
  role: Type.Enum(['owner', 'member']),
  joinedAt: Timestamp,
});

const cover = Nullable(Type.String({ maxLength: 2048, description: 'http(s) URL; null or "" for none.' }));

export const CreateGroupBody = Type.Object(
  { name: Text(80), description: Text(1000), coverImageUrl: Type.Optional(cover) },
  { additionalProperties: false },
);
export const UpdateGroupBody = Type.Object(
  {
    name: Type.Optional(Text(80)),
    description: Type.Optional(Text(1000)),
    coverImageUrl: Type.Optional(cover),
  },
  { additionalProperties: false, minProperties: 1 },
);
export const GroupListQuery = Type.Object({
  sort: Type.Optional(Type.Enum(['popular', 'newest'], { default: 'popular' })),
  q: Type.Optional(Type.String({ maxLength: 80 })),
  ...paginationQuery,
});
export const SendGroupMessageBody = Type.Object({ text: Text(2000) }, { additionalProperties: false });

const tags = ['Groups'];
const PageQuery = Type.Object(paginationQuery);

export const groupSchemas = {
  list: {
    tags,
    summary: 'Discover groups',
    description: '`sort=popular` (most members first, the Community carousel) or `sort=newest`.',
    querystring: GroupListQuery,
    response: { 200: Paginated(Group), ...errorResponses(400, 401) },
  },
  mine: {
    tags,
    summary: 'Groups I belong to, most recently joined first',
    querystring: PageQuery,
    response: { 200: Paginated(Group), ...errorResponses(401) },
  },
  create: {
    tags,
    summary: 'Start a group',
    description: 'You become its owner and first member.',
    body: CreateGroupBody,
    response: { 201: Group, ...errorResponses(400, 401) },
  },
  get: { tags, summary: 'A group', params: IdParams, response: { 200: Group, ...errorResponses(401, 404) } },
  update: {
    tags,
    summary: 'Edit a group (owner or admin)',
    params: IdParams,
    body: UpdateGroupBody,
    response: { 200: Group, ...errorResponses(400, 401, 403, 404) },
  },
  remove: {
    tags,
    summary: 'Delete a group and its chat (owner or admin)',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  join: {
    tags,
    summary: 'Join a group (idempotent)',
    params: IdParams,
    response: { 200: Group, ...errorResponses(401, 404) },
  },
  leave: {
    tags,
    summary: 'Leave a group (idempotent; owners cannot leave)',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 404, 409) },
  },
  members: {
    tags,
    summary: 'Group members',
    params: IdParams,
    querystring: PageQuery,
    response: { 200: Paginated(GroupMember), ...errorResponses(401, 404) },
  },
  messages: {
    tags,
    summary: 'Group chat history',
    description: 'Items are oldest → newest within the page; `nextCursor` loads older messages.',
    params: IdParams,
    querystring: PageQuery,
    response: { 200: Paginated(GroupMessage), ...errorResponses(401, 404) },
  },
  send: {
    tags,
    summary: 'Send a group message (members only)',
    params: IdParams,
    body: SendGroupMessageBody,
    response: { 201: GroupMessage, ...errorResponses(400, 401, 403, 404) },
  },
};
