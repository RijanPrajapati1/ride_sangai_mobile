import { apiRequest } from '@/core/http/api-client';
import type { Page } from '@/core/http/page';
import type { FeedbackFilters, FeedbackItem, FeedbackStatus, FeedbackUpdate } from '../domain/feedback';

export const feedbackRepository = {
  list: (filters: Partial<FeedbackFilters> & { status?: FeedbackStatus }, cursor: string | null, limit = 25) =>
    apiRequest<Page<FeedbackItem>>('superadmin/feedback', {
      query: {
        status: filters.status,
        category: filters.category === 'all' ? undefined : filters.category,
        cursor,
        limit,
      },
    }),
  update: (id: string, patch: FeedbackUpdate) =>
    apiRequest<FeedbackItem>(`superadmin/feedback/${id}`, { method: 'PATCH', body: patch }),
  /**
   * All-time counts per status. The API has no dedicated endpoint, so this
   * reads `feedbackByStatus` from the (smallest) analytics window.
   */
  statusCounts: async (): Promise<Record<FeedbackStatus, number>> => {
    const a = await apiRequest<{ feedbackByStatus: { key: string; count: number }[] }>('superadmin/analytics', {
      query: { days: 7 },
    });
    const counts: Record<FeedbackStatus, number> = { open: 0, inProgress: 0, resolved: 0 };
    for (const row of a.feedbackByStatus) if (row.key in counts) counts[row.key as FeedbackStatus] = row.count;
    return counts;
  },
  remove: (id: string) => apiRequest<void>(`superadmin/feedback/${id}`, { method: 'DELETE' }),
};
