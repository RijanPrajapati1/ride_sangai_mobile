import type { Metadata } from 'next';
import { BannersScreen } from '@/features/banners';

export const metadata: Metadata = { title: 'Banners' };

export default function Page() {
  return <BannersScreen />;
}
