import type { Metadata } from 'next';
import { FeedbackScreen } from '@/features/feedback';

export const metadata: Metadata = { title: 'Feedback' };

export default function Page() {
  return <FeedbackScreen />;
}
