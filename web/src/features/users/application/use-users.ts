'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useCursorList } from '@/core/query/use-cursor-list';
import { usersRepository } from '../data/users.repository';
import type { UserFilters, UserRole, UserUpdate } from '../domain/user';

/** Anything with a name and id is enough to act on a user (list row or detail). */
type Target = { id: string; name: string };

export const usersKeys = {
  all: ['users'] as const,
  list: (f: UserFilters) => ['users', 'list', f.role, f.status, f.q.trim()] as const,
  detail: (id: string) => ['users', 'detail', id] as const,
};

export function useUsers(filters: UserFilters) {
  return useCursorList(usersKeys.list(filters), (cursor) => usersRepository.list(filters, cursor));
}

export function useUser(id: string) {
  return useQuery({ queryKey: usersKeys.detail(id), queryFn: () => usersRepository.get(id) });
}

/** Refreshes every view a user change can affect. */
function useAfterUserChange() {
  const qc = useQueryClient();
  return () => {
    void qc.invalidateQueries({ queryKey: usersKeys.all });
    void qc.invalidateQueries({ queryKey: ['overview'] });
    void qc.invalidateQueries({ queryKey: ['audit-log'] });
    void qc.invalidateQueries({ queryKey: ['top-users'] });
  };
}

function useUserMutation<V>(run: (vars: V) => Promise<unknown>, success: (vars: V) => string) {
  const after = useAfterUserChange();
  return useMutation({
    mutationFn: run,
    onSuccess: (_d, vars) => {
      toast.success(success(vars));
      after();
    },
  });
}

export const useSetRole = () =>
  useUserMutation(
    ({ user, role }: { user: Target; role: UserRole }) => usersRepository.setRole(user.id, role),
    ({ user, role }) => (role === 'superadmin' ? `${user.name} is now a superadmin` : `${user.name} is now a rider`),
  );

export const useRemoveUser = () =>
  useUserMutation((user: Target) => usersRepository.remove(user.id), (user) => `${user.name} was removed`);

export const useUpdateUser = () =>
  useUserMutation(
    ({ user, input }: { user: Target; input: UserUpdate }) => usersRepository.update(user.id, input),
    ({ user }) => `${user.name}’s profile was updated`,
  );

export const useDisableUser = () =>
  useUserMutation(
    ({ user, reason }: { user: Target; reason: string | null }) => usersRepository.disable(user.id, reason),
    ({ user }) => `${user.name} is disabled and signed out`,
  );

export const useEnableUser = () =>
  useUserMutation((user: Target) => usersRepository.enable(user.id), (user) => `${user.name} can sign in again`);

export const useSignOutUser = () =>
  useUserMutation(
    (user: Target) => usersRepository.signOut(user.id),
    (user) => `${user.name} was signed out on every device`,
  );

export const useSetPassword = () =>
  useUserMutation(
    ({ user, password }: { user: Target; password: string }) => usersRepository.setPassword(user.id, password),
    ({ user }) => `New password set for ${user.name}`,
  );
