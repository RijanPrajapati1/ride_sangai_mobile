import type { Metadata } from 'next';
import { NotFoundScreen } from '@/shared/layout/not-found-screen';

export const metadata: Metadata = { title: 'Page not found' };

export default function NotFound() {
  return <NotFoundScreen />;
}
