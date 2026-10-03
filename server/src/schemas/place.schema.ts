import { Type } from 'typebox';
import { PLACE_CATEGORIES } from '../constants/enums.js';
import { paginationQuery } from '../utils/pagination.js';
import {
  ActivityCategorySchema,
  IdParams,
  NoContent,
  Nullable,
  Paginated,
  Text,
  Timestamp,
  Uuid,
  errorResponses,
} from './common.schema.js';

export const PlaceCategorySchema = Type.Enum(PLACE_CATEGORIES);

const Latitude = Type.Number({ minimum: -90, maximum: 90 });
const Longitude = Type.Number({ minimum: -180, maximum: 180 });

export const Place = Type.Object({
  id: Uuid,
  name: Type.String(),
  description: Type.String(),
  category: PlaceCategorySchema,
  latitude: Type.Number(),
  longitude: Type.Number(),
  locationName: Type.String({ description: 'Human-readable place, e.g. "Near Nagarkot, Bhaktapur".' }),
  photos: Type.Array(Type.String()),
  coverImageUrl: Nullable(Type.String({ description: 'The first photo, or null.' })),
  activities: Type.Array(ActivityCategorySchema, { description: 'Dashboards the place suits.' }),
  bestTime: Nullable(Type.String()),
  tips: Nullable(Type.String()),
  entryFee: Nullable(Type.String()),
  averageRating: Nullable(Type.Number({ description: '1–5, one decimal; null until reviewed.' })),
  reviewCount: Type.Integer(),
  worthItPercent: Nullable(Type.Integer({ description: 'Share of reviewers who said it was worth it.' })),
  saveCount: Type.Integer(),
  distanceKm: Nullable(Type.Number({ description: 'From the location you sent (lat/lng), else null.' })),
  authorId: Uuid,
  authorName: Type.String(),
  authorAvatarUrl: Type.String(),
  isMine: Type.Boolean(),
  isSaved: Type.Boolean(),
  myReview: Nullable(Type.Object({ id: Uuid, rating: Type.Integer(), worthIt: Type.Boolean() })),
  createdAt: Timestamp,
});

export const PlaceReview = Type.Object({
  id: Uuid,
  placeId: Uuid,
  userId: Uuid,
  userName: Type.String(),
  userAvatarUrl: Type.String(),
  rating: Type.Integer({ minimum: 1, maximum: 5 }),
  worthIt: Type.Boolean(),
  text: Type.String(),
  visitedOn: Nullable(Type.String({ format: 'date' })),
  photos: Type.Array(Type.String()),
  createdAt: Timestamp,
  updatedAt: Timestamp,
  isMine: Type.Boolean(),
});

const photoList = (max: number) => Type.Array(Type.String({ maxLength: 2048 }), { maxItems: max });
const optionalText = (max: number) => Nullable(Type.String({ maxLength: max }));

const placeFields = {
  name: Text(120),
  description: Text(3000),
  category: PlaceCategorySchema,
  latitude: Latitude,
  longitude: Longitude,
  locationName: Text(200),
  photos: photoList(10),
  activities: Type.Array(ActivityCategorySchema, { maxItems: 4 }),
  bestTime: optionalText(200),
  tips: optionalText(2000),
  entryFee: optionalText(120),
};

export const CreatePlaceBody = Type.Object(
  {
    ...placeFields,
    photos: Type.Optional(placeFields.photos),
    activities: Type.Optional(placeFields.activities),
    bestTime: Type.Optional(placeFields.bestTime),
    tips: Type.Optional(placeFields.tips),
    entryFee: Type.Optional(placeFields.entryFee),
  },
  { additionalProperties: false },
);
export const UpdatePlaceBody = Type.Partial(Type.Object(placeFields), { additionalProperties: false, minProperties: 1 });

export const ReviewBody = Type.Object(
  {
    rating: Type.Integer({ minimum: 1, maximum: 5 }),
    worthIt: Type.Boolean({ description: 'Was it worth going?' }),
    text: Type.Optional(Type.String({ maxLength: 2000 })),
    visitedOn: Type.Optional(Nullable(Type.String({ format: 'date' }))),
    photos: Type.Optional(photoList(5)),
  },
  { additionalProperties: false },
);

const filters = {
  category: Type.Optional(PlaceCategorySchema),
  activity: Type.Optional(ActivityCategorySchema),
  minRating: Type.Optional(Type.Number({ minimum: 1, maximum: 5 })),
  q: Type.Optional(Type.String({ maxLength: 100, description: 'Matches name or location.' })),
};

export const NearbyQuery = Type.Object({
  lat: Latitude,
  lng: Longitude,
  radiusKm: Type.Optional(Type.Number({ exclusiveMinimum: 0, maximum: 300, default: 25 })),
  ...filters,
  ...paginationQuery,
});

export const PlaceListQuery = Type.Object({
  sort: Type.Optional(Type.Enum(['top', 'newest'], { default: 'top' })),
  lat: Type.Optional(Latitude),
  lng: Type.Optional(Longitude),
  ...filters,
  ...paginationQuery,
});

export const LocationQuery = Type.Object({ lat: Type.Optional(Latitude), lng: Type.Optional(Longitude) });

export const SaveState = Type.Object({ isSaved: Type.Boolean(), saveCount: Type.Integer() });

const tags = ['Explore'];

export const placeSchemas = {
  nearby: {
    tags,
    summary: 'Places near a location, nearest first',
    description: 'Send the device location as lat/lng. Each item carries distanceKm.',
    querystring: NearbyQuery,
    response: { 200: Paginated(Place), ...errorResponses(400, 401) },
  },
  list: {
    tags,
    summary: 'Browse places (best rated or newest)',
    description: 'Pass lat/lng to get distanceKm on each item.',
    querystring: PlaceListQuery,
    response: { 200: Paginated(Place), ...errorResponses(400, 401) },
  },
  create: { tags, summary: 'Share a place', body: CreatePlaceBody, response: { 201: Place, ...errorResponses(400, 401) } },
  get: { tags, summary: 'A place', params: IdParams, querystring: LocationQuery, response: { 200: Place, ...errorResponses(401, 404) } },
  update: {
    tags,
    summary: 'Edit a place (its author or an admin)',
    params: IdParams,
    body: UpdatePlaceBody,
    response: { 200: Place, ...errorResponses(400, 401, 403, 404) },
  },
  remove: { tags, summary: 'Delete a place (its author or an admin)', params: IdParams, response: { 204: NoContent, ...errorResponses(401, 403, 404) } },
  save: { tags, summary: 'Save to "want to go" (idempotent)', params: IdParams, response: { 200: SaveState, ...errorResponses(401, 404) } },
  unsave: { tags, summary: 'Remove from "want to go" (idempotent)', params: IdParams, response: { 200: SaveState, ...errorResponses(401, 404) } },
  saved: {
    tags,
    summary: 'My saved places, most recently saved first',
    querystring: Type.Object({ ...LocationQuery.properties, ...paginationQuery }),
    response: { 200: Paginated(Place), ...errorResponses(400, 401) },
  },
  byAuthor: {
    tags,
    summary: 'Places a rider has shared, newest first',
    params: IdParams,
    querystring: Type.Object({ ...LocationQuery.properties, ...paginationQuery }),
    response: { 200: Paginated(Place), ...errorResponses(400, 401) },
  },
  reviews: {
    tags,
    summary: "A place's reviews, newest first",
    params: IdParams,
    querystring: Type.Object(paginationQuery),
    response: { 200: Paginated(PlaceReview), ...errorResponses(400, 401, 404) },
  },
  review: {
    tags,
    summary: 'Write or update my review',
    description: 'One review per rider per place: 201 when created, 200 when updated. Authors cannot review their own place.',
    params: IdParams,
    body: ReviewBody,
    response: { 200: PlaceReview, 201: PlaceReview, ...errorResponses(400, 401, 404, 409) },
  },
  removeReview: { tags, summary: 'Delete my review', params: IdParams, response: { 204: NoContent, ...errorResponses(401, 404) } },
};
