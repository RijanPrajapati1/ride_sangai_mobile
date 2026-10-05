import { Type } from 'typebox';
import { TOP_USER_METRICS } from '../constants/enums.js';
import { paginationQuery } from '../utils/pagination.js';
import {
  ActivityCategorySchema,
  DateTimeInput,
  IdParams,
  NoContent,
  Nullable,
  Paginated,
  RideRequestStatusSchema,
  Text,
  Timestamp,
  UserRoleSchema,
  Uuid,
  errorResponses,
} from './common.schema.js';
import { Banner } from './home.schema.js';
import {
  AdminFeedback,
  FeedbackCategorySchema,
  FeedbackStatusSchema,
  UpdateFeedbackBody,
} from './feedback.schema.js';
import { CommunityPost } from './post.schema.js';
import { Group } from './group.schema.js';
import { Place } from './place.schema.js';
import { Ride, RideListQuery, RideRequestPage } from './ride.schema.js';
import { UserProfile } from './user.schema.js';

export const AdminStats = Type.Object({
  riders: Type.Integer(),
  superadmins: Type.Integer(),
  rides: Type.Integer(),
  upcomingRides: Type.Integer(),
  pendingRequests: Type.Integer(),
  posts: Type.Integer(),
  comments: Type.Integer(),
  groups: Type.Integer(),
  places: Type.Integer(),
  newRidersLast7Days: Type.Integer(),
});

const Breakdown = Type.Array(Type.Object({ key: Type.String(), count: Type.Integer() }));

export const Analytics = Type.Object({
  days: Type.Integer({ description: 'Length of the window in days, ending today (UTC).' }),
  totals: Type.Object({
    signups: Type.Integer(),
    rides: Type.Integer(),
    joinRequests: Type.Integer(),
    posts: Type.Integer(),
    comments: Type.Integer(),
    messages: Type.Integer(),
    places: Type.Integer(),
    feedback: Type.Integer(),
  }),
  daily: Type.Array(
    Type.Object({
      date: Type.String({ format: 'date', description: 'UTC day, YYYY-MM-DD.' }),
      signups: Type.Integer(),
      rides: Type.Integer(),
      joinRequests: Type.Integer(),
      posts: Type.Integer(),
      comments: Type.Integer(),
      messages: Type.Integer(),
      places: Type.Integer(),
      feedback: Type.Integer(),
    }),
  ),
  activeUsers: Type.Object(
    { last24Hours: Type.Integer(), last7Days: Type.Integer(), last30Days: Type.Integer() },
    { description: 'Distinct users whose session was used in the window.' },
  ),
  ridesByCategory: Breakdown,
  ridesByDifficulty: Breakdown,
  requestsByStatus: Breakdown,
  placesByCategory: Breakdown,
  feedbackByStatus: Breakdown,
  feedbackAverageRating: Nullable(Type.Number()),
  feedbackRatings: Type.Integer({ description: 'How many feedback items have a rating.' }),
});

export const TopUserMetricSchema = Type.Enum(TOP_USER_METRICS);

export const TopUser = Type.Object({
  rank: Type.Integer(),
  id: Uuid,
  name: Type.String(),
  email: Type.String(),
  avatarUrl: Type.String(),
  joinedAt: Timestamp,
  followers: Type.Integer(),
  ridesOrganized: Type.Integer(),
  ridesJoined: Type.Integer(),
  posts: Type.Integer(),
  likesReceived: Type.Integer(),
  places: Type.Integer(),
});

export const AdminUser = Type.Object({
  ...UserProfile.properties,
  role: UserRoleSchema,
  createdAt: Timestamp,
  lastLoginAt: Nullable(Timestamp),
});

export const AuditEntry = Type.Object({
  id: Uuid,
  actorId: Nullable(Uuid),
  actorName: Nullable(Type.String()),
  action: Type.String(),
  targetType: Type.String(),
  targetId: Nullable(Uuid),
  details: Type.Unknown(),
  createdAt: Timestamp,
});

const bannerFields = {
  category: Nullable(ActivityCategorySchema),
  title: Text(80),
  subtitle: Type.String({ maxLength: 240 }),
  ctaLabel: Type.String({ maxLength: 40 }),
  ctaUrl: Nullable(Type.String({ maxLength: 2048 })),
  imageUrl: Nullable(Type.String({ maxLength: 2048 })),
  icon: Nullable(Type.String({ maxLength: 64 })),
  theme: Nullable(Type.String({ maxLength: 32 })),
  sortOrder: Type.Integer({ minimum: -1000, maximum: 1000 }),
  isActive: Type.Boolean(),
  startsAt: Nullable(DateTimeInput),
  endsAt: Nullable(DateTimeInput),
};

export const CreateBannerBody = Type.Object(
  { ...Type.Partial(Type.Object(bannerFields)).properties, title: bannerFields.title },
  { additionalProperties: false },
);
export const UpdateBannerBody = Type.Partial(Type.Object(bannerFields), {
  additionalProperties: false,
  minProperties: 1,
});

const tags = ['Superadmin'];
const PageQuery = Type.Object(paginationQuery);

export const adminSchemas = {
  stats: { tags, summary: 'Dashboard counts', response: { 200: AdminStats, ...errorResponses(401, 403) } },
  users: {
    tags,
    summary: 'Riders (or admins), alphabetical',
    querystring: Type.Object({
      q: Type.Optional(Type.String({ maxLength: 80, description: 'Name or email.' })),
      role: Type.Optional(UserRoleSchema),
      ...paginationQuery,
    }),
    response: { 200: Paginated(AdminUser), ...errorResponses(400, 401, 403) },
  },
  setRole: {
    tags,
    summary: 'Promote or demote a user',
    params: IdParams,
    body: Type.Object({ role: UserRoleSchema }, { additionalProperties: false }),
    response: { 200: UserProfile, ...errorResponses(400, 401, 403, 404, 409) },
  },
  removeUser: {
    tags,
    summary: 'Remove a rider and everything they own',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404, 409) },
  },
  rides: {
    tags,
    summary: 'All rides, newest start first',
    querystring: Type.Object({
      ...RideListQuery.properties,
      when: Type.Optional(Type.Enum(['upcoming', 'past', 'all'], { default: 'all' })),
    }),
    response: { 200: Paginated(Ride), ...errorResponses(400, 401, 403) },
  },
  removeRide: {
    tags,
    summary: 'Remove a ride (participants are notified)',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  rideRequests: {
    tags,
    summary: 'All join requests, newest first',
    description: 'Approve/decline with POST /ride-requests/:id/approve|decline (admins may act on any ride).',
    querystring: Type.Object({ status: Type.Optional(RideRequestStatusSchema), ...paginationQuery }),
    response: { 200: RideRequestPage, ...errorResponses(400, 401, 403) },
  },
  posts: {
    tags,
    summary: 'All posts, newest first',
    querystring: PageQuery,
    response: { 200: Paginated(CommunityPost), ...errorResponses(400, 401, 403) },
  },
  removePost: {
    tags,
    summary: 'Remove a post and its comments',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  groups: {
    tags,
    summary: 'All groups, newest first',
    querystring: PageQuery,
    response: { 200: Paginated(Group), ...errorResponses(400, 401, 403) },
  },
  removeGroup: {
    tags,
    summary: 'Remove a group and its chat',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  places: {
    tags,
    summary: 'All shared places, newest first',
    querystring: PageQuery,
    response: { 200: Paginated(Place), ...errorResponses(400, 401, 403) },
  },
  removePlace: {
    tags,
    summary: 'Remove a place and its reviews',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  banners: {
    tags,
    summary: 'All banners (including inactive)',
    response: { 200: Type.Object({ items: Type.Array(Banner) }), ...errorResponses(401, 403) },
  },
  createBanner: {
    tags,
    summary: 'Create a home banner',
    body: CreateBannerBody,
    response: { 201: Banner, ...errorResponses(400, 401, 403) },
  },
  updateBanner: {
    tags,
    summary: 'Edit a home banner',
    params: IdParams,
    body: UpdateBannerBody,
    response: { 200: Banner, ...errorResponses(400, 401, 403, 404) },
  },
  deleteBanner: {
    tags,
    summary: 'Delete a home banner',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  auditLog: {
    tags,
    summary: 'Moderation log, newest first',
    querystring: PageQuery,
    response: { 200: Paginated(AuditEntry), ...errorResponses(400, 401, 403) },
  },
  analytics: {
    tags,
    summary: 'Activity over time, active users and breakdowns',
    querystring: Type.Object({
      days: Type.Optional(
        Type.Integer({ minimum: 7, maximum: 365, default: 30, description: 'Window length (7–365).' }),
      ),
    }),
    response: { 200: Analytics, ...errorResponses(400, 401, 403) },
  },
  topUsers: {
    tags,
    summary: 'Leaderboard of the most active riders',
    querystring: Type.Object({
      metric: Type.Optional(TopUserMetricSchema),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 100, default: 10 })),
    }),
    response: {
      200: Type.Object({ metric: TopUserMetricSchema, items: Type.Array(TopUser) }),
      ...errorResponses(400, 401, 403),
    },
  },
  feedback: {
    tags,
    summary: 'Feedback from riders, newest first',
    querystring: Type.Object({
      status: Type.Optional(FeedbackStatusSchema),
      category: Type.Optional(FeedbackCategorySchema),
      ...paginationQuery,
    }),
    response: { 200: Paginated(AdminFeedback), ...errorResponses(400, 401, 403) },
  },
  updateFeedback: {
    tags,
    summary: 'Change a feedback item’s status or internal note',
    params: IdParams,
    body: UpdateFeedbackBody,
    response: { 200: AdminFeedback, ...errorResponses(400, 401, 403, 404) },
  },
  removeFeedback: {
    tags,
    summary: 'Delete a feedback item (spam or tests)',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
};
