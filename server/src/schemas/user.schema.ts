import { Type } from 'typebox';
import { paginationQuery } from '../utils/pagination.js';
import {
  ActivityCategorySchema,
  ExperienceLevelSchema,
  IdParams,
  NoContent,
  Paginated,
  errorResponses,
  RideTypeSchema,
  Text,
  Timestamp,
  Uuid,
} from './common.schema.js';

/** Mirrors the Dart `UserProfile` entity, plus privacy flags. */
export const UserProfile = Type.Object({
  id: Uuid,
  name: Type.String(),
  email: Type.Union([Type.String(), Type.Null()], { description: 'Only returned to the owner and admins.' }),
  avatarUrl: Type.String({ description: "'' when unset (the app shows initials)." }),
  bio: Type.String(),
  location: Type.String(),
  experienceLevel: ExperienceLevelSchema,
  preferredRideType: RideTypeSchema,
  cyclingInterests: Type.Array(Type.String()),
  totalRides: Type.Integer({ description: 'Rides organized plus rides joined (approved).' }),
  completedRides: Type.Integer({ description: 'Of totalRides, those that have already started.' }),
  followersCount: Type.Integer(),
  followingCount: Type.Integer(),
  isFollowing: Type.Boolean({ description: 'Whether the viewer follows this rider.' }),
  isMe: Type.Boolean(),
  isPrivate: Type.Boolean({
    description: 'publicProfile is off: bio, location, interests and stats are hidden from others.',
  }),
  statsHidden: Type.Boolean({
    description: 'showRidingStats is off: ride stats are reported as 0 to others.',
  }),
});

export const UserProfilePage = Paginated(UserProfile);

export const UpdateProfileBody = Type.Object(
  {
    name: Type.Optional(Text(80)),
    avatarUrl: Type.Optional(Type.String({ maxLength: 2048, description: "Image URL, or '' to clear." })),
    bio: Type.Optional(Type.String({ maxLength: 500 })),
    location: Type.Optional(Type.String({ maxLength: 120 })),
    experienceLevel: Type.Optional(ExperienceLevelSchema),
    preferredRideType: Type.Optional(RideTypeSchema),
    cyclingInterests: Type.Optional(Type.Array(Type.String({ maxLength: 40 }), { maxItems: 20 })),
  },
  { additionalProperties: false, minProperties: 1 },
);

const preferenceFields = {
  pushRideReminders: Type.Boolean(),
  pushMessages: Type.Boolean(),
  pushCommunityActivity: Type.Boolean(),
  darkModeEnabled: Type.Boolean(),
  publicProfile: Type.Boolean(),
  showRidingStats: Type.Boolean(),
};

/** Mirrors the Dart `UserPreferences` entity. */
export const UserPreferences = Type.Object(preferenceFields);
export const ReplacePreferencesBody = Type.Object(preferenceFields, { additionalProperties: false });
export const PatchPreferencesBody = Type.Partial(Type.Object(preferenceFields), {
  additionalProperties: false,
  minProperties: 1,
});

export const DeleteAccountBody = Type.Object(
  { password: Type.String({ minLength: 1, maxLength: 128 }) },
  { additionalProperties: false },
);

export const FollowState = Type.Object({
  isFollowing: Type.Boolean(),
  followersCount: Type.Integer({ description: "The target rider's follower count after the change." }),
});

export const UserSearchQuery = Type.Object({
  q: Type.Optional(Type.String({ maxLength: 80, description: 'Case-insensitive name search.' })),
  ...paginationQuery,
});

export const RecommendedQuery = Type.Object({
  category: Type.Optional(ActivityCategorySchema),
  limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 50, default: 10 })),
});

export const FollowEdge = Type.Object({
  id: Uuid,
  name: Type.String(),
  avatarUrl: Type.String(),
  location: Type.String(),
  isFollowing: Type.Boolean(),
  followedAt: Timestamp,
});
export const FollowEdgePage = Paginated(FollowEdge);

// --- Route schemas -----------------------------------------------------------

const tags = ['Users'];
const PageQuery = Type.Object(paginationQuery);

export const userSchemas = {
  me: { tags, summary: 'My profile', response: { 200: UserProfile, ...errorResponses(401) } },
  updateMe: {
    tags,
    summary: 'Edit my profile',
    description: 'Only these fields are editable; counters, email and stats are server-owned.',
    body: UpdateProfileBody,
    response: { 200: UserProfile, ...errorResponses(400, 401) },
  },
  deleteMe: {
    tags,
    summary: 'Delete my account (requires password)',
    description: 'Permanently removes the account and everything it owns (rides, posts, groups, messages).',
    body: DeleteAccountBody,
    response: { 204: NoContent, ...errorResponses(400, 401) },
  },
  getPreferences: {
    tags,
    summary: 'My settings toggles',
    response: { 200: UserPreferences, ...errorResponses(401) },
  },
  replacePreferences: {
    tags,
    summary: 'Replace all settings toggles',
    body: ReplacePreferencesBody,
    response: { 200: UserPreferences, ...errorResponses(400, 401) },
  },
  patchPreferences: {
    tags,
    summary: 'Change some settings toggles',
    description: 'Prefer this over PUT: two quick toggles cannot overwrite each other.',
    body: PatchPreferencesBody,
    response: { 200: UserPreferences, ...errorResponses(400, 401) },
  },
  search: {
    tags,
    summary: 'Search riders by name',
    querystring: UserSearchQuery,
    response: { 200: UserProfilePage, ...errorResponses(400, 401) },
  },
  recommended: {
    tags,
    summary: 'Riders to follow',
    description:
      'Excludes you, riders you follow, admins and private profiles. Matching category first, then most followed.',
    querystring: RecommendedQuery,
    response: { 200: Type.Object({ items: Type.Array(UserProfile) }), ...errorResponses(401) },
  },
  getById: {
    tags,
    summary: "A rider's profile",
    params: IdParams,
    response: { 200: UserProfile, ...errorResponses(401, 404) },
  },
  follow: {
    tags,
    summary: 'Follow a rider (idempotent)',
    params: IdParams,
    response: { 200: FollowState, ...errorResponses(400, 401, 404) },
  },
  unfollow: {
    tags,
    summary: 'Unfollow a rider (idempotent)',
    params: IdParams,
    response: { 200: FollowState, ...errorResponses(401, 404) },
  },
  followers: {
    tags,
    summary: "A rider's followers",
    params: IdParams,
    querystring: PageQuery,
    response: { 200: FollowEdgePage, ...errorResponses(401, 404) },
  },
  following: {
    tags,
    summary: 'Riders this rider follows',
    params: IdParams,
    querystring: PageQuery,
    response: { 200: FollowEdgePage, ...errorResponses(401, 404) },
  },
};
