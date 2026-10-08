import type { Metadata } from 'next';
import { UserDetailScreen } from '@/features/users';

export const metadata: Metadata = { title: 'User' };

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <UserDetailScreen id={id} />;
}
