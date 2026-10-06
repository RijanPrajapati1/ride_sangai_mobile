import { apiRequest, bffRequest } from '@/core/http/api-client';
import type { AuthUser } from '../domain/auth-user';

export const authRepository = {
  /** Signs in through the BFF, which sets the httpOnly session cookies. */
  login: (email: string, password: string) =>
    bffRequest<{ user: AuthUser }>('/api/auth/login', { method: 'POST', body: { email, password } }),

  logout: () => bffRequest<void>('/api/auth/logout', { method: 'POST' }),

  me: () => apiRequest<AuthUser>('auth/me'),
};
