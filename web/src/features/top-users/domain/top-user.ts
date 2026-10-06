export const TOP_USER_METRICS = [
  'followers',
  'ridesOrganized',
  'ridesJoined',
  'posts',
  'likesReceived',
  'places',
] as const;
export type TopUserMetric = (typeof TOP_USER_METRICS)[number];

export const METRIC_LABELS: Record<TopUserMetric, string> = {
  followers: 'Followers',
  ridesOrganized: 'Rides organized',
  ridesJoined: 'Rides joined',
  posts: 'Posts',
  likesReceived: 'Likes received',
  places: 'Places shared',
};

/** A leaderboard row (`GET /superadmin/top-users`). */
export interface TopUser {
  rank: number;
  id: string;
  name: string;
  email: string;
  avatarUrl: string;
  joinedAt: string;
  followers: number;
  ridesOrganized: number;
  ridesJoined: number;
  posts: number;
  likesReceived: number;
  places: number;
}
