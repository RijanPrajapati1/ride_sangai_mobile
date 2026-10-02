import { currentUser } from '../middlewares/authenticate.js';
import type { groupSchemas } from '../schemas/group.schema.js';
import type { GroupService } from '../services/group.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof groupSchemas;

export class GroupController {
  constructor(private readonly groups: GroupService) {}

  list = async (request: Req<S['list']>) => this.groups.list(currentUser(request).id, request.query);

  mine = async (request: Req<S['mine']>) => this.groups.mine(currentUser(request).id, request.query);

  create = async (request: Req<S['create']>, reply: Rep<S['create']>) =>
    reply.status(201).send(await this.groups.create(currentUser(request), request.body));

  get = async (request: Req<S['get']>) => this.groups.get(request.params.id, currentUser(request).id);

  update = async (request: Req<S['update']>) =>
    this.groups.update(currentUser(request), request.params.id, request.body);

  remove = async (request: Req<S['remove']>, reply: Rep<S['remove']>) => {
    await this.groups.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  join = async (request: Req<S['join']>) => this.groups.join(currentUser(request), request.params.id);

  leave = async (request: Req<S['leave']>, reply: Rep<S['leave']>) => {
    await this.groups.leave(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  members = async (request: Req<S['members']>) => this.groups.members(request.params.id, request.query);

  messages = async (request: Req<S['messages']>) =>
    this.groups.messages(request.params.id, currentUser(request).id, request.query);

  send = async (request: Req<S['send']>, reply: Rep<S['send']>) =>
    reply
      .status(201)
      .send(await this.groups.send(currentUser(request), request.params.id, request.body.text));
}
