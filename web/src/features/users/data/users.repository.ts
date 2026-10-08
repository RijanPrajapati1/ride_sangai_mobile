import { apiRequest } from '@/core/http/api-client';
import type { Page } from '@/core/http/page';
import type { ManagedUser, UserDetail, UserFilters, UserRole, UserUpdate } from '../domain/user';

export const usersRepository = {
  list: (filters: UserFilters, cursor: string | null) =>
    apiRequest<Page<ManagedUser>>('superadmin/users', {
      query: {
        q: filters.q.trim() || undefined,
        role: filters.role,
        status: filters.status === 'all' ? undefined : filters.status,
        cursor,
        limit: 25,
      },
    }),
  get: (id: string) => apiRequest<UserDetail>(`superadmin/users/${id}`),
  update: (id: string, input: UserUpdate) =>
    apiRequest<UserDetail>(`superadmin/users/${id}`, { method: 'PATCH', body: input }),
  disable: (id: string, reason: string | null) =>
    apiRequest<UserDetail>(`superadmin/users/${id}/disable`, { method: 'POST', body: { reason } }),
  enable: (id: string) => apiRequest<UserDetail>(`superadmin/users/${id}/enable`, { method: 'POST' }),
  signOut: (id: string) => apiRequest<UserDetail>(`superadmin/users/${id}/sign-out`, { method: 'POST' }),
  setPassword: (id: string, password: string) =>
    apiRequest<void>(`superadmin/users/${id}/password`, { method: 'PUT', body: { password } }),
  setRole: (id: string, role: UserRole) =>
    apiRequest<unknown>(`superadmin/users/${id}/role`, { method: 'PATCH', body: { role } }),
  remove: (id: string) => apiRequest<void>(`superadmin/users/${id}`, { method: 'DELETE' }),
};
