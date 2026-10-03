import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { AuthController } from '../controllers/auth.controller.js';
import { authSchemas as s } from '../schemas/auth.schema.js';

/** /api/v1/auth */
const authRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new AuthController(app.services.auth);

  // Credential endpoints get a much tighter per-IP budget than the global limit.
  const strict = app.config.rateLimit.enabled
    ? { rateLimit: { max: app.config.rateLimit.authMax, timeWindow: app.config.rateLimit.windowMs } }
    : {};
  const pub = { auth: 'none' as const, ...strict };

  app.post('/register', { config: pub, schema: s.register }, c.register);
  app.post('/login', { config: pub, schema: s.login }, c.login);
  app.post('/refresh', { config: pub, schema: s.refresh }, c.refresh);
  app.post('/forgot-password', { config: pub, schema: s.forgotPassword }, c.forgotPassword);
  app.post('/reset-password', { config: pub, schema: s.resetPassword }, c.resetPassword);

  app.post('/logout', { schema: s.logout }, c.logout);
  app.post('/logout-all', { schema: s.logoutAll }, c.logoutAll);
  app.post('/change-password', { schema: s.changePassword }, c.changePassword);
  app.get('/me', { schema: s.me }, c.me);
  app.get('/sessions', { schema: s.sessions }, c.sessions);
  app.delete('/sessions/:id', { schema: s.revokeSession }, c.revokeSession);
};

export default authRoutes;
