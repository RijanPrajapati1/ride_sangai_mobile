import { apiRequest } from '@/core/http/api-client';
import type { Page } from '@/core/http/page';
import type { Announcement, AnnouncementInput } from '../domain/announcement';

export const announcementsRepository = {
  history: (cursor: string | null) =>
    apiRequest<Page<Announcement>>('superadmin/announcements', { query: { cursor, limit: 20 } }),
  send: (input: AnnouncementInput) =>
    apiRequest<{ recipients: number }>('superadmin/announcements', { method: 'POST', body: input }),
};
