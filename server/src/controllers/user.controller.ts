import { currentUser } from '../middlewares/authenticate.js';
import type { userSchemas } from '../schemas/user.schema.js';
import type { UserService } from '../services/user.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof userSchemas;

export class UserController {
  constructor(private readonly users: UserService) {}

  me = async (request: Req<S['me']>) => {
    const user = currentUser(request);
    return this.users.getProfile(user.id, user);
  };

  updateMe = async (request: Req<S['updateMe']>) => this.users.updateProfile(currentUser(request).id, request.body);

  deleteMe = async (request: Req<S['deleteMe']>, reply: Rep<S['deleteMe']>) => {
    await this.users.deleteAccount(currentUser(request).id, request.body.password);
    return reply.status(204).send();
  };

  getPreferences = async (request: Req<S['getPreferences']>) => this.users.getPreferences(currentUser(request).id);

  replacePreferences = async (request: Req<S['replacePreferences']>) =>
    this.users.updatePreferences(currentUser(request).id, request.body);

  patchPreferences = async (request: Req<S['patchPreferences']>) =>
    this.users.updatePreferences(currentUser(request).id, request.body);

  search = async (request: Req<S['search']>) => this.users.search(currentUser(request), request.query);

  recommended = async (request: Req<S['recommended']>) => ({
    items: await this.users.recommended(currentUser(request), request.query),
  });

  getById = async (request: Req<S['getById']>) => this.users.getProfile(request.params.id, currentUser(request));

  follow = async (request: Req<S['follow']>) => this.users.follow(currentUser(request).id, request.params.id);

  unfollow = async (request: Req<S['unfollow']>) => this.users.unfollow(currentUser(request).id, request.params.id);

  followers = async (request: Req<S['followers']>) =>
    this.users.followEdges(request.params.id, 'followers', currentUser(request).id, request.query);

  following = async (request: Req<S['following']>) =>
    this.users.followEdges(request.params.id, 'following', currentUser(request).id, request.query);
}
