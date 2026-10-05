import { Activity } from 'lucide-react';
import { Skeleton } from '@/shared/ui/skeleton';
import { formatCompact, formatNumber } from '@/shared/lib/format';

export function ActiveUsersCard({
  data,
  loading,
}: {
  data: { last24Hours: number; last7Days: number; last30Days: number } | undefined;
  loading: boolean;
}) {
  const cells = [
    { label: '24 hours', value: data?.last24Hours },
    { label: '7 days', value: data?.last7Days },
    { label: '30 days', value: data?.last30Days },
  ];
  return (
    <div className="flex flex-col gap-3 rounded-xl border border-border bg-surface p-4 shadow-card sm:col-span-2">
      <div className="flex items-center justify-between gap-2">
        <span className="text-[13px] font-medium text-muted">Active riders</span>
        <span className="flex size-8 items-center justify-center rounded-lg bg-success-soft text-success-ink">
          <Activity className="size-4" />
        </span>
      </div>
      <div className="grid grid-cols-3 divide-x divide-border">
        {cells.map((c) => (
          <div key={c.label} className="px-3 first:pl-0 last:pr-0">
            {loading || c.value === undefined ? (
              <Skeleton className="h-8 w-14" />
            ) : (
              <div className="text-[28px] leading-none font-semibold tracking-tight" title={formatNumber(c.value)}>
                {formatCompact(c.value)}
              </div>
            )}
            <div className="mt-2 text-xs text-muted">{c.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
