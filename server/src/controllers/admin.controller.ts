import { currentUser } from '../middlewares/authenticate.js';
import type { adminSchemas } from '../schemas/admin.schema.js';
import type { AdminService } from '../services/admin.service.js';
import type { FeedbackService } from '../services/feedback.service.js';
import type { GroupService } from '../services/group.service.js';
import type { PlaceService } from '../services/place.service.js';
import type { PostService } from '../services/post.service.js';
import type { RideService } from '../services/ride.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof adminSchemas;

export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly rideService: RideService,
    private readonly postService: PostService,
    private readonly groupService: GroupService,
    private readonly placeService: PlaceService,
    private readonly feedbackService: FeedbackService,
  ) {}

  stats = async () => this.admin.stats();

  analytics = async (request: Req<S['analytics']>) => this.admin.analytics(request.query.days);

  topUsers = async (request: Req<S['topUsers']>) =>
    this.admin.topUsers(request.query.metric, request.query.limit);

  feedback = async (request: Req<S['feedback']>) => this.feedbackService.list(request.query);

  removeFeedback = async (request: Req<S['removeFeedback']>, reply: Rep<S['removeFeedback']>) => {
    await this.feedbackService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  updateFeedback = async (request: Req<S['updateFeedback']>) =>
    this.feedbackService.update(currentUser(request), request.params.id, request.body);

  users = async (request: Req<S['users']>) => this.admin.listUsers(currentUser(request), request.query);

  setRole = async (request: Req<S['setRole']>) =>
    this.admin.setRole(currentUser(request), request.params.id, request.body.role);

  removeUser = async (request: Req<S['removeUser']>, reply: Rep<S['removeUser']>) => {
    await this.admin.removeUser(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  rides = async (request: Req<S['rides']>) => {
    const { from, to, ...rest } = request.query;
    return this.rideService.listAll(currentUser(request).id, {
      ...rest,
      ...(from ? { from: new Date(from) } : {}),
      ...(to ? { to: new Date(to) } : {}),
    });
  };

  removeRide = async (request: Req<S['removeRide']>, reply: Rep<S['removeRide']>) => {
    await this.rideService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  rideRequests = async (request: Req<S['rideRequests']>) => this.rideService.allRequests(request.query);

  posts = async (request: Req<S['posts']>) => this.postService.feed(currentUser(request).id, request.query);

  removePost = async (request: Req<S['removePost']>, reply: Rep<S['removePost']>) => {
    await this.postService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  groups = async (request: Req<S['groups']>) =>
    this.groupService.list(currentUser(request).id, { ...request.query, sort: 'newest' });

  removeGroup = async (request: Req<S['removeGroup']>, reply: Rep<S['removeGroup']>) => {
    await this.groupService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  places = async (request: Req<S['places']>) =>
    this.placeService.list(currentUser(request).id, { ...request.query, sort: 'newest' });

  removePlace = async (request: Req<S['removePlace']>, reply: Rep<S['removePlace']>) => {
    await this.placeService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  banners = async () => ({ items: await this.admin.listBanners() });

  createBanner = async (request: Req<S['createBanner']>, reply: Rep<S['createBanner']>) =>
    reply.status(201).send(await this.admin.createBanner(request.body));

  updateBanner = async (request: Req<S['updateBanner']>) =>
    this.admin.updateBanner(request.params.id, request.body);

  deleteBanner = async (request: Req<S['deleteBanner']>, reply: Rep<S['deleteBanner']>) => {
    await this.admin.deleteBanner(request.params.id);
    return reply.status(204).send();
  };

  auditLog = async (request: Req<S['auditLog']>) => this.admin.auditLog(request.query);
}
