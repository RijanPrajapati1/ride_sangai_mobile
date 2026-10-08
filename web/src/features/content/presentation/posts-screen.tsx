'use client';

import { useState } from 'react';
import { Heart, MessageCircle, Newspaper, Pencil, Trash2 } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { UserCell } from '@/shared/components/user-cell';
import { formatDateTime, formatNumber, timeAgo } from '@/shared/lib/format';
import { usePosts } from '../application/use-content';
import type { Post } from '../domain/post';
import { EditContentDialog, type FieldSpec } from './edit-content-dialog';
import { ListCard } from './list-card';
import { CommentsDialog } from './moderation-screens';
import { Thumb } from './thumb';
import { useRemoveFlow } from './use-remove-flow';

const POST_FIELDS: FieldSpec[] = [{ key: 'text', label: 'Post', kind: 'textarea', max: 2000, required: true }];

export function PostsScreen() {
  const list = usePosts();
  const [editing, setEditing] = useState<Post | null>(null);
  const [commentsOf, setCommentsOf] = useState<Post | null>(null);
  const remove = useRemoveFlow<Post>('post', (p) => ({
    title: 'Remove this post?',
    description: (
      <>
        The post by <b className="text-foreground">{p.userName}</b> and all its comments will be deleted. This can&apos;t be undone.
      </>
    ),
  }));

  return (
    <>
      <ListCard
        list={list}
        noun="posts"
        empty={{ icon: Newspaper, title: 'No posts yet', description: 'Posts riders share in the community feed will show up here.' }}
      >
        <ul className="divide-y divide-border">
          {list.items.map((p) => (
            <li key={p.id} className="flex gap-4 px-4 py-4 sm:px-5">
              <div className="min-w-0 flex-1">
                <UserCell
                  name={p.userName}
                  avatarUrl={p.userAvatarUrl}
                  secondary={<span title={formatDateTime(p.time)}>{timeAgo(p.time)}</span>}
                />
                <p className="mt-2.5 line-clamp-4 text-sm leading-relaxed whitespace-pre-wrap text-foreground">{p.text}</p>
                <div className="mt-2.5 flex items-center gap-4 text-xs text-muted">
                  <span className="inline-flex items-center gap-1">
                    <Heart className="size-3.5" /> {formatNumber(p.likeCount)}
                  </span>
                  <button
                    type="button"
                    onClick={() => setCommentsOf(p)}
                    className="inline-flex items-center gap-1 rounded-md px-1 -mx-1 font-medium hover:bg-surface-2 hover:text-foreground"
                    aria-label={`${p.commentCount} comments, open to moderate`}
                  >
                    <MessageCircle className="size-3.5" /> {formatNumber(p.commentCount)} comments
                  </button>
                </div>
              </div>
              <div className="flex shrink-0 flex-col items-end gap-3">
                <div className="flex gap-1">
                  <Button variant="ghost" size="sm" onClick={() => setEditing(p)} aria-label={`Edit post by ${p.userName}`}>
                    <Pencil /> <span className="hidden sm:inline">Edit</span>
                  </Button>
                  <Button variant="danger-ghost" size="sm" onClick={() => remove.ask(p)} aria-label={`Remove post by ${p.userName}`}>
                    <Trash2 /> <span className="hidden sm:inline">Remove</span>
                  </Button>
                </div>
                {p.imageUrl && <Thumb src={p.imageUrl} className="size-20 sm:size-24" />}
              </div>
            </li>
          ))}
        </ul>
      </ListCard>
      {remove.dialog}
      <EditContentDialog
        kind="post"
        item={editing}
        title={`Edit ${editing?.userName ?? ''}’s post`}
        fields={POST_FIELDS}
        onClose={() => setEditing(null)}
      />
      <CommentsDialog post={commentsOf} onClose={() => setCommentsOf(null)} />
    </>
  );
}
