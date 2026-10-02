import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { UserController } from '../controllers/user.controller.js';
import { userSchemas as s } from '../schemas/user.schema.js';

/** /api/v1/me… and /api/v1/users… */
const userRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new UserController(app.services.user);

  app.get('/me', { schema: s.me }, c.me);
  app.patch('/me', { schema: s.updateMe }, c.updateMe);
  app.delete('/me', { schema: s.deleteMe }, c.deleteMe);
  app.get('/me/preferences', { schema: s.getPreferences }, c.getPreferences);
  app.put('/me/preferences', { schema: s.replacePreferences }, c.replacePreferences);
  app.patch('/me/preferences', { schema: s.patchPreferences }, c.patchPreferences);

  app.get('/users', { schema: s.search }, c.search);
  app.get('/users/recommended', { schema: s.recommended }, c.recommended);
  app.get('/users/:id', { schema: s.getById }, c.getById);
  app.put('/users/:id/follow', { schema: s.follow }, c.follow);
  app.delete('/users/:id/follow', { schema: s.unfollow }, c.unfollow);
  app.get('/users/:id/followers', { schema: s.followers }, c.followers);
  app.get('/users/:id/following', { schema: s.following }, c.following);
};

export default userRoutes;
