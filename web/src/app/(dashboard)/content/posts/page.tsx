import type { Metadata } from 'next';
import { PostsScreen } from '@/features/content';

export const metadata: Metadata = { title: 'Posts' };

export default function Page() {
  return <PostsScreen />;
}
