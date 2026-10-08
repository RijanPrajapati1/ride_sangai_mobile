'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useCursorList } from '@/core/query/use-cursor-list';
import { contentRepository, type ContentChanges } from '../data/content.repository';
import type { RideWhen } from '../domain/ride';
import type { RideRequestStatus } from '../domain/ride-request';

export const contentKeys = {
  posts: ['content', 'posts'] as const,
  rides: (when: RideWhen, q: string) => ['content', 'rides', when, q.trim()] as const,
  requests: (status: string) => ['content', 'requests', status] as const,
  places: ['content', 'places'] as const,
  groups: ['content', 'groups'] as const,
  comments: (q: string, postId?: string) => ['content', 'comments', postId ?? 'all', q.trim()] as const,
  reviews: (q: string, placeId?: string) => ['content', 'reviews', placeId ?? 'all', q.trim()] as const,
};

export const usePosts = () => useCursorList(contentKeys.posts, contentRepository.posts);
export const useRides = (when: RideWhen, q: string) =>
  useCursorList(contentKeys.rides(when, q), (cursor) => contentRepository.rides({ when, q }, cursor));
export const useRideRequests = (status: RideRequestStatus | 'all') =>
  useCursorList(contentKeys.requests(status), (cursor) => contentRepository.rideRequests(status, cursor));
export const usePlaces = () => useCursorList(contentKeys.places, contentRepository.places);
export const useGroups = () => useCursorList(contentKeys.groups, contentRepository.groups);
export const useComments = (q: string, postId?: string) =>
  useCursorList(contentKeys.comments(q, postId), (cursor) => contentRepository.comments({ q, postId }, cursor));
export const useReviews = (q: string, placeId?: string) =>
  useCursorList(contentKeys.reviews(q, placeId), (cursor) => contentRepository.reviews({ q, placeId }, cursor));

const REMOVERS = {
  post: contentRepository.removePost,
  ride: contentRepository.removeRide,
  place: contentRepository.removePlace,
  group: contentRepository.removeGroup,
  comment: contentRepository.removeComment,
  review: contentRepository.removeReview,
} as const;

export type ContentKind = keyof typeof REMOVERS;

const NOUN: Record<ContentKind, string> = {
  post: 'Post',
  ride: 'Ride',
  place: 'Place',
  group: 'Group',
  comment: 'Comment',
  review: 'Review',
};

const EDITORS = {
  post: contentRepository.editPost,
  ride: contentRepository.editRide,
  place: contentRepository.editPlace,
  group: contentRepository.editGroup,
} as const;

export type EditableKind = keyof typeof EDITORS;

/** Edits a post, ride, place or group (only the changed fields), then refreshes the lists. */
export function useEditContent(kind: EditableKind) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, changes }: { id: string; changes: ContentChanges }): Promise<unknown> =>
      EDITORS[kind](id, changes),
    onSuccess: () => {
      toast.success(`${NOUN[kind]} updated`);
      void qc.invalidateQueries({ queryKey: ['content'] });
      void qc.invalidateQueries({ queryKey: ['audit-log'] });
    },
  });
}

/** Approves or declines a join request on anyone's ride. */
export function useDecideRequest() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, approve, reason }: { id: string; approve: boolean; reason?: string | null }) =>
      approve ? contentRepository.approveRequest(id) : contentRepository.declineRequest(id, reason ?? null),
    onSuccess: (request) => {
      toast.success(`${request.userName} ${request.status === 'approved' ? 'is in' : 'was declined'}`);
      void qc.invalidateQueries({ queryKey: ['content'] });
      void qc.invalidateQueries({ queryKey: ['overview'] });
      void qc.invalidateQueries({ queryKey: ['audit-log'] });
    },
  });
}

/** Removes a post, ride, place or group, then refreshes the affected lists. */
export function useRemoveContent(kind: ContentKind) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => REMOVERS[kind](id),
    onSuccess: () => {
      toast.success(`${NOUN[kind]} removed`);
      void qc.invalidateQueries({ queryKey: ['content'] });
      void qc.invalidateQueries({ queryKey: ['overview'] });
      void qc.invalidateQueries({ queryKey: ['audit-log'] });
      void qc.invalidateQueries({ queryKey: ['top-users'] });
    },
  });
}
