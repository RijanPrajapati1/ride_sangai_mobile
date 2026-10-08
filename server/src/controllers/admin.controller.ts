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

  user = async (request: Req<S['user']>) => this.admin.getUser(currentUser(request), request.params.id);

  updateUser = async (request: Req<S['updateUser']>) =>
    this.admin.updateUser(currentUser(request), request.params.id, request.body);

  disableUser = async (request: Req<S['disableUser']>) =>
    this.admin.setDisabled(currentUser(request), request.params.id, true, request.body?.reason);

  enableUser = async (request: Req<S['enableUser']>) =>
    this.admin.setDisabled(currentUser(request), request.params.id, false);

  signOutUser = async (request: Req<S['signOutUser']>) =>
    this.admin.signOutEverywhere(currentUser(request), request.params.id);

  setPassword = async (request: Req<S['setPassword']>, reply: Rep<S['setPassword']>) => {
    await this.admin.setPassword(currentUser(request), request.params.id, request.body.password);
    return reply.status(204).send();
  };

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

  editRide = async (request: Req<S['editRide']>) =>
    this.admin.editRide(currentUser(request), request.params.id, request.body);

  approveRequest = async (request: Req<S['approveRequest']>) =>
    this.rideService.approve(currentUser(request), request.params.id);

  declineRequest = async (request: Req<S['declineRequest']>) =>
    this.rideService.decline(currentUser(request), request.params.id, request.body?.reason);

  removeRide = async (request: Req<S['removeRide']>, reply: Rep<S['removeRide']>) => {
    await this.rideService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  rideRequests = async (request: Req<S['rideRequests']>) => this.rideService.allRequests(request.query);

  posts = async (request: Req<S['posts']>) => this.postService.feed(currentUser(request).id, request.query);

  editPost = async (request: Req<S['editPost']>) =>
    this.admin.editPost(currentUser(request), request.params.id, request.body);

  comments = async (request: Req<S['comments']>) => this.admin.comments(request.query);

  removeComment = async (request: Req<S['removeComment']>, reply: Rep<S['removeComment']>) => {
    await this.admin.removeComment(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  removePost = async (request: Req<S['removePost']>, reply: Rep<S['removePost']>) => {
    await this.postService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  groups = async (request: Req<S['groups']>) =>
    this.groupService.list(currentUser(request).id, { ...request.query, sort: 'newest' });

  editGroup = async (request: Req<S['editGroup']>) =>
    this.admin.editGroup(currentUser(request), request.params.id, request.body);

  removeGroup = async (request: Req<S['removeGroup']>, reply: Rep<S['removeGroup']>) => {
    await this.groupService.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  places = async (request: Req<S['places']>) =>
    this.placeService.list(currentUser(request).id, { ...request.query, sort: 'newest' });

  editPlace = async (request: Req<S['editPlace']>) =>
    this.admin.editPlace(currentUser(request), request.params.id, request.body);

  reviews = async (request: Req<S['reviews']>) => this.admin.reviews(request.query);

  removeReview = async (request: Req<S['removeReview']>, reply: Rep<S['removeReview']>) => {
    await this.admin.removeReview(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

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

  announce = async (request: Req<S['announce']>, reply: Rep<S['announce']>) =>
    reply.status(201).send(await this.admin.announce(currentUser(request), request.body));

  announcements = async (request: Req<S['announcements']>) => this.admin.announcements(request.query);

  auditLog = async (request: Req<S['auditLog']>) => this.admin.auditLog(request.query);
}
