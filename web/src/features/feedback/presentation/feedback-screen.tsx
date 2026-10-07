'use client';

import { useState } from 'react';
import { ChevronRight, Inbox, StickyNote } from 'lucide-react';
import { Card } from '@/shared/ui/card';
import { Select } from '@/shared/ui/input';
import { PageHeader } from '@/shared/layout/page-header';
import { Segmented } from '@/shared/components/segmented';
import { EmptyState, ErrorState, LoadMore } from '@/shared/components/states';
import { TableSkeleton } from '@/shared/components/data-table';
import { Avatar } from '@/shared/ui/avatar';
import { timeAgo } from '@/shared/lib/format';
import { useFeedbackCounts, useFeedbackList } from '../application/use-feedback';
import {
  CATEGORY_LABELS,
  FEEDBACK_CATEGORIES,
  FEEDBACK_STATUSES,
  STATUS_LABELS,
  type FeedbackCategory,
  type FeedbackItem,
  type FeedbackStatus,
} from '../domain/feedback';
import { CategoryBadge, Stars } from './feedback-badges';
import { FeedbackDetailDialog } from './feedback-detail-dialog';

const EMPTY: Record<FeedbackStatus, { title: string; description: string }> = {
  open: { title: 'Inbox zero', description: 'No open feedback. New messages from riders land here first.' },
  inProgress: { title: 'Nothing in progress', description: 'Move feedback here while the team works on it.' },
  resolved: { title: 'Nothing resolved yet', description: 'Feedback you resolve is kept here for reference.' },
};

function FeedbackRow({ item, onOpen }: { item: FeedbackItem; onOpen: () => void }) {
  return (
    <li>
      <button
        type="button"
        onClick={onOpen}
        className="group flex w-full items-start gap-3 px-4 py-4 text-left transition-colors hover:bg-surface-2/60 sm:px-5"
      >
        <Avatar name={item.user?.name ?? 'Deleted rider'} src={item.user?.avatarUrl} size={36} />
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <span className="truncate text-sm font-semibold">{item.user?.name ?? 'Deleted rider'}</span>
            <CategoryBadge category={item.category} />
            <Stars rating={item.rating} />
            <span className="ml-auto text-xs whitespace-nowrap text-subtle">{timeAgo(item.createdAt)}</span>
          </div>
          <p className="mt-1.5 line-clamp-2 text-sm leading-relaxed text-muted">{item.message}</p>
          {item.adminNote && (
            <p className="mt-2 inline-flex max-w-full items-center gap-1.5 rounded-md bg-warning-soft px-2 py-1 text-xs text-warning-ink">
              <StickyNote className="size-3 shrink-0" />
              <span className="truncate">{item.adminNote}</span>
            </p>
          )}
        </div>
        <ChevronRight className="mt-2 size-4 shrink-0 text-subtle transition group-hover:translate-x-0.5 group-hover:text-foreground" />
      </button>
    </li>
  );
}

export function FeedbackScreen() {
  const [status, setStatus] = useState<FeedbackStatus>('open');
  const [category, setCategory] = useState<FeedbackCategory | 'all'>('all');
  const [opened, setOpened] = useState<FeedbackItem | null>(null);
  const list = useFeedbackList({ status, category });
  const counts = useFeedbackCounts();

  return (
    <>
      <PageHeader title="Feedback" description="Bug reports, ideas and praise sent from the Yatrix app." />
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <Segmented
          ariaLabel="Status"
          value={status}
          onChange={setStatus}
          options={FEEDBACK_STATUSES.map((s) => ({ value: s, label: STATUS_LABELS[s], count: counts.data?.[s] }))}
        />
        <Select
          aria-label="Category"
          className="w-44"
          value={category}
          onChange={(e) => setCategory(e.target.value as FeedbackCategory | 'all')}
        >
          <option value="all">All categories</option>
          {FEEDBACK_CATEGORIES.map((c) => (
            <option key={c} value={c}>
              {CATEGORY_LABELS[c]}
            </option>
          ))}
        </Select>
      </div>
      <Card className="overflow-hidden">
        {list.isLoading ? (
          <TableSkeleton rows={5} columns={2} />
        ) : list.isError ? (
          <ErrorState error={list.error} onRetry={() => void list.refetch()} />
        ) : list.items.length === 0 ? (
          <EmptyState
            icon={Inbox}
            title={category === 'all' ? EMPTY[status].title : `No ${CATEGORY_LABELS[category].toLowerCase()} feedback here`}
            description={category === 'all' ? EMPTY[status].description : 'Try another category or status.'}
          />
        ) : (
          <>
            <ul className="divide-y divide-border">
              {list.items.map((item) => (
                <FeedbackRow key={item.id} item={item} onOpen={() => setOpened(item)} />
              ))}
            </ul>
            <LoadMore
              count={list.items.length}
              hasMore={list.hasMore}
              loading={list.isLoadingMore}
              onClick={list.loadMore}
              noun="messages"
            />
          </>
        )}
      </Card>
      <FeedbackDetailDialog item={opened} onClose={() => setOpened(null)} />
    </>
  );
}
