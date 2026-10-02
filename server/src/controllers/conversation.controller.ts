import { currentUser } from '../middlewares/authenticate.js';
import type { conversationSchemas } from '../schemas/conversation.schema.js';
import type { ConversationService } from '../services/conversation.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof conversationSchemas;

export class ConversationController {
  constructor(private readonly conversations: ConversationService) {}

  inbox = async (request: Req<S['inbox']>) => this.conversations.inbox(currentUser(request).id, request.query);

  open = async (request: Req<S['open']>, reply: Rep<S['open']>) => {
    const { conversation, created } = await this.conversations.open(currentUser(request).id, request.body.userId);
    return reply.status(created ? 201 : 200).send(conversation);
  };

  unreadCount = async (request: Req<S['unreadCount']>) => ({ count: await this.conversations.totalUnread(currentUser(request).id) });

  get = async (request: Req<S['get']>) => this.conversations.get(request.params.id, currentUser(request).id);

  messages = async (request: Req<S['messages']>) =>
    this.conversations.messages(request.params.id, currentUser(request).id, request.query);

  send = async (request: Req<S['send']>, reply: Rep<S['send']>) =>
    reply.status(201).send(await this.conversations.send(currentUser(request), request.params.id, request.body.text));

  markRead = async (request: Req<S['markRead']>, reply: Rep<S['markRead']>) => {
    await this.conversations.markRead(request.params.id, currentUser(request).id);
    return reply.status(204).send();
  };
}
