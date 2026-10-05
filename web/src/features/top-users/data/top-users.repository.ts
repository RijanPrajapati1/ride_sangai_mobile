import { apiRequest } from '@/core/http/api-client';
import type { TopUser, TopUserMetric } from '../domain/top-user';

export const topUsersRepository = {
  list: (metric: TopUserMetric, limit: number) =>
    apiRequest<{ metric: TopUserMetric; items: TopUser[] }>('superadmin/top-users', { query: { metric, limit } }),
};
