import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { FeedbackController } from '../controllers/feedback.controller.js';
import { feedbackSchemas as s } from '../schemas/feedback.schema.js';

/** POST /api/v1/feedback */
const feedbackRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const c = new FeedbackController(app.services.feedback);

  // Plenty for real feedback, too few to flood the inbox.
  const limited = app.config.rateLimit.enabled ? { rateLimit: { max: 10, timeWindow: 60 * 60_000 } } : {};

  app.post('/feedback', { config: limited, schema: s.send }, c.send);
};

export default feedbackRoutes;
