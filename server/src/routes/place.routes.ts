import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { PlaceController } from '../controllers/place.controller.js';
import { placeSchemas as s } from '../schemas/place.schema.js';

/** /api/v1/places… (Explore), /api/v1/me/saved-places, /api/v1/users/:id/places */
const placeRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new PlaceController(app.services.place);

  app.get('/places/nearby', { schema: s.nearby }, c.nearby);
  app.get('/places', { schema: s.list }, c.list);
  app.post('/places', { schema: s.create }, c.create);
  app.get('/places/:id', { schema: s.get }, c.get);
  app.patch('/places/:id', { schema: s.update }, c.update);
  app.delete('/places/:id', { schema: s.remove }, c.remove);
  app.put('/places/:id/save', { schema: s.save }, c.save);
  app.delete('/places/:id/save', { schema: s.unsave }, c.unsave);
  app.get('/places/:id/reviews', { schema: s.reviews }, c.reviews);
  app.put('/places/:id/review', { schema: s.review }, c.review);
  app.delete('/places/:id/review', { schema: s.removeReview }, c.removeReview);

  app.get('/me/saved-places', { schema: s.saved }, c.saved);
  app.get('/users/:id/places', { schema: s.byAuthor }, c.byAuthor);
};

export default placeRoutes;
