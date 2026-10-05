'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { authRepository } from '../data/auth.repository';
import type { LoginInput } from './login.schema';

export const authKeys = { me: ['auth', 'me'] as const };

export function useCurrentUser() {
  return useQuery({ queryKey: authKeys.me, queryFn: authRepository.me, staleTime: 5 * 60_000 });
}

export function useLogin() {
  return useMutation({
    mutationFn: ({ email, password }: LoginInput) => authRepository.login(email, password),
    meta: { silent: true }, // the form shows the error inline
  });
}

export function useLogout() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: authRepository.logout,
    onSettled: () => {
      qc.clear();
      window.location.assign('/login?reason=signed-out');
    },
  });
}
