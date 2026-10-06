import { apiRequest } from '@/core/http/api-client';
import type { Page } from '@/core/http/page';
import type { ManagedUser, UserFilters, UserRole } from '../domain/user';

export const usersRepository = {
  list: (filters: UserFilters, cursor: string | null) =>
    apiRequest<Page<ManagedUser>>('superadmin/users', {
      query: { q: filters.q.trim() || undefined, role: filters.role, cursor, limit: 25 },
    }),
  setRole: (id: string, role: UserRole) =>
    apiRequest<unknown>(`superadmin/users/${id}/role`, { method: 'PATCH', body: { role } }),
  remove: (id: string) => apiRequest<void>(`superadmin/users/${id}`, { method: 'DELETE' }),
};
