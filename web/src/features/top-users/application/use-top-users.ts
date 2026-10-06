'use client';

import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { topUsersRepository } from '../data/top-users.repository';
import type { TopUserMetric } from '../domain/top-user';

export function useTopUsers(metric: TopUserMetric, limit: number) {
  return useQuery({
    queryKey: ['top-users', metric, limit],
    queryFn: () => topUsersRepository.list(metric, limit),
    select: (data) => data.items,
    placeholderData: keepPreviousData,
  });
}
