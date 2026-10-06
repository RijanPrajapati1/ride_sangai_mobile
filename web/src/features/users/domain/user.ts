export type UserRole = 'user' | 'superadmin';

/** A rider as the superadmin sees them (`GET /superadmin/users`). */
export interface ManagedUser {
  id: string;
  name: string;
  email: string | null;
  avatarUrl: string;
  bio: string;
  location: string;
  experienceLevel: string;
  totalRides: number;
  completedRides: number;
  followersCount: number;
  followingCount: number;
  isMe: boolean;
  role: UserRole;
  createdAt: string;
  lastLoginAt: string | null;
}

export interface UserFilters {
  q: string;
  role: UserRole;
}
