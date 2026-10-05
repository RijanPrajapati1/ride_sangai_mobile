'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useCursorList } from '@/core/query/use-cursor-list';
import { feedbackRepository } from '../data/feedback.repository';
import { STATUS_LABELS, type FeedbackFilters, type FeedbackItem, type FeedbackUpdate } from '../domain/feedback';

export const feedbackKeys = {
  all: ['feedback'] as const,
  list: (f: FeedbackFilters) => ['feedback', 'list', f.status, f.category] as const,
  recent: ['feedback', 'recent'] as const,
};

export function useFeedbackList(filters: FeedbackFilters) {
  return useCursorList(feedbackKeys.list(filters), (cursor) => feedbackRepository.list(filters, cursor));
}

/** Latest feedback of any status (overview preview). */
export function useRecentFeedback(limit = 5) {
  return useQuery({
    queryKey: [...feedbackKeys.recent, limit],
    queryFn: () => feedbackRepository.list({}, null, limit),
    select: (page) => page.items,
  });
}

function invalidate(qc: ReturnType<typeof useQueryClient>) {
  void qc.invalidateQueries({ queryKey: feedbackKeys.all });
  void qc.invalidateQueries({ queryKey: ['overview'] });
  void qc.invalidateQueries({ queryKey: ['audit-log'] });
}

export function useUpdateFeedback() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ item, patch }: { item: FeedbackItem; patch: FeedbackUpdate }) =>
      feedbackRepository.update(item.id, patch),
    onSuccess: (_updated, { patch }) => {
      if (patch.status) toast.success(`Marked as ${STATUS_LABELS[patch.status].toLowerCase()}`);
      else toast.success('Note saved');
      invalidate(qc);
    },
  });
}

export function useRemoveFeedback() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (item: FeedbackItem) => feedbackRepository.remove(item.id),
    onSuccess: () => {
      toast.success('Feedback deleted');
      invalidate(qc);
    },
  });
}
