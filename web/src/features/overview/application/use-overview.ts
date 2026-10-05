'use client';

import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { overviewRepository } from '../data/overview.repository';
import type { AnalyticsWindow } from '../domain/analytics';

export const overviewKeys = {
  stats: ['overview', 'stats'] as const,
  analytics: (days: AnalyticsWindow) => ['overview', 'analytics', days] as const,
};

export function useStats() {
  return useQuery({ queryKey: overviewKeys.stats, queryFn: overviewRepository.stats });
}

export function useAnalytics(days: AnalyticsWindow) {
  return useQuery({
    queryKey: overviewKeys.analytics(days),
    queryFn: () => overviewRepository.analytics(days),
    placeholderData: keepPreviousData,
  });
}
