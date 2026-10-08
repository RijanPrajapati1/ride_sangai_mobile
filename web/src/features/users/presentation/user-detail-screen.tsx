'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Ban,
  Bike,
  CalendarDays,
  CircleCheck,
  Clock,
  Hourglass,
  Laptop,
  Lock,
  MapPin,
  MessageCircle,
  MoreHorizontal,
  Newspaper,
  Pencil,
  Smartphone,
  UserRoundX,
  UsersRound,
} from 'lucide-react';
import { ApiError } from '@/core/http/errors';
import { Avatar } from '@/shared/ui/avatar';
import { Badge } from '@/shared/ui/badge';
import { Button } from '@/shared/ui/button';
import { Card, CardHeader } from '@/shared/ui/card';
import { DropdownMenu, DropdownMenuContent, DropdownMenuTrigger } from '@/shared/ui/dropdown-menu';
import { Skeleton } from '@/shared/ui/skeleton';
import { EmptyState, ErrorState } from '@/shared/components/states';
import { formatDate, formatDateTime, formatNumber, humanize, timeAgo } from '@/shared/lib/format';
import { useUser } from '../application/use-users';
import type { UserDetail, UserSession } from '../domain/user';
import { useUserActions } from './user-actions';
import { UserStatusBadge } from './users-screen';

export function UserDetailScreen({ id }: { id: string }) {
  const query = useUser(id);
  const router = useRouter();
  const actions = useUserActions({ afterRemove: () => router.replace('/users') });

  return (
    <>
      <Link href="/users" className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-muted hover:text-foreground">
        <ArrowLeft className="size-4" /> Users
      </Link>
      {query.isPending ? (
        <DetailSkeleton />
      ) : query.isError ? (
        query.error instanceof ApiError && query.error.status === 404 ? (
          <Card>
            <EmptyState icon={UserRoundX} title="User not found" description="This account may have been removed." />
          </Card>
        ) : (
          <Card>
            <ErrorState error={query.error} onRetry={() => void query.refetch()} />
          </Card>
        )
      ) : (
        <Detail user={query.data} actions={actions} />
      )}
      {actions.dialogs}
    </>
  );
}

function Detail({ user, actions }: { user: UserDetail; actions: ReturnType<typeof useUserActions> }) {
  const a = user.activity;
  return (
    <div className="flex flex-col gap-5">
      <Card className="overflow-hidden">
        <div className="h-20 bg-gradient-to-r from-primary to-primary-hover" aria-hidden />
        <div className="flex flex-wrap items-start gap-4 px-5 pb-5 sm:items-end">
          <Avatar name={user.name} src={user.avatarUrl} size={88} className="-mt-11 ring-4 ring-surface" />
          <div className="min-w-0 flex-1 pt-3">
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="truncate text-2xl font-extrabold tracking-tight">{user.name}</h1>
              <UserStatusBadge user={user} />
              {user.isPrivate && (
                <Badge>
                  <Lock /> Private profile
                </Badge>
              )}
              {user.isMe && <Badge tone="primary">You</Badge>}
            </div>
            <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted">
              <span>{user.email}</span>
              {user.location && (
                <span className="inline-flex items-center gap-1">
                  <MapPin className="size-3.5" /> {user.location}
                </span>
              )}
              <span className="inline-flex items-center gap-1">
                <CalendarDays className="size-3.5" /> Joined {formatDate(user.createdAt)}
              </span>
              <span className="inline-flex items-center gap-1" title={formatDateTime(user.lastLoginAt)}>
                <Clock className="size-3.5" /> Last sign-in {timeAgo(user.lastLoginAt)}
              </span>
            </div>
          </div>
          {!user.isMe && (
            <div className="flex flex-wrap gap-2">
              <Button variant="secondary" onClick={() => actions.ask('edit', user)}>
                <Pencil /> Edit
              </Button>
              {user.disabledAt ? (
                <Button onClick={() => actions.ask('enable', user)}>
                  <CircleCheck /> Enable
                </Button>
              ) : (
                user.role === 'user' && (
                  <Button variant="danger-ghost" onClick={() => actions.ask('disable', user)}>
                    <Ban /> Disable
                  </Button>
                )
              )}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="secondary" size="icon" aria-label={`More actions for ${user.name}`}>
                    <MoreHorizontal />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">{actions.menuItems(user, { showView: false })}</DropdownMenuContent>
              </DropdownMenu>
            </div>
          )}
        </div>
      </Card>

      {user.disabledAt && (
        <div role="status" className="flex items-start gap-3 rounded-2xl border border-danger/30 bg-danger-soft px-4 py-3 text-sm text-danger-ink">
          <Ban className="mt-0.5 size-4 shrink-0" />
          <div>
            <div className="font-semibold">Disabled {timeAgo(user.disabledAt)}</div>
            <div className="mt-0.5">
              {user.disabledReason ? `Reason: ${user.disabledReason}` : 'No reason was recorded.'} They can&apos;t sign in until you
              enable the account.
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <Stat icon={Bike} label="Rides organized" value={a.ridesOrganized} />
        <Stat icon={CircleCheck} label="Rides joined" value={a.ridesJoined} />
        <Stat icon={Hourglass} label="Pending requests" value={a.pendingRequests} />
        <Stat icon={UsersRound} label="Followers" value={user.followersCount} hint={`Following ${formatNumber(user.followingCount)}`} />
        <Stat icon={Newspaper} label="Posts" value={a.posts} />
        <Stat icon={MessageCircle} label="Comments" value={a.comments} />
        <Stat icon={MapPin} label="Places shared" value={a.places} hint={`${formatNumber(a.reviews)} reviews written`} />
        <Stat icon={UsersRound} label="Groups owned" value={a.groupsOwned} hint={`Member of ${formatNumber(a.groupsJoined)}`} />
      </div>

      <div className="grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <Card>
          <CardHeader title="Profile" description="What other riders see in the app." />
          <dl className="grid gap-x-6 gap-y-4 px-5 pt-4 pb-5 sm:grid-cols-2">
            <Item label="Bio" className="sm:col-span-2">
              {user.bio || <span className="text-subtle">No bio yet</span>}
            </Item>
            <Item label="Experience">{humanize(user.experienceLevel)}</Item>
            <Item label="Preferred ride type">{humanize(user.preferredRideType)}</Item>
            <Item label="Interests" className="sm:col-span-2">
              {user.cyclingInterests.length ? (
                <div className="flex flex-wrap gap-1.5">
                  {user.cyclingInterests.map((i) => (
                    <Badge key={i} tone="neutral">
                      {i}
                    </Badge>
                  ))}
                </div>
              ) : (
                <span className="text-subtle">None listed</span>
              )}
            </Item>
          </dl>
        </Card>
        <Card>
          <CardHeader
            title="Signed-in devices"
            description={a.activeSessions ? `${a.activeSessions} active session${a.activeSessions === 1 ? '' : 's'}` : 'Not signed in anywhere'}
          />
          <ul className="flex flex-col gap-1 px-3 pt-3 pb-4">
            {user.sessions.length === 0 && <li className="px-2 py-3 text-sm text-subtle">No active sessions.</li>}
            {user.sessions.map((s) => (
              <SessionRow key={s.id} session={s} />
            ))}
          </ul>
        </Card>
      </div>
    </div>
  );
}

function Stat({
  icon: Icon,
  label,
  value,
  hint,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: number;
  hint?: string;
}) {
  return (
    <Card className="p-4">
      <div className="flex items-center justify-between">
        <span className="text-[13px] font-medium text-muted">{label}</span>
        <Icon className="size-4 text-primary-ink" />
      </div>
      <div className="tabular mt-2 text-2xl font-extrabold tracking-tight">{formatNumber(value)}</div>
      {hint && <div className="mt-0.5 text-xs text-subtle">{hint}</div>}
    </Card>
  );
}

function Item({ label, children, className }: { label: string; children: React.ReactNode; className?: string }) {
  return (
    <div className={className}>
      <dt className="text-xs font-semibold tracking-wide text-subtle uppercase">{label}</dt>
      <dd className="mt-1 text-sm leading-relaxed text-foreground">{children}</dd>
    </div>
  );
}

/** "Chrome on Android", "Yatrix app on iOS" — enough to tell devices apart. */
function describeAgent(agent: string | null): { label: string; mobile: boolean } {
  if (!agent) return { label: 'Unknown device', mobile: false };
  const os = /android/i.test(agent)
    ? 'Android'
    : /iphone|ipad|ios/i.test(agent)
      ? 'iOS'
      : /mac os/i.test(agent)
        ? 'macOS'
        : /windows/i.test(agent)
          ? 'Windows'
          : /linux/i.test(agent)
            ? 'Linux'
            : null;
  const app = /dart|dio|flutter/i.test(agent)
    ? 'Yatrix app'
    : /edg\//i.test(agent)
      ? 'Edge'
      : /chrome/i.test(agent)
        ? 'Chrome'
        : /firefox/i.test(agent)
          ? 'Firefox'
          : /safari/i.test(agent)
            ? 'Safari'
            : 'Browser';
  return { label: os ? `${app} on ${os}` : app, mobile: os === 'Android' || os === 'iOS' };
}

function SessionRow({ session }: { session: UserSession }) {
  const { label, mobile } = describeAgent(session.userAgent);
  const Icon = mobile ? Smartphone : Laptop;
  return (
    <li className="flex items-center gap-3 rounded-xl px-2 py-2.5 hover:bg-surface-2">
      <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-primary-soft text-primary-ink">
        <Icon className="size-4" />
      </span>
      <div className="min-w-0 flex-1">
        <div className="truncate text-sm font-semibold">{label}</div>
        <div className="truncate text-xs text-muted">
          {session.ip ?? 'Unknown IP'} · signed in {formatDate(session.createdAt)}
        </div>
      </div>
      <span className="shrink-0 text-xs text-subtle" title={formatDateTime(session.lastUsedAt)}>
        {timeAgo(session.lastUsedAt)}
      </span>
    </li>
  );
}

function DetailSkeleton() {
  return (
    <div className="flex flex-col gap-5">
      <Card className="overflow-hidden">
        <Skeleton className="h-20 rounded-none" />
        <div className="flex items-end gap-4 px-5 pb-5">
          <Skeleton className="-mt-11 size-[88px] rounded-full" />
          <div className="flex-1 space-y-2 pt-3">
            <Skeleton className="h-6 w-48" />
            <Skeleton className="h-4 w-72" />
          </div>
        </div>
      </Card>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {Array.from({ length: 8 }, (_, i) => (
          <Skeleton key={i} className="h-24 rounded-2xl" />
        ))}
      </div>
    </div>
  );
}
