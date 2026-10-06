'use client';

import { useState } from 'react';
import { Trash2 } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { Dialog, DialogBody, DialogContent, DialogFooter } from '@/shared/ui/dialog';
import { Textarea } from '@/shared/ui/input';
import { ConfirmDialog } from '@/shared/components/confirm-dialog';
import { Segmented } from '@/shared/components/segmented';
import { UserCell } from '@/shared/components/user-cell';
import { formatDateTime, timeAgo } from '@/shared/lib/format';
import { ADMIN_NOTE_MAX, adminNoteSchema } from '../application/feedback-note.schema';
import { useRemoveFeedback, useUpdateFeedback } from '../application/use-feedback';
import { FEEDBACK_STATUSES, STATUS_LABELS, type FeedbackItem, type FeedbackStatus } from '../domain/feedback';
import { CategoryBadge, Stars, StatusBadge } from './feedback-badges';

function Meta({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-muted">{label}</dt>
      <dd className="mt-0.5 truncate text-sm text-foreground">{children}</dd>
    </div>
  );
}

function DetailBody({ item, onClose }: { item: FeedbackItem; onClose: () => void }) {
  const update = useUpdateFeedback();
  const remove = useRemoveFeedback();
  const [status, setStatus] = useState<FeedbackStatus>(item.status);
  const [note, setNote] = useState(item.adminNote);
  const [savedNote, setSavedNote] = useState(item.adminNote);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const noteCheck = adminNoteSchema.safeParse(note);
  const noteDirty = note.trim() !== savedNote.trim();

  const changeStatus = (next: FeedbackStatus) => {
    if (next === status) return;
    const prev = status;
    setStatus(next);
    update.mutate({ item, patch: { status: next } }, { onError: () => setStatus(prev) });
  };

  return (
    <>
      <DialogBody className="flex flex-col gap-5">
        <div className="flex flex-wrap items-center gap-2">
          <CategoryBadge category={item.category} />
          <StatusBadge status={status} />
          <Stars rating={item.rating} />
        </div>
        <blockquote className="rounded-xl border border-border bg-surface-2/60 p-4 text-[15px] leading-relaxed whitespace-pre-wrap text-foreground">
          {item.message}
        </blockquote>
        {item.user ? (
          <UserCell name={item.user.name} avatarUrl={item.user.avatarUrl} secondary={item.user.email} size={36} />
        ) : (
          <p className="text-sm text-muted">Sent by a rider who has since deleted their account.</p>
        )}
        <dl className="grid grid-cols-2 gap-x-4 gap-y-3 sm:grid-cols-3">
          <Meta label="Received">{formatDateTime(item.createdAt)}</Meta>
          <Meta label="Platform">{item.platform || '—'}</Meta>
          <Meta label="App version">{item.appVersion || '—'}</Meta>
          <Meta label="Last updated">{timeAgo(item.updatedAt)}</Meta>
          {item.resolvedAt && <Meta label="Resolved">{formatDateTime(item.resolvedAt)}</Meta>}
        </dl>

        <div className="flex flex-col gap-2">
          <span className="text-[13px] font-medium">Status</span>
          <Segmented
            ariaLabel="Status"
            value={status}
            onChange={changeStatus}
            className="self-start"
            options={FEEDBACK_STATUSES.map((s) => ({ value: s, label: STATUS_LABELS[s] }))}
          />
        </div>

        <div className="flex flex-col gap-2">
          <label htmlFor="admin-note" className="flex items-baseline justify-between text-[13px] font-medium">
            Internal note
            <span className={noteCheck.success ? 'text-xs font-normal text-subtle' : 'text-xs font-normal text-danger-ink'}>
              {note.length}/{ADMIN_NOTE_MAX}
            </span>
          </label>
          <Textarea
            id="admin-note"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="Only the platform team sees this. e.g. “Reproduced on Android 14, fix in 1.4.2”"
            aria-invalid={!noteCheck.success}
          />
          {!noteCheck.success && <p className="text-xs text-danger-ink">{noteCheck.error.issues[0]?.message}</p>}
        </div>
      </DialogBody>
      <DialogFooter className="sm:justify-between">
        <Button variant="danger-ghost" onClick={() => setConfirmDelete(true)}>
          <Trash2 /> Delete
        </Button>
        <div className="flex flex-col-reverse gap-2 sm:flex-row">
          <Button variant="secondary" onClick={onClose}>
            Close
          </Button>
          <Button
            disabled={!noteDirty || !noteCheck.success}
            loading={update.isPending && update.variables?.patch.adminNote !== undefined}
            onClick={() =>
              update.mutate({ item, patch: { adminNote: note } }, { onSuccess: (updated) => setSavedNote(updated.adminNote) })
            }
          >
            Save note
          </Button>
        </div>
      </DialogFooter>
      <ConfirmDialog
        open={confirmDelete}
        onOpenChange={setConfirmDelete}
        title="Delete this feedback?"
        description="Use this for spam or test messages. The rider is not notified, and this can't be undone."
        loading={remove.isPending}
        onConfirm={() =>
          remove.mutate(item, {
            onSuccess: () => {
              setConfirmDelete(false);
              onClose();
            },
          })
        }
      />
    </>
  );
}

export function FeedbackDetailDialog({ item, onClose }: { item: FeedbackItem | null; onClose: () => void }) {
  return (
    <Dialog open={!!item} onOpenChange={(o) => !o && onClose()}>
      {item && (
        <DialogContent title="Feedback" description={`Received ${timeAgo(item.createdAt)}`} className="max-w-xl">
          <DetailBody key={item.id} item={item} onClose={onClose} />
        </DialogContent>
      )}
    </Dialog>
  );
}
