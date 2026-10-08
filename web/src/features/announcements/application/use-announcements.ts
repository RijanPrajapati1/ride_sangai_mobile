'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useCursorList } from '@/core/query/use-cursor-list';
import { formatNumber } from '@/shared/lib/format';
import { announcementsRepository } from '../data/announcements.repository';
import type { AnnouncementInput } from '../domain/announcement';

const KEY = ['announcements'] as const;

export const useAnnouncements = () => useCursorList(KEY, announcementsRepository.history);

export function useSendAnnouncement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: AnnouncementInput) => announcementsRepository.send(input),
    onSuccess: ({ recipients }) => {
      toast.success(`Sent to ${formatNumber(recipients)} rider${recipients === 1 ? '' : 's'}`);
      void qc.invalidateQueries({ queryKey: KEY });
      void qc.invalidateQueries({ queryKey: ['audit-log'] });
    },
  });
}
