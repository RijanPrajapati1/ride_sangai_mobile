'use client';

import { useMutation, useQuery } from '@tanstack/react-query';
import { goToLogin } from '@/core/http/api-client';
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
  return useMutation({
    mutationFn: authRepository.logout,
    onSettled: () => goToLogin('signed-out', { keepLocation: false }),
  });
}
