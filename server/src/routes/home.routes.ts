import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { HomeController } from '../controllers/home.controller.js';
import { homeSchemas as s } from '../schemas/home.schema.js';

/** /api/v1/home, /api/v1/me/badges, /api/v1/banners, /api/v1/meta */
const homeRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new HomeController(app.services.home);

  app.get('/home', { schema: s.home }, c.get);
  app.get('/me/badges', { schema: s.badges }, c.badges);
  app.get('/banners', { schema: s.banners }, c.banners);
  app.get('/meta', { config: { auth: 'none' }, schema: s.meta }, c.meta);
};

export default homeRoutes;
