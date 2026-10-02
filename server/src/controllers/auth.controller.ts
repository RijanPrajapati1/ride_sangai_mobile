import type { FastifyRequest } from 'fastify';
import { currentUser } from '../middlewares/authenticate.js';
import type { authSchemas } from '../schemas/auth.schema.js';
import type { AuthService, ClientInfo } from '../services/auth.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof authSchemas;

function clientInfo(request: FastifyRequest): ClientInfo {
  return { userAgent: request.headers['user-agent'] ?? null, ip: request.ip ?? null };
}

export class AuthController {
  constructor(private readonly auth: AuthService) {}

  register = async (request: Req<S['register']>, reply: Rep<S['register']>) =>
    reply.status(201).send(await this.auth.register(request.body, clientInfo(request)));

  login = async (request: Req<S['login']>) => this.auth.login(request.body, clientInfo(request));

  refresh = async (request: Req<S['refresh']>) => this.auth.refresh(request.body.refreshToken);

  logout = async (request: Req<S['logout']>, reply: Rep<S['logout']>) => {
    await this.auth.logout(currentUser(request).sessionId);
    return reply.status(204).send();
  };

  logoutAll = async (request: Req<S['logoutAll']>, reply: Rep<S['logoutAll']>) => {
    await this.auth.logoutAll(currentUser(request).id);
    return reply.status(204).send();
  };

  forgotPassword = async (request: Req<S['forgotPassword']>, reply: Rep<S['forgotPassword']>) => {
    await this.auth.requestPasswordReset(request.body.email);
    return reply.status(202).send({ message: 'If an account exists for that email, a reset link has been sent.' });
  };

  resetPassword = async (request: Req<S['resetPassword']>, reply: Rep<S['resetPassword']>) => {
    await this.auth.resetPassword(request.body.token, request.body.password);
    return reply.status(204).send();
  };

  changePassword = async (request: Req<S['changePassword']>, reply: Rep<S['changePassword']>) => {
    await this.auth.changePassword(currentUser(request), request.body.currentPassword, request.body.newPassword);
    return reply.status(204).send();
  };

  me = async (request: Req<S['me']>) => this.auth.me(currentUser(request).id);

  sessions = async (request: Req<S['sessions']>) => {
    const user = currentUser(request);
    const sessions = await this.auth.listSessions(user.id);
    return {
      items: sessions.map((session) => ({ ...session, current: session.id === user.sessionId })),
    };
  };

  revokeSession = async (request: Req<S['revokeSession']>, reply: Rep<S['revokeSession']>) => {
    await this.auth.revokeOwnSession(currentUser(request).id, request.params.id);
    return reply.status(204).send();
  };
}
