'use client';

import { useInfiniteQuery, type QueryKey } from '@tanstack/react-query';
import type { Page } from '@/core/http/page';

/**
 * Cursor pagination ("Load more") over a `{ items, nextCursor }` endpoint.
 * Returns the flattened items plus the usual query state.
 */
export function useCursorList<T>(
  queryKey: QueryKey,
  fetchPage: (cursor: string | null) => Promise<Page<T>>,
  options: { enabled?: boolean } = {},
) {
  const query = useInfiniteQuery({
    queryKey,
    queryFn: ({ pageParam }) => fetchPage(pageParam),
    initialPageParam: null as string | null,
    getNextPageParam: (last) => last.nextCursor,
    enabled: options.enabled,
  });
  const items = query.data?.pages.flatMap((p) => p.items) ?? [];
  return {
    items,
    isLoading: query.isPending,
    isError: query.isError,
    error: query.error,
    refetch: query.refetch,
    hasMore: !!query.hasNextPage,
    loadMore: () => void query.fetchNextPage(),
    isLoadingMore: query.isFetchingNextPage,
    isRefetching: query.isRefetching && !query.isFetchingNextPage,
  };
}
