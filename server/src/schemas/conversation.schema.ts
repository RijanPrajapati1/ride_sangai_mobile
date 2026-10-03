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

/** Mirrors the Dart `Conversation` entity, as seen by the viewer. */
export const Conversation = Type.Object({
  id: Uuid,
  userId: Uuid,
  userName: Type.String(),
  userAvatarUrl: Type.String(),
  lastMessage: Type.String({ description: "'Say hello 👋' until the first message." }),
  lastMessageTime: Timestamp,
  lastMessageSenderId: Nullable(Uuid),
  unreadCount: Type.Integer(),
});

/** Mirrors the Dart `Message` entity. */
export const Message = Type.Object({
  id: Uuid,
  conversationId: Uuid,
  senderId: Uuid,
  text: Type.String(),
  sentAt: Timestamp,
  isMe: Type.Boolean(),
});

export const OpenConversationBody = Type.Object({ userId: Uuid }, { additionalProperties: false });
export const SendMessageBody = Type.Object({ text: Text(2000) }, { additionalProperties: false });
export const MessagesQuery = Type.Object({
  ...paginationQuery,
  markRead: Type.Optional(
    Type.Boolean({ default: true, description: 'Mark the conversation read when loading the latest page.' }),
  ),
});
export const UnreadCount = Type.Object({ count: Type.Integer() });

const tags = ['Messages'];

export const conversationSchemas = {
  inbox: {
    tags,
    summary: 'My conversations, most recent first',
    querystring: Type.Object(paginationQuery),
    response: { 200: Paginated(Conversation), ...errorResponses(400, 401) },
  },
  open: {
    tags,
    summary: 'Open (get or create) my conversation with a rider',
    description: '200 when it already existed, 201 when created.',
    body: OpenConversationBody,
    response: { 200: Conversation, 201: Conversation, ...errorResponses(400, 401, 404) },
  },
  unreadCount: {
    tags,
    summary: 'Unread messages across all conversations',
    response: { 200: UnreadCount, ...errorResponses(401) },
  },
  get: {
    tags,
    summary: 'A conversation',
    params: IdParams,
    response: { 200: Conversation, ...errorResponses(401, 404) },
  },
  messages: {
    tags,
    summary: 'Message history',
    description: 'Items are oldest → newest within the page; `nextCursor` loads older messages.',
    params: IdParams,
    querystring: MessagesQuery,
    response: { 200: Paginated(Message), ...errorResponses(400, 401, 404) },
  },
  send: {
    tags,
    summary: 'Send a message',
    params: IdParams,
    body: SendMessageBody,
    response: { 201: Message, ...errorResponses(400, 401, 404) },
  },
  markRead: {
    tags,
    summary: 'Mark a conversation read',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 404) },
  },
};
