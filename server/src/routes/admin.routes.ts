import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { AdminController } from '../controllers/admin.controller.js';
import { adminSchemas as s } from '../schemas/admin.schema.js';

/** /api/v1/superadmin… (the web dashboard) — every route here requires the superadmin role. */
const adminRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.addHook('onRoute', (route) => {
    route.config = {
      ...(route.config ?? {}),
      auth: 'required',
      roles: ['superadmin'],
    } as typeof route.config;
  });

  const { admin, ride, post, group, place, feedback } = app.services;
  const c = new AdminController(admin, ride, post, group, place, feedback);

  app.get('/stats', { schema: s.stats }, c.stats);
  app.get('/analytics', { schema: s.analytics }, c.analytics);
  app.get('/top-users', { schema: s.topUsers }, c.topUsers);
  app.get('/feedback', { schema: s.feedback }, c.feedback);
  app.patch('/feedback/:id', { schema: s.updateFeedback }, c.updateFeedback);
  app.delete('/feedback/:id', { schema: s.removeFeedback }, c.removeFeedback);
  app.get('/users', { schema: s.users }, c.users);
  app.get('/users/:id', { schema: s.user }, c.user);
  app.patch('/users/:id', { schema: s.updateUser }, c.updateUser);
  app.post('/users/:id/disable', { schema: s.disableUser }, c.disableUser);
  app.post('/users/:id/enable', { schema: s.enableUser }, c.enableUser);
  app.post('/users/:id/sign-out', { schema: s.signOutUser }, c.signOutUser);
  app.put('/users/:id/password', { schema: s.setPassword }, c.setPassword);
  app.patch('/users/:id/role', { schema: s.setRole }, c.setRole);
  app.delete('/users/:id', { schema: s.removeUser }, c.removeUser);
  app.get('/rides', { schema: s.rides }, c.rides);
  app.patch('/rides/:id', { schema: s.editRide }, c.editRide);
  app.delete('/rides/:id', { schema: s.removeRide }, c.removeRide);
  app.get('/ride-requests', { schema: s.rideRequests }, c.rideRequests);
  app.post('/ride-requests/:id/approve', { schema: s.approveRequest }, c.approveRequest);
  app.post('/ride-requests/:id/decline', { schema: s.declineRequest }, c.declineRequest);
  app.get('/posts', { schema: s.posts }, c.posts);
  app.patch('/posts/:id', { schema: s.editPost }, c.editPost);
  app.delete('/posts/:id', { schema: s.removePost }, c.removePost);
  app.get('/comments', { schema: s.comments }, c.comments);
  app.delete('/comments/:id', { schema: s.removeComment }, c.removeComment);
  app.get('/groups', { schema: s.groups }, c.groups);
  app.patch('/groups/:id', { schema: s.editGroup }, c.editGroup);
  app.delete('/groups/:id', { schema: s.removeGroup }, c.removeGroup);
  app.get('/places', { schema: s.places }, c.places);
  app.patch('/places/:id', { schema: s.editPlace }, c.editPlace);
  app.delete('/places/:id', { schema: s.removePlace }, c.removePlace);
  app.get('/reviews', { schema: s.reviews }, c.reviews);
  app.delete('/reviews/:id', { schema: s.removeReview }, c.removeReview);
  app.post('/announcements', { schema: s.announce }, c.announce);
  app.get('/announcements', { schema: s.announcements }, c.announcements);
  app.get('/banners', { schema: s.banners }, c.banners);
  app.post('/banners', { schema: s.createBanner }, c.createBanner);
  app.patch('/banners/:id', { schema: s.updateBanner }, c.updateBanner);
  app.delete('/banners/:id', { schema: s.deleteBanner }, c.deleteBanner);
  app.get('/audit-log', { schema: s.auditLog }, c.auditLog);
};

export default adminRoutes;
