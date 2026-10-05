'use client';

import Link from 'next/link';
import { ArrowRight, Trophy } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/card';
import { Skeleton } from '@/shared/ui/skeleton';
import { EmptyState } from '@/shared/components/states';
import { UserCell } from '@/shared/components/user-cell';
import { formatNumber } from '@/shared/lib/format';
import { useTopUsers } from '../application/use-top-users';
import { RankBadge } from './rank-badge';

/** Overview card: the top five riders by rides joined. */
export function TopRidersPreview() {
  const { data, isPending } = useTopUsers('ridesJoined', 5);
  const items = (data ?? []).filter((u) => u.ridesJoined > 0 || u.ridesOrganized > 0);
  return (
    <Card className="flex flex-col">
      <CardHeader
        title="Top riders"
        description="Most rides joined"
        action={
          <Link href="/top-users" className="inline-flex items-center gap-1 text-[13px] font-medium text-primary-ink hover:underline">
            Leaderboard <ArrowRight className="size-3.5" />
          </Link>
        }
      />
      <div className="flex-1 px-2 pt-3 pb-2">
        {isPending ? (
          <div className="flex flex-col gap-3 px-3 py-2">
            {Array.from({ length: 5 }, (_, i) => (
              <Skeleton key={i} className="h-9" />
            ))}
          </div>
        ) : items.length === 0 ? (
          <EmptyState compact icon={Trophy} title="No rides joined yet" description="Riders who join rides will rank here." />
        ) : (
          <ul>
            {items.map((u) => (
              <li key={u.id} className="flex items-center gap-3 rounded-lg px-3 py-2 hover:bg-surface-2/60">
                <RankBadge rank={u.rank} />
                <UserCell name={u.name} avatarUrl={u.avatarUrl} secondary={`${formatNumber(u.followers)} followers`} className="flex-1" />
                <div className="text-right">
                  <div className="tabular text-sm font-semibold">{formatNumber(u.ridesJoined)}</div>
                  <div className="text-[11px] text-muted">joined</div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </Card>
  );
}
