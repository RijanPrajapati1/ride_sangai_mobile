import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { PostController } from '../controllers/post.controller.js';
import { postSchemas as s } from '../schemas/post.schema.js';

/** /api/v1/posts… and /api/v1/comments… */
const postRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new PostController(app.services.post);

  app.get('/posts', { schema: s.feed }, c.feed);
  app.post('/posts', { schema: s.create }, c.create);
  app.get('/posts/:id', { schema: s.get }, c.get);
  app.patch('/posts/:id', { schema: s.update }, c.update);
  app.delete('/posts/:id', { schema: s.remove }, c.remove);
  app.put('/posts/:id/like', { schema: s.like }, c.like);
  app.delete('/posts/:id/like', { schema: s.unlike }, c.unlike);
  app.get('/posts/:id/comments', { schema: s.comments }, c.comments);
  app.post('/posts/:id/comments', { schema: s.addComment }, c.addComment);

  app.delete('/comments/:id', { schema: s.removeComment }, c.removeComment);
  app.put('/comments/:id/like', { schema: s.likeComment }, c.likeComment);
  app.delete('/comments/:id/like', { schema: s.unlikeComment }, c.unlikeComment);
};

export default postRoutes;
