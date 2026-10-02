import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { GroupController } from '../controllers/group.controller.js';
import { groupSchemas as s } from '../schemas/group.schema.js';

/** /api/v1/groups… */
const groupRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new GroupController(app.services.group);

  app.get('/groups', { schema: s.list }, c.list);
  app.get('/groups/mine', { schema: s.mine }, c.mine);
  app.post('/groups', { schema: s.create }, c.create);
  app.get('/groups/:id', { schema: s.get }, c.get);
  app.patch('/groups/:id', { schema: s.update }, c.update);
  app.delete('/groups/:id', { schema: s.remove }, c.remove);
  app.post('/groups/:id/join', { schema: s.join }, c.join);
  app.post('/groups/:id/leave', { schema: s.leave }, c.leave);
  app.get('/groups/:id/members', { schema: s.members }, c.members);
  app.get('/groups/:id/messages', { schema: s.messages }, c.messages);
  app.post('/groups/:id/messages', { schema: s.send }, c.send);
};

export default groupRoutes;
