import { Type } from 'typebox';
import { ActivityCategorySchema, Nullable, Timestamp, Uuid, errorResponses } from './common.schema.js';
import { Place } from './place.schema.js';
import { CommunityPost } from './post.schema.js';
import { Ride } from './ride.schema.js';
import { UserProfile } from './user.schema.js';

export const Banner = Type.Object({
  id: Uuid,
  category: Nullable(ActivityCategorySchema),
  title: Type.String(),
  subtitle: Type.String(),
  ctaLabel: Type.String(),
  ctaUrl: Nullable(Type.String()),
  imageUrl: Nullable(Type.String()),
  icon: Nullable(Type.String({ description: 'Material icon name hint, e.g. group_add.' })),
  theme: Nullable(Type.String({ description: 'Colour theme hint, e.g. primary.' })),
  sortOrder: Type.Integer(),
  isActive: Type.Boolean(),
  startsAt: Nullable(Timestamp),
  endsAt: Nullable(Timestamp),
});

export const Badges = Type.Object({
  unreadNotifications: Type.Integer(),
  unreadMessages: Type.Integer(),
  pendingRideRequests: Type.Integer({ description: 'Pending join requests on upcoming rides you organize.' }),
});

const Option = Type.Object({ value: Type.String(), label: Type.String() });

export const Meta = Type.Object({
  categories: Type.Array(
    Type.Object({
      value: ActivityCategorySchema,
      label: Type.String(),
      activityNoun: Type.String(),
      activitySingular: Type.String(),
      tagline: Type.String(),
      rideTypes: Type.Array(Option),
    }),
  ),
  difficulties: Type.Array(Option),
  experienceLevels: Type.Array(Option),
  placeCategories: Type.Array(Option),
  notificationTypes: Type.Array(Type.String()),
  limits: Type.Record(Type.String(), Type.Unknown()),
});

export const CategoryQuery = Type.Object({ category: Type.Optional(ActivityCategorySchema) });

const tags = ['Home'];

export const homeSchemas = {
  home: {
    tags,
    summary: 'Everything the Home screen shows, in one request',
    description: 'featuredRide is the soonest upcoming ride in the category, upcomingRides the next six.',
    querystring: Type.Object({
      category: Type.Optional(ActivityCategorySchema),
      lat: Type.Optional(Type.Number({ minimum: -90, maximum: 90 })),
      lng: Type.Optional(Type.Number({ minimum: -180, maximum: 180 })),
    }),
    response: {
      200: Type.Object({
        category: ActivityCategorySchema,
        me: UserProfile,
        featuredRide: Nullable(Ride),
        upcomingRides: Type.Array(Ride),
        communityPreview: Type.Array(CommunityPost),
        recommendedRiders: Type.Array(UserProfile),
        explorePlaces: Type.Array(Place, {
          description: 'Nearby places (if lat/lng sent) or the best rated.',
        }),
        banners: Type.Array(Banner),
        badges: Badges,
      }),
      ...errorResponses(400, 401),
    },
  },
  badges: { tags, summary: 'Header badge counts', response: { 200: Badges, ...errorResponses(401) } },
  banners: {
    tags,
    summary: 'Home carousel banners',
    querystring: CategoryQuery,
    response: { 200: Type.Object({ items: Type.Array(Banner) }), ...errorResponses(401) },
  },
  meta: { tags, summary: 'Enum options and labels (public)', response: { 200: Meta } },
};
