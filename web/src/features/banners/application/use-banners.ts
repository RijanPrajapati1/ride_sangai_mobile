'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { bannersRepository } from '../data/banners.repository';
import type { Banner, BannerInput } from '../domain/banner';

const KEY = ['banners'] as const;

export function useBanners() {
  return useQuery({
    queryKey: KEY,
    queryFn: bannersRepository.list,
    select: (d) => [...d.items].sort((a, b) => a.sortOrder - b.sortOrder || a.title.localeCompare(b.title)),
  });
}

export function useSaveBanner() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: { id?: string; input: BannerInput }) =>
      id ? bannersRepository.update(id, input) : bannersRepository.create(input),
    onSuccess: (_b, { id }) => {
      toast.success(id ? 'Banner updated' : 'Banner created');
      void qc.invalidateQueries({ queryKey: KEY });
    },
  });
}

export function useToggleBanner() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (b: Banner) => bannersRepository.update(b.id, { isActive: !b.isActive }),
    onSuccess: (b) => {
      toast.success(b.isActive ? 'Banner activated' : 'Banner paused');
      void qc.invalidateQueries({ queryKey: KEY });
    },
  });
}

export function useRemoveBanner() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (b: Banner) => bannersRepository.remove(b.id),
    onSuccess: () => {
      toast.success('Banner deleted');
      void qc.invalidateQueries({ queryKey: KEY });
    },
  });
}
