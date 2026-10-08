export type UserRole = 'user' | 'superadmin';
export type UserStatus = 'all' | 'active' | 'disabled';

export const EXPERIENCE_LEVELS = ['beginner', 'intermediate', 'advanced', 'pro'] as const;
export type ExperienceLevel = (typeof EXPERIENCE_LEVELS)[number];

/** Preferred ride types the app offers, grouped by activity. */
export const RIDE_TYPES = {
  cycling: ['road', 'mountain', 'gravel', 'touring', 'social', 'hillClimb', 'nightRide'],
  trekking: ['multiDayTrek', 'dayTrek', 'summitTrek'],
  hiking: ['dayHike', 'natureWalk', 'familyHike'],
  riding: ['touringRide', 'offRoadRide', 'trackDay'],
} as const;

/** A rider as the superadmin sees them (`GET /superadmin/users`). */
export interface ManagedUser {
  id: string;
  name: string;
  email: string | null;
  avatarUrl: string;
  bio: string;
  location: string;
  experienceLevel: string;
  preferredRideType: string;
  cyclingInterests: string[];
  totalRides: number;
  completedRides: number;
  followersCount: number;
  followingCount: number;
  isMe: boolean;
  isPrivate: boolean;
  role: UserRole;
  createdAt: string;
  lastLoginAt: string | null;
  /** Set while the account is disabled. */
  disabledAt: string | null;
  disabledReason: string | null;
}

export interface UserSession {
  id: string;
  userAgent: string | null;
  ip: string | null;
  createdAt: string;
  lastUsedAt: string;
  expiresAt: string;
}

/** One user in full (`GET /superadmin/users/:id`). */
export interface UserDetail extends ManagedUser {
  activity: {
    ridesOrganized: number;
    ridesJoined: number;
    pendingRequests: number;
    posts: number;
    comments: number;
    places: number;
    reviews: number;
    groupsOwned: number;
    groupsJoined: number;
    activeSessions: number;
  };
  sessions: UserSession[];
}

/** Fields a superadmin may change on anyone's account. */
export interface UserUpdate {
  name?: string;
  email?: string;
  bio?: string;
  location?: string;
  avatarUrl?: string;
  experienceLevel?: ExperienceLevel;
  preferredRideType?: string;
  cyclingInterests?: string[];
}

export interface UserFilters {
  q: string;
  role: UserRole;
  status: UserStatus;
}
