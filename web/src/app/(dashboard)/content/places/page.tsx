import type { Metadata } from 'next';
import { PlacesScreen } from '@/features/content';

export const metadata: Metadata = { title: 'Places' };

export default function Page() {
  return <PlacesScreen />;
}
