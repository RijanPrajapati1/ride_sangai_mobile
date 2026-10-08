'use client';

import { useState } from 'react';
import Link from 'next/link';
import { MessageCircle, MessageSquareText, Star, ThumbsDown, ThumbsUp, Trash2 } from 'lucide-react';
import { Badge } from '@/shared/ui/badge';
import { Button } from '@/shared/ui/button';
import { Dialog, DialogBody, DialogContent } from '@/shared/ui/dialog';
import { SearchInput } from '@/shared/components/search-input';
import { EmptyState, ErrorState, LoadMore } from '@/shared/components/states';
import { UserCell } from '@/shared/components/user-cell';
import { formatDateTime, timeAgo } from '@/shared/lib/format';
import { useDebouncedValue } from '@/shared/lib/use-debounced-value';
import { useComments, useReviews } from '../application/use-content';
import type { AdminComment, AdminReview } from '../domain/moderation';
import { ListCard } from './list-card';
import { Thumb } from './thumb';
import { useRemoveFlow } from './use-remove-flow';

function Author({ user, at }: { user: AdminComment['author']; at: string }) {
  return (
    <Link href={`/users/${user.id}`} className="rounded-lg">
      <UserCell
        name={user.name}
        avatarUrl={user.avatarUrl}
        size={30}
        secondary={<span title={formatDateTime(at)}>{timeAgo(at)}</span>}
      />
    </Link>
  );
}

function CommentRows({ items, showPost, onRemove }: { items: AdminComment[]; showPost: boolean; onRemove: (c: AdminComment) => void }) {
  return (
    <ul className="divide-y divide-border">
      {items.map((c) => (
        <li key={c.id} className="flex gap-4 px-4 py-3.5 sm:px-5">
          <div className="min-w-0 flex-1">
            <Author user={c.author} at={c.createdAt} />
            <p className="mt-2 text-sm leading-relaxed whitespace-pre-wrap">{c.text}</p>
            {showPost && (
              <p className="mt-2 line-clamp-1 border-l-2 border-border pl-2.5 text-xs text-muted">On: {c.post.text}</p>
            )}
          </div>
          <Button variant="danger-ghost" size="sm" onClick={() => onRemove(c)} aria-label={`Remove comment by ${c.author.name}`}>
            <Trash2 /> <span className="hidden sm:inline">Remove</span>
          </Button>
        </li>
      ))}
    </ul>
  );
}

function Stars({ rating }: { rating: number }) {
  return (
    <span className="inline-flex items-center gap-0.5" aria-label={`${rating} out of 5`}>
      {Array.from({ length: 5 }, (_, i) => (
        <Star key={i} className={i < rating ? 'size-3.5 fill-warning text-warning' : 'size-3.5 text-border-strong'} />
      ))}
    </span>
  );
}

function ReviewRows({ items, showPlace, onRemove }: { items: AdminReview[]; showPlace: boolean; onRemove: (r: AdminReview) => void }) {
  return (
    <ul className="divide-y divide-border">
      {items.map((r) => (
        <li key={r.id} className="flex gap-4 px-4 py-3.5 sm:px-5">
          <div className="min-w-0 flex-1">
            <Author user={r.author} at={r.createdAt} />
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <Stars rating={r.rating} />
              {r.worthIt ? (
                <Badge tone="success">
                  <ThumbsUp /> Worth it
                </Badge>
              ) : (
                <Badge tone="danger">
                  <ThumbsDown /> Not worth it
                </Badge>
              )}
              {showPlace && <span className="text-xs font-medium text-muted">{r.place.name}</span>}
            </div>
            {r.text && <p className="mt-2 text-sm leading-relaxed whitespace-pre-wrap">{r.text}</p>}
          </div>
          <div className="flex shrink-0 flex-col items-end gap-2">
            <Button variant="danger-ghost" size="sm" onClick={() => onRemove(r)} aria-label={`Remove review by ${r.author.name}`}>
              <Trash2 /> <span className="hidden sm:inline">Remove</span>
            </Button>
            {r.photos[0] && <Thumb src={r.photos[0]} className="size-16" />}
          </div>
        </li>
      ))}
    </ul>
  );
}

function useRemoveComment() {
  return useRemoveFlow<AdminComment>('comment', (c) => ({
    title: 'Remove this comment?',
    description: (
      <>
        The comment by <b className="text-foreground">{c.author.name}</b> will be deleted. This can&apos;t be undone.
      </>
    ),
  }));
}

function useRemoveReview() {
  return useRemoveFlow<AdminReview>('review', (r) => ({
    title: 'Remove this review?',
    description: (
      <>
        {r.author.name}&apos;s {r.rating}-star review of <b className="text-foreground">{r.place.name}</b> will be deleted and the
        place&apos;s rating recalculated.
      </>
    ),
  }));
}

export function CommentsScreen() {
  const [search, setSearch] = useState('');
  const q = useDebouncedValue(search, 300);
  const list = useComments(q);
  const remove = useRemoveComment();
  return (
    <>
      <div className="mb-4 flex">
        <SearchInput value={search} onChange={setSearch} placeholder="Search comment text" className="w-full sm:ml-auto sm:w-72" />
      </div>
      <ListCard
        list={list}
        noun="comments"
        empty={{
          icon: MessageCircle,
          title: q ? 'No matching comments' : 'No comments yet',
          description: q ? 'Try a different word.' : 'Comments riders leave on posts will appear here.',
        }}
      >
        <CommentRows items={list.items} showPost onRemove={remove.ask} />
      </ListCard>
      {remove.dialog}
    </>
  );
}

export function ReviewsScreen() {
  const [search, setSearch] = useState('');
  const q = useDebouncedValue(search, 300);
  const list = useReviews(q);
  const remove = useRemoveReview();
  return (
    <>
      <div className="mb-4 flex">
        <SearchInput value={search} onChange={setSearch} placeholder="Search review text" className="w-full sm:ml-auto sm:w-72" />
      </div>
      <ListCard
        list={list}
        noun="reviews"
        empty={{
          icon: MessageSquareText,
          title: q ? 'No matching reviews' : 'No reviews yet',
          description: q ? 'Try a different word.' : 'Reviews riders write about shared places will appear here.',
        }}
      >
        <ReviewRows items={list.items} showPlace onRemove={remove.ask} />
      </ListCard>
      {remove.dialog}
    </>
  );
}

/** A list inside a dialog: loading, error, empty and "load more", without the card chrome. */
function DialogList({
  list,
  empty,
  noun,
  children,
}: {
  list: ReturnType<typeof useComments> | ReturnType<typeof useReviews>;
  empty: string;
  noun: string;
  children: React.ReactNode;
}) {
  if (list.isLoading) return <div className="px-5 py-10 text-center text-sm text-muted">Loading…</div>;
  if (list.isError) return <ErrorState error={list.error} onRetry={() => void list.refetch()} />;
  if (list.items.length === 0) return <EmptyState icon={MessageCircle} title={empty} description="" />;
  return (
    <>
      {children}
      <LoadMore count={list.items.length} hasMore={list.hasMore} loading={list.isLoadingMore} onClick={list.loadMore} noun={noun} />
    </>
  );
}

function PostComments({ postId }: { postId: string }) {
  const list = useComments('', postId);
  const remove = useRemoveComment();
  return (
    <>
      <DialogList list={list} empty="No comments on this post" noun="comments">
        <CommentRows items={list.items} showPost={false} onRemove={remove.ask} />
      </DialogList>
      {remove.dialog}
    </>
  );
}

function PlaceReviews({ placeId }: { placeId: string }) {
  const list = useReviews('', placeId);
  const remove = useRemoveReview();
  return (
    <>
      <DialogList list={list} empty="No reviews of this place" noun="reviews">
        <ReviewRows items={list.items} showPlace={false} onRemove={remove.ask} />
      </DialogList>
      {remove.dialog}
    </>
  );
}

export function CommentsDialog({ post, onClose }: { post: { id: string; userName: string } | null; onClose: () => void }) {
  return (
    <Dialog open={!!post} onOpenChange={(o) => !o && onClose()}>
      {post && (
        <DialogContent title={`Comments on ${post.userName}’s post`} className="max-w-xl">
          <DialogBody className="px-0 py-0">
            <PostComments postId={post.id} />
          </DialogBody>
        </DialogContent>
      )}
    </Dialog>
  );
}

export function ReviewsDialog({ place, onClose }: { place: { id: string; name: string } | null; onClose: () => void }) {
  return (
    <Dialog open={!!place} onOpenChange={(o) => !o && onClose()}>
      {place && (
        <DialogContent title={`Reviews of ${place.name}`} className="max-w-xl">
          <DialogBody className="px-0 py-0">
            <PlaceReviews placeId={place.id} />
          </DialogBody>
        </DialogContent>
      )}
    </Dialog>
  );
}
