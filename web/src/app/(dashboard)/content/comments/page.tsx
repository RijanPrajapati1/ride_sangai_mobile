import type { Metadata } from 'next';
import { CommentsScreen } from '@/features/content';

export const metadata: Metadata = { title: 'Comments' };

export default function Page() {
  return <CommentsScreen />;
}
