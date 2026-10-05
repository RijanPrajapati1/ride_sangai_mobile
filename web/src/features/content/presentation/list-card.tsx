'use client';

import { Card } from '@/shared/ui/card';
import { TableSkeleton } from '@/shared/components/data-table';
import { EmptyState, ErrorState, LoadMore } from '@/shared/components/states';

interface ListState {
  items: unknown[];
  isLoading: boolean;
  isError: boolean;
  error: unknown;
  refetch: () => unknown;
  hasMore: boolean;
  loadMore: () => void;
  isLoadingMore: boolean;
}

/** Card wrapper that handles loading, error, empty and "load more" for a content list. */
export function ListCard({
  list,
  empty,
  noun,
  children,
}: {
  list: ListState;
  empty: { icon: React.ComponentType<{ className?: string }>; title: string; description: string };
  noun: string;
  children: React.ReactNode;
}) {
  return (
    <Card className="overflow-hidden">
      {list.isLoading ? (
        <TableSkeleton rows={6} columns={5} />
      ) : list.isError ? (
        <ErrorState error={list.error} onRetry={() => void list.refetch()} />
      ) : list.items.length === 0 ? (
        <EmptyState icon={empty.icon} title={empty.title} description={empty.description} />
      ) : (
        <>
          {children}
          <LoadMore count={list.items.length} hasMore={list.hasMore} loading={list.isLoadingMore} onClick={list.loadMore} noun={noun} />
        </>
      )}
    </Card>
  );
}
