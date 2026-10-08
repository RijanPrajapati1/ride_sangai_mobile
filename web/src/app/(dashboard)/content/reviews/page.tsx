import type { Metadata } from 'next';
import { ReviewsScreen } from '@/features/content';

export const metadata: Metadata = { title: 'Reviews' };

export default function Page() {
  return <ReviewsScreen />;
}
