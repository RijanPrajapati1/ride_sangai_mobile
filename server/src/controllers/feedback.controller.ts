import { currentUser } from '../middlewares/authenticate.js';
import type { feedbackSchemas } from '../schemas/feedback.schema.js';
import type { FeedbackService } from '../services/feedback.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof feedbackSchemas;

export class FeedbackController {
  constructor(private readonly feedback: FeedbackService) {}

  send = async (request: Req<S['send']>, reply: Rep<S['send']>) =>
    reply.status(201).send(await this.feedback.send(currentUser(request).id, request.body));
}
