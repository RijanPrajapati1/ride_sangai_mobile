import { Type } from 'typebox';
import { paginationQuery } from '../utils/pagination.js';
import {
  ActivityCategorySchema,
  DateTimeInput,
  ExperienceLevelSchema,
  IdParams,
  NoContent,
  Nullable,
  Paginated,
  RideDifficultySchema,
  RideJoinStatusSchema,
  RideRequestStatusSchema,
  RideTypeSchema,
  Text,
  Timestamp,
  Uuid,
  errorResponses,
} from './common.schema.js';

export const MyRideRequest = Type.Object({
  id: Uuid,
  status: RideRequestStatusSchema,
  declineReason: Nullable(Type.String()),
  requestedAt: Timestamp,
});

/** Mirrors the Dart `Ride` entity (plus category, isFull and the viewer's own request). */
export const Ride = Type.Object({
  id: Uuid,
  title: Type.String(),
  description: Type.String(),
  date: Timestamp,
  meetingPoint: Type.String(),
  rideType: RideTypeSchema,
  category: ActivityCategorySchema,
  difficulty: RideDifficultySchema,
  distanceKm: Type.Number(),
  durationMinutes: Type.Integer(),
  organizerId: Uuid,
  organizerName: Type.String(),
  organizerAvatarUrl: Type.String(),
  imageUrl: Type.String({ description: "'' when no cover image (the app shows a gradient)." }),
  participantCount: Type.Integer({ description: 'Includes the organizer.' }),
  maxParticipants: Type.Integer(),
  isFull: Type.Boolean(),
  requirements: Type.Array(Type.String()),
  participantAvatars: Type.Array(Type.String(), { description: 'Avatars of the first 5 approved riders.' }),
  joinStatus: RideJoinStatusSchema,
  myRequest: Nullable(MyRideRequest),
  createdAt: Timestamp,
});
export const RidePage = Paginated(Ride);

/** Mirrors the Dart `RideRequest` entity. */
export const RideRequest = Type.Object({
  id: Uuid,
  rideId: Uuid,
  rideTitle: Type.String(),
  rideDate: Timestamp,
  userId: Uuid,
  userName: Type.String(),
  userAvatarUrl: Type.String(),
  userBio: Type.String({ description: "The rider's note with the request, or their profile bio." }),
  message: Nullable(Type.String()),
  experienceLevel: ExperienceLevelSchema,
  requestedAt: Timestamp,
  status: RideRequestStatusSchema,
  declineReason: Nullable(Type.String()),
  decidedAt: Nullable(Timestamp),
});
export const RideRequestPage = Paginated(RideRequest);

/** Mirrors the Dart `RideParticipant` entity. */
export const RideParticipant = Type.Object({
  id: Uuid,
  rideId: Uuid,
  userId: Uuid,
  name: Type.String(),
  avatarUrl: Type.String(),
  joinedAt: Timestamp,
});
export const RideParticipantPage = Paginated(RideParticipant);

const rideFields = {
  title: Text(120),
  description: Text(5000),
  date: DateTimeInput,
  meetingPoint: Text(200),
  rideType: RideTypeSchema,
  difficulty: RideDifficultySchema,
  distanceKm: Type.Number({ exclusiveMinimum: 0, maximum: 10_000 }),
  durationMinutes: Type.Integer({ minimum: 1, maximum: 43_200, description: 'Up to 30 days.' }),
  maxParticipants: Type.Integer({ minimum: 2, maximum: 1000, description: 'Includes the organizer.' }),
  requirements: Type.Array(Type.String({ maxLength: 80 }), { maxItems: 20 }),
  imageUrl: Type.String({ maxLength: 2048 }),
};

export const CreateRideBody = Type.Object(
  {
    ...rideFields,
    requirements: Type.Optional(rideFields.requirements),
    imageUrl: Type.Optional(Nullable(rideFields.imageUrl)),
  },
  { additionalProperties: false },
);

export const UpdateRideBody = Type.Partial(Type.Object(rideFields), {
  additionalProperties: false,
  minProperties: 1,
});

export const RideListQuery = Type.Object({
  category: Type.Optional(ActivityCategorySchema),
  rideType: Type.Optional(RideTypeSchema),
  difficulty: Type.Optional(RideDifficultySchema),
  q: Type.Optional(Type.String({ maxLength: 100, description: 'Matches title or meeting point.' })),
  from: Type.Optional(DateTimeInput),
  to: Type.Optional(DateTimeInput),
  ...paginationQuery,
});

export const MyRidesQuery = Type.Object({
  scope: Type.Optional(
    Type.Enum(['upcoming', 'organized', 'joined', 'past'], {
      default: 'upcoming',
      description:
        'upcoming: future rides you organize or joined/requested · organized: all rides you organize (oldest first) · ' +
        'joined: future rides you requested or joined · past: started rides you organized or joined (newest first)',
    }),
  ),
  category: Type.Optional(ActivityCategorySchema),
  ...paginationQuery,
});

export const RequestListQuery = Type.Object({
  status: Type.Optional(RideRequestStatusSchema),
  ...paginationQuery,
});

export const JoinBody = Type.Object(
  { message: Type.Optional(Type.String({ maxLength: 500, description: 'Optional note to the organizer.' })) },
  { additionalProperties: false },
);

export const DeclineBody = Type.Object(
  { reason: Type.Optional(Nullable(Type.String({ maxLength: 500, description: 'Shared with the rider.' }))) },
  { additionalProperties: false },
);

// --- Route schemas -----------------------------------------------------------

const tags = ['Rides'];
const requestTags = ['Ride requests'];
const PageQuery = Type.Object(paginationQuery);

export const rideSchemas = {
  discover: {
    tags,
    summary: 'Upcoming rides (discovery)',
    description:
      'Rides that have not started yet, soonest first. Filter by dashboard category, type, difficulty, text or dates.',
    querystring: RideListQuery,
    response: { 200: RidePage, ...errorResponses(400, 401) },
  },
  create: {
    tags,
    summary: 'Organize a ride',
    description: 'The caller becomes the organizer and counts as the first participant.',
    body: CreateRideBody,
    response: { 201: Ride, ...errorResponses(400, 401, 422) },
  },
  get: {
    tags,
    summary: 'Ride details',
    params: IdParams,
    response: { 200: Ride, ...errorResponses(401, 404) },
  },
  update: {
    tags,
    summary: 'Edit a ride (organizer or admin)',
    description:
      'Approved riders and pending requesters get a rideUpdated notification describing what changed.',
    params: IdParams,
    body: UpdateRideBody,
    response: { 200: Ride, ...errorResponses(400, 401, 403, 404, 409, 422) },
  },
  remove: {
    tags,
    summary: 'Cancel a ride (organizer or admin)',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 403, 404) },
  },
  participants: {
    tags,
    summary: 'Approved riders',
    params: IdParams,
    querystring: PageQuery,
    response: { 200: RideParticipantPage, ...errorResponses(401, 404) },
  },
  join: {
    tags,
    summary: 'Ask to join a ride',
    description: 'Creates a pending request (a declined rider may ask again). The organizer is notified.',
    params: IdParams,
    body: JoinBody,
    response: { 201: RideRequest, ...errorResponses(401, 404, 409) },
  },
  leave: {
    tags,
    summary: 'Withdraw a request or leave a ride',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 404, 409) },
  },
  rideRequests: {
    tags: requestTags,
    summary: "A ride's join requests (organizer or admin)",
    params: IdParams,
    querystring: RequestListQuery,
    response: { 200: RideRequestPage, ...errorResponses(401, 403, 404) },
  },
  myRides: {
    tags,
    summary: 'My rides (tabs of the My Rides screen)',
    querystring: MyRidesQuery,
    response: { 200: RidePage, ...errorResponses(400, 401) },
  },
  inbox: {
    tags: requestTags,
    summary: 'Join requests across all rides I organize',
    querystring: RequestListQuery,
    response: { 200: RideRequestPage, ...errorResponses(401) },
  },
  byOrganizer: {
    tags,
    summary: 'Rides a rider organizes (all dates, oldest first)',
    params: IdParams,
    querystring: PageQuery,
    response: { 200: RidePage, ...errorResponses(401, 404) },
  },
  approve: {
    tags: requestTags,
    summary: 'Approve a pending request (organizer or admin)',
    params: IdParams,
    response: { 200: RideRequest, ...errorResponses(401, 403, 404, 409) },
  },
  decline: {
    tags: requestTags,
    summary: 'Decline a pending request, optionally with a reason shared with the rider',
    params: IdParams,
    body: DeclineBody,
    response: { 200: RideRequest, ...errorResponses(400, 401, 403, 404, 409) },
  },
};
