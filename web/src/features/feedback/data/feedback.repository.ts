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
  remove: (id: string) => apiRequest<void>(`superadmin/feedback/${id}`, { method: 'DELETE' }),
};
