import { currentUser } from '../middlewares/authenticate.js';
import type { postSchemas } from '../schemas/post.schema.js';
import type { PostService } from '../services/post.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof postSchemas;

export class PostController {
  constructor(private readonly posts: PostService) {}

  feed = async (request: Req<S['feed']>) => this.posts.feed(currentUser(request).id, request.query);

  create = async (request: Req<S['create']>, reply: Rep<S['create']>) =>
    reply.status(201).send(await this.posts.create(currentUser(request), request.body));

  get = async (request: Req<S['get']>) => this.posts.get(request.params.id, currentUser(request).id);

  update = async (request: Req<S['update']>) => this.posts.update(currentUser(request), request.params.id, request.body);

  remove = async (request: Req<S['remove']>, reply: Rep<S['remove']>) => {
    await this.posts.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  like = async (request: Req<S['like']>) => this.posts.like(currentUser(request), request.params.id);

  unlike = async (request: Req<S['unlike']>) => this.posts.unlike(currentUser(request), request.params.id);

  comments = async (request: Req<S['comments']>) => this.posts.comments(request.params.id, currentUser(request).id, request.query);

  addComment = async (request: Req<S['addComment']>, reply: Rep<S['addComment']>) =>
    reply.status(201).send(await this.posts.addComment(currentUser(request), request.params.id, request.body.text));

  removeComment = async (request: Req<S['removeComment']>, reply: Rep<S['removeComment']>) => {
    await this.posts.removeComment(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  likeComment = async (request: Req<S['likeComment']>) => this.posts.likeComment(currentUser(request), request.params.id);

  unlikeComment = async (request: Req<S['unlikeComment']>) => this.posts.unlikeComment(currentUser(request), request.params.id);
}
