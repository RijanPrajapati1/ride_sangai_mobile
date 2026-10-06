import { apiRequest } from '@/core/http/api-client';
import type { Banner, BannerInput } from '../domain/banner';

export const bannersRepository = {
  list: () => apiRequest<{ items: Banner[] }>('superadmin/banners'),
  create: (input: BannerInput) => apiRequest<Banner>('superadmin/banners', { method: 'POST', body: input }),
  update: (id: string, patch: Partial<BannerInput>) =>
    apiRequest<Banner>(`superadmin/banners/${id}`, { method: 'PATCH', body: patch }),
  remove: (id: string) => apiRequest<void>(`superadmin/banners/${id}`, { method: 'DELETE' }),
};
