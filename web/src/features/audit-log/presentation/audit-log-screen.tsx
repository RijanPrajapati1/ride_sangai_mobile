'use client';

import {
  Ban,
  Bike,
  CircleCheck,
  FileClock,
  KeyRound,
  LogOut,
  MapPin,
  Megaphone,
  MessageCircle,
  MessageSquareText,
  Newspaper,
  PencilLine,
  ShieldCheck,
  Star,
  Trash2,
  UserRoundPen,
  UserRoundX,
  UsersRound,
  XCircle,
} from 'lucide-react';
import { Card } from '@/shared/ui/card';
import { Skeleton } from '@/shared/ui/skeleton';
import { PageHeader } from '@/shared/layout/page-header';
import { EmptyState, ErrorState, LoadMore } from '@/shared/components/states';
import { formatDateTime, humanize, timeAgo } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { useAuditLog } from '../application/use-audit-log';
import type { AuditEntry } from '../domain/audit-entry';

type Details = Record<string, unknown>;

const ACTIONS: Record<string, { icon: React.ComponentType<{ className?: string }>; tone: string; describe: (d: Details) => string }> = {
  'user.setRole': {
    icon: ShieldCheck,
    tone: 'bg-primary-soft text-primary-ink',
    describe: (d) => (d.role === 'superadmin' ? 'promoted a rider to superadmin' : 'changed a superadmin back to rider'),
  },
  'user.remove': {
    icon: UserRoundX,
    tone: 'bg-danger-soft text-danger-ink',
    describe: (d) => `removed the account of ${typeof d.name === 'string' ? d.name : 'a rider'}`,
  },
  'post.delete': { icon: Newspaper, tone: 'bg-danger-soft text-danger-ink', describe: () => 'removed a post' },
  'ride.delete': {
    icon: Bike,
    tone: 'bg-danger-soft text-danger-ink',
    describe: (d) => `removed the ride ${typeof d.title === 'string' ? `“${d.title}”` : ''}`,
  },
  'place.delete': {
    icon: MapPin,
    tone: 'bg-danger-soft text-danger-ink',
    describe: (d) => `removed the place ${typeof d.name === 'string' ? `“${d.name}”` : ''}`,
  },
  'group.delete': {
    icon: UsersRound,
    tone: 'bg-danger-soft text-danger-ink',
    describe: (d) => `removed the group ${typeof d.name === 'string' ? `“${d.name}”` : ''}`,
  },
  'feedback.update': {
    icon: PencilLine,
    tone: 'bg-info-soft text-info-ink',
    describe: (d) => {
      const parts: string[] = [];
      if (typeof d.status === 'string') parts.push(`marked feedback as ${humanize(d.status).toLowerCase()}`);
      if (d.noteChanged) parts.push(parts.length ? 'updated its note' : 'updated a feedback note');
      return parts.join(' and ') || 'updated feedback';
    },
  },
  'feedback.remove': { icon: MessageSquareText, tone: 'bg-danger-soft text-danger-ink', describe: () => 'deleted a feedback message' },
  'user.update': {
    icon: UserRoundPen,
    tone: 'bg-info-soft text-info-ink',
    describe: (d) => `edited ${name(d, 'a rider')}’s profile${typeof d.fields === 'string' ? ` (${d.fields})` : ''}`,
  },
  'user.disable': {
    icon: Ban,
    tone: 'bg-danger-soft text-danger-ink',
    describe: (d) => `disabled ${name(d, 'an account')}${typeof d.reason === 'string' ? ` — ${d.reason}` : ''}`,
  },
  'user.enable': { icon: CircleCheck, tone: 'bg-success-soft text-success-ink', describe: (d) => `re-enabled ${name(d, 'an account')}` },
  'user.signOut': { icon: LogOut, tone: 'bg-info-soft text-info-ink', describe: (d) => `signed ${name(d, 'a rider')} out everywhere` },
  'user.setPassword': { icon: KeyRound, tone: 'bg-warning-soft text-warning-ink', describe: (d) => `set a new password for ${name(d, 'a rider')}` },
  'ride.update': { icon: Bike, tone: 'bg-info-soft text-info-ink', describe: (d) => `edited the ride ${quoted(d.title)}` },
  'post.update': { icon: Newspaper, tone: 'bg-info-soft text-info-ink', describe: () => 'edited a post' },
  'place.update': { icon: MapPin, tone: 'bg-info-soft text-info-ink', describe: (d) => `edited the place ${quoted(d.name)}` },
  'group.update': { icon: UsersRound, tone: 'bg-info-soft text-info-ink', describe: (d) => `edited the group ${quoted(d.name)}` },
  'comment.delete': { icon: MessageCircle, tone: 'bg-danger-soft text-danger-ink', describe: () => 'removed a comment' },
  'review.delete': {
    icon: Star,
    tone: 'bg-danger-soft text-danger-ink',
    describe: (d) => `removed a ${typeof d.rating === 'number' ? `${d.rating}-star ` : ''}review of ${quoted(d.place)}`,
  },
  'rideRequest.approved': { icon: CircleCheck, tone: 'bg-success-soft text-success-ink', describe: () => 'approved a join request' },
  'rideRequest.declined': { icon: XCircle, tone: 'bg-warning-soft text-warning-ink', describe: () => 'declined a join request' },
  'announcement.send': {
    icon: Megaphone,
    tone: 'bg-accent-soft text-accent-ink',
    describe: (d) =>
      `sent the announcement ${quoted(d.title)}${typeof d.recipients === 'number' ? ` to ${d.recipients} riders` : ''}`,
  },
};

function name(d: Details, fallback: string) {
  return typeof d.name === 'string' ? d.name : fallback;
}

function quoted(value: unknown) {
  return typeof value === 'string' ? `“${value}”` : '';
}

function describe(e: AuditEntry) {
  const details = (e.details && typeof e.details === 'object' ? e.details : {}) as Details;
  const known = ACTIONS[e.action];
  return {
    icon: known?.icon ?? Trash2,
    tone: known?.tone ?? 'bg-surface-3 text-muted',
    text: known ? known.describe(details).trim() : `${humanize(e.action.replace('.', ' '))} (${e.targetType})`,
    excerpt:
      (e.action === 'post.delete' || e.action === 'post.update' || e.action === 'review.delete') && typeof details.text === 'string'
        ? details.text
        : null,
  };
}

function dayLabel(iso: string) {
  const d = new Date(iso);
  const today = new Date();
  const yesterday = new Date(Date.now() - 86_400_000);
  if (d.toDateString() === today.toDateString()) return 'Today';
  if (d.toDateString() === yesterday.toDateString()) return 'Yesterday';
  return d.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' });
}

export function AuditLogScreen() {
  const list = useAuditLog();
  const groups: { day: string; entries: AuditEntry[] }[] = [];
  for (const e of list.items) {
    const day = dayLabel(e.createdAt);
    const last = groups[groups.length - 1];
    if (last?.day === day) last.entries.push(e);
    else groups.push({ day, entries: [e] });
  }

  return (
    <>
      <PageHeader title="Audit log" description="Every moderation action taken by the superadmin team, newest first." />
      <Card className="overflow-hidden">
        {list.isLoading ? (
          <div className="flex flex-col gap-5 p-5">
            {Array.from({ length: 6 }, (_, i) => (
              <div key={i} className="flex gap-3">
                <Skeleton className="size-9 rounded-full" />
                <div className="flex flex-1 flex-col gap-2">
                  <Skeleton className="h-3.5 w-72 max-w-full" />
                  <Skeleton className="h-3 w-32" />
                </div>
              </div>
            ))}
          </div>
        ) : list.isError ? (
          <ErrorState error={list.error} onRetry={() => void list.refetch()} />
        ) : list.items.length === 0 ? (
          <EmptyState
            icon={FileClock}
            title="No moderation activity yet"
            description="Role changes, removals and feedback updates are recorded here automatically."
          />
        ) : (
          <>
            <div className="px-4 py-2 sm:px-5">
              {groups.map((g) => (
                <section key={g.day} className="py-3">
                  <h2 className="mb-2 text-xs font-semibold tracking-wider text-subtle uppercase">{g.day}</h2>
                  <ol className="relative">
                    {g.entries.map((e, i) => {
                      const d = describe(e);
                      const Icon = d.icon;
                      return (
                        <li key={e.id} className="relative flex gap-3 pb-4 last:pb-1">
                          {i < g.entries.length - 1 && (
                            <span aria-hidden className="absolute top-10 bottom-0 left-[17px] w-px bg-border" />
                          )}
                          <span className={cn('relative flex size-9 shrink-0 items-center justify-center rounded-full', d.tone)}>
                            <Icon className="size-4" />
                          </span>
                          <div className="min-w-0 flex-1 pt-1">
                            <p className="text-sm text-foreground">
                              <span className="font-semibold">{e.actorName ?? 'A removed superadmin'}</span> {d.text}
                            </p>
                            {d.excerpt && (
                              <p className="mt-1 line-clamp-2 border-l-2 border-border pl-2 text-[13px] text-muted italic">{d.excerpt}</p>
                            )}
                            <p className="mt-0.5 text-xs text-subtle" title={formatDateTime(e.createdAt)}>
                              {timeAgo(e.createdAt)} · <code className="font-mono text-[11px]">{e.action}</code>
                            </p>
                          </div>
                        </li>
                      );
                    })}
                  </ol>
                </section>
              ))}
            </div>
            <LoadMore count={list.items.length} hasMore={list.hasMore} loading={list.isLoadingMore} onClick={list.loadMore} noun="entries" />
          </>
        )}
      </Card>
    </>
  );
}
