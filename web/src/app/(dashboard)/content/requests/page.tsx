import type { Metadata } from 'next';
import { RequestsScreen } from '@/features/content';

export const metadata: Metadata = { title: 'Join requests' };

export default function Page() {
  return <RequestsScreen />;
}
