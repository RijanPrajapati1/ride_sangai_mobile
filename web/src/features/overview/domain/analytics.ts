export const ACTIVITY_SERIES = [
  'signups',
  'rides',
  'joinRequests',
  'posts',
  'comments',
  'messages',
  'places',
  'feedback',
] as const;
export type ActivitySeries = (typeof ACTIVITY_SERIES)[number];

export const ACTIVITY_LABELS: Record<ActivitySeries, string> = {
  signups: 'Signups',
  rides: 'Rides',
  joinRequests: 'Join requests',
  posts: 'Posts',
  comments: 'Comments',
  messages: 'Messages',
  places: 'Places',
  feedback: 'Feedback',
};

export const ANALYTICS_WINDOWS = [7, 30, 90, 365] as const;
export type AnalyticsWindow = (typeof ANALYTICS_WINDOWS)[number];

export type Breakdown = { key: string; count: number }[];

export type DailyActivity = { date: string } & Record<ActivitySeries, number>;

/** `GET /superadmin/analytics?days=` */
export interface Analytics {
  days: number;
  totals: Record<ActivitySeries, number>;
  daily: DailyActivity[];
  activeUsers: { last24Hours: number; last7Days: number; last30Days: number };
  ridesByCategory: Breakdown;
  ridesByDifficulty: Breakdown;
  requestsByStatus: Breakdown;
  placesByCategory: Breakdown;
  feedbackByStatus: Breakdown;
  feedbackAverageRating: number | null;
  feedbackRatings: number;
}
