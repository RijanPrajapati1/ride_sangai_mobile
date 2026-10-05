import { apiRequest } from '@/core/http/api-client';
import type { Page } from '@/core/http/page';
import type { Group } from '../domain/group';
import type { Place } from '../domain/place';
import type { Post } from '../domain/post';
import type { Ride, RideWhen } from '../domain/ride';
import type { RideRequest, RideRequestStatus } from '../domain/ride-request';

const LIMIT = 20;

export const contentRepository = {
  posts: (cursor: string | null) => apiRequest<Page<Post>>('superadmin/posts', { query: { cursor, limit: LIMIT } }),
  removePost: (id: string) => apiRequest<void>(`superadmin/posts/${id}`, { method: 'DELETE' }),

  rides: (filters: { when: RideWhen; q: string }, cursor: string | null) =>
    apiRequest<Page<Ride>>('superadmin/rides', {
      query: { when: filters.when, q: filters.q.trim() || undefined, cursor, limit: LIMIT },
    }),
  removeRide: (id: string) => apiRequest<void>(`superadmin/rides/${id}`, { method: 'DELETE' }),

  rideRequests: (status: RideRequestStatus | 'all', cursor: string | null) =>
    apiRequest<Page<RideRequest>>('superadmin/ride-requests', {
      query: { status: status === 'all' ? undefined : status, cursor, limit: LIMIT },
    }),

  places: (cursor: string | null) => apiRequest<Page<Place>>('superadmin/places', { query: { cursor, limit: LIMIT } }),
  removePlace: (id: string) => apiRequest<void>(`superadmin/places/${id}`, { method: 'DELETE' }),

  groups: (cursor: string | null) => apiRequest<Page<Group>>('superadmin/groups', { query: { cursor, limit: LIMIT } }),
  removeGroup: (id: string) => apiRequest<void>(`superadmin/groups/${id}`, { method: 'DELETE' }),
};
