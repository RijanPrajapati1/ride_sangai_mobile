/**
 * Domain enums, spelled exactly like the Dart enum values in
 * mobile/lib/core/enums so the app can parse them with `Enum.values.byName`.
 * The matching enums live in prisma/schema.prisma — keep both in sync.
 */

export const ACTIVITY_CATEGORIES = ['cycling', 'trekking', 'hiking', 'riding'] as const;
export type ActivityCategory = (typeof ACTIVITY_CATEGORIES)[number];

export const RIDE_TYPES = [
  // Cycling
  'road',
  'mountain',
  'gravel',
  'touring',
  'social',
  'hillClimb',
  'nightRide',
  // Trekking
  'multiDayTrek',
  'dayTrek',
  'summitTrek',
  // Hiking
  'dayHike',
  'natureWalk',
  'familyHike',
  // Riding (motorbike)
  'touringRide',
  'offRoadRide',
  'trackDay',
] as const;
export type RideType = (typeof RIDE_TYPES)[number];

/** Which dashboard category each ride type belongs to (mirrors `RideTypeX.category`). */
export const RIDE_TYPE_CATEGORY: Readonly<Record<RideType, ActivityCategory>> = {
  road: 'cycling',
  mountain: 'cycling',
  gravel: 'cycling',
  touring: 'cycling',
  social: 'cycling',
  hillClimb: 'cycling',
  nightRide: 'cycling',
  multiDayTrek: 'trekking',
  dayTrek: 'trekking',
  summitTrek: 'trekking',
  dayHike: 'hiking',
  natureWalk: 'hiking',
  familyHike: 'hiking',
  touringRide: 'riding',
  offRoadRide: 'riding',
  trackDay: 'riding',
};

export const RIDE_DIFFICULTIES = ['easy', 'moderate', 'hard'] as const;
export type RideDifficulty = (typeof RIDE_DIFFICULTIES)[number];

export const EXPERIENCE_LEVELS = ['beginner', 'intermediate', 'advanced', 'pro'] as const;
export type ExperienceLevel = (typeof EXPERIENCE_LEVELS)[number];

export const RIDE_REQUEST_STATUSES = ['pending', 'approved', 'declined'] as const;
export type RideRequestStatus = (typeof RIDE_REQUEST_STATUSES)[number];

/** The viewer's relationship to a ride (derived, never stored). */
export const RIDE_JOIN_STATUSES = ['none', 'pending', 'approved', 'declined', 'organizer'] as const;
export type RideJoinStatus = (typeof RIDE_JOIN_STATUSES)[number];

export const NOTIFICATION_TYPES = [
  'requestApproved',
  'requestDeclined',
  'newMessage',
  'rideReminder',
  'rideUpdated',
  'newFollower',
  'comment',
  'like',
  /** Sent to an organizer when someone asks to join their ride (new; not in the app's enum yet). */
  'newRideRequest',
  /** Sent to a place's author when someone reviews it (new; not in the app's enum yet). */
  'placeReview',
  /** Sent to every rider from the superadmin dashboard. */
  'announcement',
] as const;
export type NotificationType = (typeof NOTIFICATION_TYPES)[number];

export const USER_ROLES = ['user', 'superadmin'] as const;
export type UserRole = (typeof USER_ROLES)[number];

export const GROUP_MEMBER_ROLES = ['owner', 'member'] as const;
export type GroupMemberRole = (typeof GROUP_MEMBER_ROLES)[number];

export function rideTypesFor(category: ActivityCategory): RideType[] {
  return RIDE_TYPES.filter((type) => RIDE_TYPE_CATEGORY[type] === category);
}

/** What a notification points at, so the app can navigate when it is tapped. */
export const NOTIFICATION_ENTITY_TYPES = [
  'ride',
  'rideRequest',
  'post',
  'comment',
  'user',
  'conversation',
  'group',
  'place',
] as const;
export type NotificationEntityType = (typeof NOTIFICATION_ENTITY_TYPES)[number];

/** Kinds of places riders share in Explore. */
export const PLACE_CATEGORIES = [
  'viewpoint',
  'waterfall',
  'lake',
  'river',
  'trail',
  'heritage',
  'temple',
  'cafe',
  'food',
  'campsite',
  'village',
  'cave',
  'other',
] as const;
export type PlaceCategory = (typeof PLACE_CATEGORIES)[number];

export const FEEDBACK_CATEGORIES = ['bug', 'idea', 'praise', 'other'] as const;
export type FeedbackCategory = (typeof FEEDBACK_CATEGORIES)[number];

export const FEEDBACK_STATUSES = ['open', 'inProgress', 'resolved'] as const;
export type FeedbackStatus = (typeof FEEDBACK_STATUSES)[number];

/** Ways to rank riders on the superadmin leaderboard. */
export const TOP_USER_METRICS = [
  'followers',
  'ridesOrganized',
  'ridesJoined',
  'posts',
  'likesReceived',
  'places',
] as const;
export type TopUserMetric = (typeof TOP_USER_METRICS)[number];
