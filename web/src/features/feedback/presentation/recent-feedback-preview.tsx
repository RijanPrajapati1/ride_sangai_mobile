'use client';

import Link from 'next/link';
import { ArrowRight, MessageSquareHeart } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/card';
import { Skeleton } from '@/shared/ui/skeleton';
import { Avatar } from '@/shared/ui/avatar';
import { EmptyState } from '@/shared/components/states';
import { timeAgo } from '@/shared/lib/format';
import { useRecentFeedback } from '../application/use-feedback';
import { CategoryBadge, StatusBadge } from './feedback-badges';

export function RecentFeedbackPreview() {
  const { data, isPending } = useRecentFeedback(4);
  return (
    <Card className="flex flex-col">
      <CardHeader
        title="Recent feedback"
        description="Latest messages from riders"
        action={
          <Link href="/feedback" className="inline-flex items-center gap-1 text-[13px] font-medium text-primary-ink hover:underline">
            Inbox <ArrowRight className="size-3.5" />
          </Link>
        }
      />
      <div className="flex-1 px-2 pt-3 pb-2">
        {isPending ? (
          <div className="flex flex-col gap-3 px-3 py-2">
            {Array.from({ length: 4 }, (_, i) => (
              <Skeleton key={i} className="h-12" />
            ))}
          </div>
        ) : !data?.length ? (
          <EmptyState compact icon={MessageSquareHeart} title="No feedback yet" description="When riders send feedback from the app, it shows up here." />
        ) : (
          <ul>
            {data.map((f) => (
              <li key={f.id}>
                <Link href="/feedback" className="flex gap-3 rounded-lg px-3 py-2.5 hover:bg-surface-2/60">
                  <Avatar name={f.user?.name ?? 'Deleted rider'} src={f.user?.avatarUrl} size={32} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="truncate text-sm font-medium">{f.user?.name ?? 'Deleted rider'}</span>
                      <span className="ml-auto shrink-0 text-xs text-subtle">{timeAgo(f.createdAt)}</span>
                    </div>
                    <p className="mt-0.5 truncate text-[13px] text-muted">{f.message}</p>
                    <div className="mt-1.5 flex gap-1.5">
                      <CategoryBadge category={f.category} />
                      <StatusBadge status={f.status} />
                    </div>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>
    </Card>
  );
}
