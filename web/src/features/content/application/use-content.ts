'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useCursorList } from '@/core/query/use-cursor-list';
import { contentRepository } from '../data/content.repository';
import type { RideWhen } from '../domain/ride';
import type { RideRequestStatus } from '../domain/ride-request';

export const contentKeys = {
  posts: ['content', 'posts'] as const,
  rides: (when: RideWhen, q: string) => ['content', 'rides', when, q.trim()] as const,
  requests: (status: string) => ['content', 'requests', status] as const,
  places: ['content', 'places'] as const,
  groups: ['content', 'groups'] as const,
};

export const usePosts = () => useCursorList(contentKeys.posts, contentRepository.posts);
export const useRides = (when: RideWhen, q: string) =>
  useCursorList(contentKeys.rides(when, q), (cursor) => contentRepository.rides({ when, q }, cursor));
export const useRideRequests = (status: RideRequestStatus | 'all') =>
  useCursorList(contentKeys.requests(status), (cursor) => contentRepository.rideRequests(status, cursor));
export const usePlaces = () => useCursorList(contentKeys.places, contentRepository.places);
export const useGroups = () => useCursorList(contentKeys.groups, contentRepository.groups);

const REMOVERS = {
  post: contentRepository.removePost,
  ride: contentRepository.removeRide,
  place: contentRepository.removePlace,
  group: contentRepository.removeGroup,
} as const;

export type ContentKind = keyof typeof REMOVERS;

const NOUN: Record<ContentKind, string> = { post: 'Post', ride: 'Ride', place: 'Place', group: 'Group' };

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
