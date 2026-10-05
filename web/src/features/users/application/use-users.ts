'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useCursorList } from '@/core/query/use-cursor-list';
import { usersRepository } from '../data/users.repository';
import type { ManagedUser, UserFilters, UserRole } from '../domain/user';

export const usersKeys = {
  all: ['users'] as const,
  list: (f: UserFilters) => ['users', 'list', f.role, f.q.trim()] as const,
};

export function useUsers(filters: UserFilters) {
  return useCursorList(usersKeys.list(filters), (cursor) => usersRepository.list(filters, cursor));
}

export function useSetRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ user, role }: { user: ManagedUser; role: UserRole }) => usersRepository.setRole(user.id, role),
    onSuccess: (_d, { user, role }) => {
      toast.success(role === 'superadmin' ? `${user.name} is now a superadmin` : `${user.name} is now a rider`);
      void qc.invalidateQueries({ queryKey: usersKeys.all });
      void qc.invalidateQueries({ queryKey: ['overview'] });
      void qc.invalidateQueries({ queryKey: ['audit-log'] });
    },
  });
}

export function useRemoveUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (user: ManagedUser) => usersRepository.remove(user.id),
    onSuccess: (_d, user) => {
      toast.success(`${user.name} was removed`);
      void qc.invalidateQueries({ queryKey: usersKeys.all });
      void qc.invalidateQueries({ queryKey: ['overview'] });
      void qc.invalidateQueries({ queryKey: ['audit-log'] });
    },
  });
}
