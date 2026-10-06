import { BarChart3 } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/card';
import { Skeleton } from '@/shared/ui/skeleton';
import { formatNumber, humanize } from '@/shared/lib/format';
import type { Breakdown } from '../domain/analytics';

/**
 * Horizontal bars for a categorical breakdown — one hue (magnitude), every
 * bar labelled with its name and value, so identity never rests on colour.
 */
export function BreakdownCard({
  title,
  description,
  data,
  loading,
  order,
  colorFor,
  emptyText,
}: {
  title: string;
  description?: string;
  data: Breakdown | undefined;
  loading: boolean;
  /** Fixed category order (keys missing from `data` show as 0). */
  order?: readonly string[];
  colorFor?: (key: string) => string;
  emptyText: string;
}) {
  const rows = order
    ? order.map((key) => ({ key, count: data?.find((d) => d.key === key)?.count ?? 0 }))
    : [...(data ?? [])].sort((a, b) => b.count - a.count);
  const total = rows.reduce((n, r) => n + r.count, 0);
  const max = Math.max(1, ...rows.map((r) => r.count));

  return (
    <Card className="flex flex-col">
      <CardHeader
        title={title}
        description={description}
        action={!loading && total > 0 ? <span className="tabular text-sm font-semibold">{formatNumber(total)}</span> : undefined}
      />
      <div className="flex flex-1 flex-col justify-center gap-3.5 px-5 pt-4 pb-5">
        {loading && !data ? (
          Array.from({ length: 4 }, (_, i) => <Skeleton key={i} className="h-7" />)
        ) : total === 0 ? (
          <div className="flex flex-col items-center gap-2 py-6 text-center">
            <BarChart3 className="size-5 text-subtle" />
            <p className="text-sm text-muted">{emptyText}</p>
          </div>
        ) : (
          rows.map((r) => (
            <div key={r.key} className="flex flex-col gap-1.5">
              <div className="flex items-baseline justify-between gap-2 text-[13px]">
                <span className="font-medium text-foreground">{humanize(r.key)}</span>
                <span className="tabular text-muted">
                  <span className="font-medium text-foreground">{formatNumber(r.count)}</span>
                  <span className="ml-1.5 text-xs">{Math.round((r.count / total) * 100)}%</span>
                </span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-surface-3">
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${(r.count / max) * 100}%`,
                    minWidth: r.count > 0 ? 6 : 0,
                    background: colorFor?.(r.key) ?? 'var(--primary)',
                  }}
                />
              </div>
            </div>
          ))
        )}
      </div>
    </Card>
  );
}
