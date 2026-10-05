import type { Metadata } from 'next';
import { TopUsersScreen } from '@/features/top-users';

export const metadata: Metadata = { title: 'Top riders' };

export default function Page() {
  return <TopUsersScreen />;
}
