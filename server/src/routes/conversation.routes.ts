import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { ConversationController } from '../controllers/conversation.controller.js';
import { conversationSchemas as s } from '../schemas/conversation.schema.js';

/** /api/v1/conversations… */
const conversationRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new ConversationController(app.services.conversation);

  app.get('/conversations', { schema: s.inbox }, c.inbox);
  app.post('/conversations', { schema: s.open }, c.open);
  app.get('/conversations/unread-count', { schema: s.unreadCount }, c.unreadCount);
  app.get('/conversations/:id', { schema: s.get }, c.get);
  app.get('/conversations/:id/messages', { schema: s.messages }, c.messages);
  app.post('/conversations/:id/messages', { schema: s.send }, c.send);
  app.post('/conversations/:id/read', { schema: s.markRead }, c.markRead);
};

export default conversationRoutes;
