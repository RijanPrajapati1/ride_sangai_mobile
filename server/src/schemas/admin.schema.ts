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
import { Email, NewPassword } from './auth.schema.js';
import { CommunityPost, UpdatePostBody } from './post.schema.js';
import { Group, UpdateGroupBody } from './group.schema.js';
import { Place, UpdatePlaceBody } from './place.schema.js';
import {
  DeclineBody,
  Ride,
  RideListQuery,
  RideRequest,
  RideRequestPage,
  UpdateRideBody,
} from './ride.schema.js';
import { UpdateProfileBody, UserProfile } from './user.schema.js';

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
  disabledUsers: Type.Integer({ description: 'Accounts a superadmin has disabled.' }),
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
  // Set while the account is disabled.
  disabledAt: Nullable(Timestamp),
  disabledReason: Nullable(Type.String()),
});

export const AdminUserDetail = Type.Object({
  ...AdminUser.properties,
  activity: Type.Object({
    ridesOrganized: Type.Integer(),
    ridesJoined: Type.Integer(),
    pendingRequests: Type.Integer(),
    posts: Type.Integer(),
    comments: Type.Integer(),
    places: Type.Integer(),
    reviews: Type.Integer(),
    groupsOwned: Type.Integer(),
    groupsJoined: Type.Integer(),
    activeSessions: Type.Integer(),
  }),
  sessions: Type.Array(
    Type.Object({
      id: Uuid,
      userAgent: Nullable(Type.String()),
      ip: Nullable(Type.String()),
      createdAt: Timestamp,
      lastUsedAt: Timestamp,
      expiresAt: Timestamp,
    }),
    { description: 'Devices currently signed in.' },
  ),
});

export const AdminUpdateUserBody = Type.Object(
  { ...UpdateProfileBody.properties, email: Type.Optional(Email) },
  { additionalProperties: false, minProperties: 1 },
);

const MiniUser = Type.Object({
  id: Uuid,
  name: Type.String(),
  email: Type.String(),
  avatarUrl: Type.String(),
});

export const AdminComment = Type.Object({
  id: Uuid,
  text: Type.String(),
  likeCount: Type.Integer(),
  createdAt: Timestamp,
  author: MiniUser,
  post: Type.Object({ id: Uuid, text: Type.String({ description: 'First 160 characters.' }) }),
});

export const AdminReview = Type.Object({
  id: Uuid,
  rating: Type.Integer(),
  worthIt: Type.Boolean(),
  text: Type.String(),
  photos: Type.Array(Type.String()),
  createdAt: Timestamp,
  author: MiniUser,
  place: Type.Object({ id: Uuid, name: Type.String() }),
});

export const AnnouncementBody = Type.Object(
  { title: Text(80), message: Text(500) },
  { additionalProperties: false },
);

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
      status: Type.Optional(Type.Enum(['active', 'disabled'], { description: 'Omit for everyone.' })),
      ...paginationQuery,
    }),
    response: { 200: Paginated(AdminUser), ...errorResponses(400, 401, 403) },
  },
  user: {
    tags,
    summary: 'One user: profile, status, activity and signed-in devices',
    params: IdParams,
    response: { 200: AdminUserDetail, ...errorResponses(401, 403, 404) },
  },
  updateUser: {
    tags,
    summary: 'Edit any profile, including the sign-in email',
    params: IdParams,
    body: AdminUpdateUserBody,
    response: { 200: AdminUserDetail, ...errorResponses(400, 401, 403, 404, 409) },
  },
  disableUser: {
    tags,
    summary: 'Disable an account (signs it out everywhere; it cannot sign in until enabled)',
    params: IdParams,
    body: Type.Object(
      { reason: Type.Optional(Nullable(Type.String({ maxLength: 300, description: 'Internal note.' }))) },
      { additionalProperties: false },
    ),
    response: { 200: AdminUserDetail, ...errorResponses(400, 401, 403, 404, 409) },
  },
  enableUser: {
    tags,
    summary: 'Re-enable a disabled account',
    params: IdParams,
    response: { 200: AdminUserDetail, ...errorResponses(401, 403, 404, 409) },
  },
  signOutUser: {
    tags,
    summary: 'Sign a user out on every device',
    params: IdParams,
    response: { 200: AdminUserDetail, ...errorResponses(401, 403, 404, 409) },
  },
  setPassword: {
    tags,
    summary: 'Set a new password for a user (signs them out everywhere)',
    params: IdParams,
    body: Type.Object({ password: NewPassword }, { additionalProperties: false }),
    response: { 204: NoContent, ...errorResponses(400, 401, 403, 404, 409) },
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
  editRide: {
    tags,
    summary: 'Edit any ride (participants are notified of changes)',
    params: IdParams,
    body: UpdateRideBody,
    response: { 200: Ride, ...errorResponses(400, 401, 403, 404, 409, 422) },
  },
  approveRequest: {
    tags,
    summary: 'Approve a join request on any ride',
    params: IdParams,
    response: { 200: RideRequest, ...errorResponses(401, 403, 404, 409) },
  },
  declineRequest: {
    tags,
    summary: 'Decline a join request on any ride',
    params: IdParams,
    body: DeclineBody,
    response: { 200: RideRequest, ...errorResponses(400, 401, 403, 404, 409) },
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
  editPost: {
    tags,
    summary: 'Edit any post',
    params: IdParams,
    body: UpdatePostBody,
    response: { 200: CommunityPost, ...errorResponses(400, 401, 403, 404) },
  },
  comments: {
    tags,
    summary: 'All comments, newest first',
    querystring: Type.Object({
      q: Type.Optional(Type.String({ maxLength: 80, description: 'Text contains.' })),
      postId: Type.Optional(Uuid),
      ...paginationQuery,
    }),
    response: { 200: Paginated(AdminComment), ...errorResponses(400, 401, 403) },
  },
  removeComment: {
    tags,
    summary: 'Remove any comment',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
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
  editGroup: {
    tags,
    summary: 'Edit any group',
    params: IdParams,
    body: UpdateGroupBody,
    response: { 200: Group, ...errorResponses(400, 401, 403, 404) },
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
  editPlace: {
    tags,
    summary: 'Edit any shared place',
    params: IdParams,
    body: UpdatePlaceBody,
    response: { 200: Place, ...errorResponses(400, 401, 403, 404) },
  },
  reviews: {
    tags,
    summary: 'All place reviews, newest first',
    querystring: Type.Object({
      q: Type.Optional(Type.String({ maxLength: 80, description: 'Text contains.' })),
      placeId: Type.Optional(Uuid),
      ...paginationQuery,
    }),
    response: { 200: Paginated(AdminReview), ...errorResponses(400, 401, 403) },
  },
  removeReview: {
    tags,
    summary: 'Remove any place review (the place rating updates)',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
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
  announce: {
    tags,
    summary: 'Send an announcement to every active rider',
    description: 'Each rider gets an in-app notification (and a push, when push is configured).',
    body: AnnouncementBody,
    response: { 201: Type.Object({ recipients: Type.Integer() }), ...errorResponses(400, 401, 403) },
  },
  announcements: {
    tags,
    summary: 'Announcements sent so far, newest first',
    querystring: PageQuery,
    response: { 200: Paginated(AuditEntry), ...errorResponses(400, 401, 403) },
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
