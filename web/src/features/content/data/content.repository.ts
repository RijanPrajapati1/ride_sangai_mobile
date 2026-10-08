import { apiRequest } from '@/core/http/api-client';
import type { Page } from '@/core/http/page';
import type { Group } from '../domain/group';
import type { AdminComment, AdminReview } from '../domain/moderation';
import type { Place } from '../domain/place';
import type { Post } from '../domain/post';
import type { Ride, RideWhen } from '../domain/ride';
import type { RideRequest, RideRequestStatus } from '../domain/ride-request';

const LIMIT = 20;

/** Partial edits; the API only changes the fields sent. */
export type ContentChanges = Record<string, string | number | null>;

export const contentRepository = {
  posts: (cursor: string | null) => apiRequest<Page<Post>>('superadmin/posts', { query: { cursor, limit: LIMIT } }),
  editPost: (id: string, changes: ContentChanges) =>
    apiRequest<Post>(`superadmin/posts/${id}`, { method: 'PATCH', body: changes }),
  removePost: (id: string) => apiRequest<void>(`superadmin/posts/${id}`, { method: 'DELETE' }),

  rides: (filters: { when: RideWhen; q: string }, cursor: string | null) =>
    apiRequest<Page<Ride>>('superadmin/rides', {
      query: { when: filters.when, q: filters.q.trim() || undefined, cursor, limit: LIMIT },
    }),
  editRide: (id: string, changes: ContentChanges) =>
    apiRequest<Ride>(`superadmin/rides/${id}`, { method: 'PATCH', body: changes }),
  removeRide: (id: string) => apiRequest<void>(`superadmin/rides/${id}`, { method: 'DELETE' }),

  rideRequests: (status: RideRequestStatus | 'all', cursor: string | null) =>
    apiRequest<Page<RideRequest>>('superadmin/ride-requests', {
      query: { status: status === 'all' ? undefined : status, cursor, limit: LIMIT },
    }),
  approveRequest: (id: string) =>
    apiRequest<RideRequest>(`superadmin/ride-requests/${id}/approve`, { method: 'POST' }),
  declineRequest: (id: string, reason: string | null) =>
    apiRequest<RideRequest>(`superadmin/ride-requests/${id}/decline`, { method: 'POST', body: { reason } }),

  places: (cursor: string | null) => apiRequest<Page<Place>>('superadmin/places', { query: { cursor, limit: LIMIT } }),
  editPlace: (id: string, changes: ContentChanges) =>
    apiRequest<Place>(`superadmin/places/${id}`, { method: 'PATCH', body: changes }),
  removePlace: (id: string) => apiRequest<void>(`superadmin/places/${id}`, { method: 'DELETE' }),

  groups: (cursor: string | null) => apiRequest<Page<Group>>('superadmin/groups', { query: { cursor, limit: LIMIT } }),
  editGroup: (id: string, changes: ContentChanges) =>
    apiRequest<Group>(`superadmin/groups/${id}`, { method: 'PATCH', body: changes }),
  removeGroup: (id: string) => apiRequest<void>(`superadmin/groups/${id}`, { method: 'DELETE' }),

  comments: (filters: { q: string; postId?: string }, cursor: string | null) =>
    apiRequest<Page<AdminComment>>('superadmin/comments', {
      query: { q: filters.q.trim() || undefined, postId: filters.postId, cursor, limit: LIMIT },
    }),
  removeComment: (id: string) => apiRequest<void>(`superadmin/comments/${id}`, { method: 'DELETE' }),

  reviews: (filters: { q: string; placeId?: string }, cursor: string | null) =>
    apiRequest<Page<AdminReview>>('superadmin/reviews', {
      query: { q: filters.q.trim() || undefined, placeId: filters.placeId, cursor, limit: LIMIT },
    }),
  removeReview: (id: string) => apiRequest<void>(`superadmin/reviews/${id}`, { method: 'DELETE' }),
};
