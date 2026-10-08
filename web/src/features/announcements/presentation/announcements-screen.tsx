'use client';

import { useState } from 'react';
import { Megaphone, Send, UsersRound } from 'lucide-react';
import { useStats } from '@/features/overview';
import { Button } from '@/shared/ui/button';
import { Card, CardHeader } from '@/shared/ui/card';
import { Field, Input, Textarea } from '@/shared/ui/input';
import { PageHeader } from '@/shared/layout/page-header';
import { ConfirmDialog } from '@/shared/components/confirm-dialog';
import { EmptyState, ErrorState, LoadMore } from '@/shared/components/states';
import { formatDateTime, formatNumber, timeAgo } from '@/shared/lib/format';
import { useAnnouncements, useSendAnnouncement } from '../application/use-announcements';

const TITLE_MAX = 80;
const MESSAGE_MAX = 500;

function Counter({ value, max }: { value: string; max: number }) {
  return (
    <span className={value.length > max * 0.9 ? 'text-warning-ink' : undefined}>
      {value.length}/{max}
    </span>
  );
}

/** The notification as riders will see it in the app's inbox. */
function Preview({ title, message }: { title: string; message: string }) {
  return (
    <div className="rounded-2xl border border-border bg-surface-2 p-3">
      <div className="mb-2 text-[11px] font-semibold tracking-wider text-subtle uppercase">Preview in the app</div>
      <div className="flex gap-3 rounded-xl bg-surface p-3 shadow-card">
        <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-accent-soft text-accent-ink">
          <Megaphone className="size-5" />
        </span>
        <div className="min-w-0 flex-1">
          <div className="text-sm font-bold">{title.trim() || 'Your title'}</div>
          <p className="mt-0.5 text-[13px] leading-relaxed break-words whitespace-pre-wrap text-muted">
            {message.trim() || 'Your message to every rider.'}
          </p>
          <div className="mt-1 text-xs text-subtle">Just now</div>
        </div>
        <span className="mt-1 size-2 shrink-0 rounded-full bg-accent" aria-hidden />
      </div>
    </div>
  );
}

export function AnnouncementsScreen() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [confirming, setConfirming] = useState(false);
  const send = useSendAnnouncement();
  const stats = useStats();
  const history = useAnnouncements();
  const recipients = stats.data ? stats.data.riders - stats.data.disabledUsers : null;
  const ready = title.trim().length > 0 && message.trim().length > 0;

  return (
    <>
      <PageHeader
        title="Announcements"
        description="Send a message to every rider. It lands in their notifications in the app, and as a push where push is set up."
      />
      <div className="grid items-start gap-5 lg:grid-cols-[1.1fr_1fr]">
        <Card>
          <CardHeader title="New announcement" description="Keep it short and useful: events, safety notices, app news." />
          <form
            className="flex flex-col gap-4 px-5 pt-4 pb-5"
            onSubmit={(e) => {
              e.preventDefault();
              if (ready) setConfirming(true);
            }}
          >
            <Field label="Title" htmlFor="a-title" hint={<Counter value={title} max={TITLE_MAX} />}>
              <Input
                id="a-title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                maxLength={TITLE_MAX}
                placeholder="Dashain group rides are back"
              />
            </Field>
            <Field label="Message" htmlFor="a-message" hint={<Counter value={message} max={MESSAGE_MAX} />}>
              <Textarea
                id="a-message"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                maxLength={MESSAGE_MAX}
                className="min-h-28"
                placeholder="Join a festival ride this weekend. Check Rides in the app for times and meeting points."
              />
            </Field>
            <Preview title={title} message={message} />
            <div className="flex flex-wrap items-center justify-between gap-3">
              <span className="inline-flex items-center gap-1.5 text-sm text-muted">
                <UsersRound className="size-4" />
                {recipients === null ? 'Every active rider' : `${formatNumber(recipients)} active riders`}
              </span>
              <Button type="submit" disabled={!ready}>
                <Send /> Send announcement
              </Button>
            </div>
          </form>
        </Card>

        <Card className="overflow-hidden">
          <CardHeader title="Sent" description="Newest first." />
          <div className="mt-3">
            {history.isLoading ? (
              <div className="px-5 py-10 text-center text-sm text-muted">Loading…</div>
            ) : history.isError ? (
              <ErrorState error={history.error} onRetry={() => void history.refetch()} />
            ) : history.items.length === 0 ? (
              <EmptyState icon={Megaphone} title="Nothing sent yet" description="Announcements you send appear here." />
            ) : (
              <>
                <ul className="divide-y divide-border border-t border-border">
                  {history.items.map((a) => (
                    <li key={a.id} className="px-5 py-3.5">
                      <div className="text-sm font-bold">{a.details.title}</div>
                      <p className="mt-0.5 line-clamp-3 text-[13px] leading-relaxed text-muted">{a.details.message}</p>
                      <div className="mt-1.5 text-xs text-subtle" title={formatDateTime(a.createdAt)}>
                        {timeAgo(a.createdAt)} · by {a.actorName ?? 'a former superadmin'} ·{' '}
                        {formatNumber(a.details.recipients ?? 0)} riders
                      </div>
                    </li>
                  ))}
                </ul>
                <LoadMore
                  count={history.items.length}
                  hasMore={history.hasMore}
                  loading={history.isLoadingMore}
                  onClick={history.loadMore}
                  noun="announcements"
                />
              </>
            )}
          </div>
        </Card>
      </div>

      <ConfirmDialog
        open={confirming}
        onOpenChange={(o) => !o && setConfirming(false)}
        destructive={false}
        title="Send to every rider?"
        description={
          recipients === null
            ? 'Every active rider gets this in their notifications. It can’t be unsent.'
            : `${formatNumber(recipients)} active riders get this in their notifications. It can’t be unsent.`
        }
        confirmLabel="Send now"
        loading={send.isPending}
        onConfirm={() =>
          send.mutate(
            { title: title.trim(), message: message.trim() },
            {
              onSuccess: () => {
                setConfirming(false);
                setTitle('');
                setMessage('');
              },
            },
          )
        }
      />
    </>
  );
}
