'use client';

import { useState } from 'react';
import { Trophy } from 'lucide-react';
import { Card } from '@/shared/ui/card';
import { Select } from '@/shared/ui/input';
import { PageHeader } from '@/shared/layout/page-header';
import { Segmented } from '@/shared/components/segmented';
import { EmptyState, ErrorState } from '@/shared/components/states';
import { TD, TH, THead, TR, Table, TableSkeleton } from '@/shared/components/data-table';
import { UserCell } from '@/shared/components/user-cell';
import { formatDate, formatNumber } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { useTopUsers } from '../application/use-top-users';
import { METRIC_LABELS, TOP_USER_METRICS, type TopUserMetric } from '../domain/top-user';
import { RankBadge } from './rank-badge';

const LIMITS = [10, 25, 50, 100];

export function TopUsersScreen() {
  const [metric, setMetric] = useState<TopUserMetric>('followers');
  const [limit, setLimit] = useState(25);
  const { data, isPending, isError, error, refetch, isFetching } = useTopUsers(metric, limit);
  const items = data ?? [];
  const leaderHasActivity = items.some((u) => u[metric] > 0);

  return (
    <>
      <PageHeader title="Top riders" description="The most active riders, ranked by the metric you choose." />
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <Segmented
          ariaLabel="Rank by"
          value={metric}
          onChange={setMetric}
          className="hidden md:inline-flex"
          options={TOP_USER_METRICS.map((m) => ({ value: m, label: METRIC_LABELS[m] }))}
        />
        <Select
          aria-label="Rank by"
          className="w-48 md:hidden"
          value={metric}
          onChange={(e) => setMetric(e.target.value as TopUserMetric)}
        >
          {TOP_USER_METRICS.map((m) => (
            <option key={m} value={m}>
              Rank by {METRIC_LABELS[m].toLowerCase()}
            </option>
          ))}
        </Select>
        <Select aria-label="How many" className="w-32" value={limit} onChange={(e) => setLimit(Number(e.target.value))}>
          {LIMITS.map((l) => (
            <option key={l} value={l}>
              Top {l}
            </option>
          ))}
        </Select>
      </div>
      <Card className={cn('overflow-hidden transition-opacity', isFetching && !isPending && 'opacity-70')}>
        {isPending ? (
          <TableSkeleton rows={8} columns={8} />
        ) : isError ? (
          <ErrorState error={error} onRetry={() => void refetch()} />
        ) : items.length === 0 || !leaderHasActivity ? (
          <EmptyState
            icon={Trophy}
            title="No leaders yet"
            description={`Once riders start ${metric === 'followers' ? 'following each other' : 'riding, posting and sharing places'}, the leaderboard fills up here.`}
          />
        ) : (
          <Table>
            <THead>
              <tr>
                <TH className="w-14">#</TH>
                <TH>Rider</TH>
                {TOP_USER_METRICS.map((m) => (
                  <TH
                    key={m}
                    className={cn('text-right', m === metric && 'text-primary-ink')}
                    aria-sort={m === metric ? 'descending' : undefined}
                  >
                    <button type="button" onClick={() => setMetric(m)} className="hover:text-foreground">
                      {METRIC_LABELS[m]}
                    </button>
                  </TH>
                ))}
                <TH>Joined</TH>
              </tr>
            </THead>
            <tbody>
              {items.map((u) => (
                <TR key={u.id}>
                  <TD>
                    <RankBadge rank={u.rank} />
                  </TD>
                  <TD className="min-w-56">
                    <UserCell name={u.name} avatarUrl={u.avatarUrl} secondary={u.email} />
                  </TD>
                  {TOP_USER_METRICS.map((m) => (
                    <TD
                      key={m}
                      className={cn(
                        'tabular text-right',
                        m === metric ? 'bg-primary-soft/40 font-semibold text-foreground' : 'text-muted',
                      )}
                    >
                      {formatNumber(u[m])}
                    </TD>
                  ))}
                  <TD className="whitespace-nowrap text-muted">{formatDate(u.joinedAt)}</TD>
                </TR>
              ))}
            </tbody>
          </Table>
        )}
      </Card>
    </>
  );
}
