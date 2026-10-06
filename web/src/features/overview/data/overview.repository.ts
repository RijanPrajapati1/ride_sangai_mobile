import { apiRequest } from '@/core/http/api-client';
import type { Analytics, AnalyticsWindow } from '../domain/analytics';
import type { PlatformStats } from '../domain/stats';

export const overviewRepository = {
  stats: () => apiRequest<PlatformStats>('superadmin/stats'),
  analytics: (days: AnalyticsWindow) => apiRequest<Analytics>('superadmin/analytics', { query: { days } }),
};
