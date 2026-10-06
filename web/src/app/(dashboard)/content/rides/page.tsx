import type { Metadata } from 'next';
import { RidesScreen } from '@/features/content';

export const metadata: Metadata = { title: 'Rides' };

export default function Page() {
  return <RidesScreen />;
}
