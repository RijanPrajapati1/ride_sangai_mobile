import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { RideController } from '../controllers/ride.controller.js';
import { rideSchemas as s } from '../schemas/ride.schema.js';

/** /api/v1/rides…, /api/v1/ride-requests…, /api/v1/me/rides, /api/v1/users/:id/rides */
const rideRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new RideController(app.services.ride);

  app.get('/rides', { schema: s.discover }, c.discover);
  app.post('/rides', { schema: s.create }, c.create);
  app.get('/rides/:id', { schema: s.get }, c.get);
  app.patch('/rides/:id', { schema: s.update }, c.update);
  app.delete('/rides/:id', { schema: s.remove }, c.remove);
  app.get('/rides/:id/participants', { schema: s.participants }, c.participants);
  app.post('/rides/:id/join', { schema: s.join }, c.join);
  app.delete('/rides/:id/join', { schema: s.leave }, c.leave);
  app.get('/rides/:id/requests', { schema: s.rideRequests }, c.rideRequests);

  app.get('/me/rides', { schema: s.myRides }, c.myRides);
  app.get('/me/ride-requests', { schema: s.inbox }, c.inbox);
  app.get('/users/:id/rides', { schema: s.byOrganizer }, c.byOrganizer);

  app.post('/ride-requests/:id/approve', { schema: s.approve }, c.approve);
  app.post('/ride-requests/:id/decline', { schema: s.decline }, c.decline);
};

export default rideRoutes;
