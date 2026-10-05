import type { Metadata } from 'next';
import { LoginScreen } from '@/features/auth';

export const metadata: Metadata = { title: 'Sign in' };

export default async function LoginPage({ searchParams }: PageProps<'/login'>) {
  const { next, reason } = await searchParams;
  return (
    <LoginScreen next={typeof next === 'string' ? next : undefined} reason={typeof reason === 'string' ? reason : undefined} />
  );
}
