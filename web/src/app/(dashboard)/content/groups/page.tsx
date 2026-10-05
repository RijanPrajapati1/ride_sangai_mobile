import type { Metadata } from 'next';
import { GroupsScreen } from '@/features/content';

export const metadata: Metadata = { title: 'Groups' };

export default function Page() {
  return <GroupsScreen />;
}
