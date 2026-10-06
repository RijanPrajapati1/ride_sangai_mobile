export type UserRole = 'user' | 'superadmin';

/** The signed-in account (mirrors the API's `AuthUser`). */
export interface AuthUser {
  id: string;
  name: string;
  email: string;
  avatarUrl: string;
  role: UserRole;
  isSuperadmin: boolean;
}
