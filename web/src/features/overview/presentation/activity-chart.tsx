'use client';

import { useMemo, useState } from 'react';
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { LineChart as LineIcon } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/card';
import { Skeleton } from '@/shared/ui/skeleton';
import { Segmented } from '@/shared/components/segmented';
import { formatDay, formatDayLong, formatNumber } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import {
  ACTIVITY_LABELS,
  ACTIVITY_SERIES,
  ANALYTICS_WINDOWS,
  type ActivitySeries,
  type Analytics,
  type AnalyticsWindow,
} from '../domain/analytics';

/** Fixed slot per series: colour follows the entity, never its rank. */
const SERIES_COLOR: Record<ActivitySeries, string> = {
  signups: 'var(--series-1)',
  rides: 'var(--series-2)',
  posts: 'var(--series-3)',
  joinRequests: 'var(--series-4)',
  messages: 'var(--series-5)',
  comments: 'var(--series-6)',
  places: 'var(--series-7)',
  feedback: 'var(--series-8)',
};

const DEFAULT_SERIES: ActivitySeries[] = ['signups', 'rides', 'posts'];

interface TooltipPayload {
  dataKey: ActivitySeries;
  value: number;
  color: string;
}

function ChartTooltip({ active, payload, label }: { active?: boolean; payload?: TooltipPayload[]; label?: string }) {
  if (!active || !payload?.length || !label) return null;
  return (
    <div className="min-w-44 rounded-lg border border-border bg-surface px-3 py-2.5 text-xs shadow-pop">
      <div className="mb-1.5 font-medium text-foreground">{formatDayLong(label)}</div>
      <div className="flex flex-col gap-1">
        {payload.map((p) => (
          <div key={p.dataKey} className="flex items-center justify-between gap-4">
            <span className="flex items-center gap-1.5 text-muted">
              <span className="size-2 rounded-full" style={{ background: SERIES_COLOR[p.dataKey] }} />
              {ACTIVITY_LABELS[p.dataKey]}
            </span>
            <span className="tabular font-medium text-foreground">{formatNumber(p.value)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export function ActivityChart({
  data,
  loading,
  days,
  onDaysChange,
}: {
  data: Analytics | undefined;
  loading: boolean;
  days: AnalyticsWindow;
  onDaysChange: (d: AnalyticsWindow) => void;
}) {
  const [active, setActive] = useState<ActivitySeries[]>(DEFAULT_SERIES);
  const toggle = (s: ActivitySeries) =>
    setActive((cur) => (cur.includes(s) ? cur.filter((x) => x !== s) : [...cur, s]));

  const visible = ACTIVITY_SERIES.filter((s) => active.includes(s));
  const isEmpty = !!data && visible.every((s) => data.totals[s] === 0);
  const daily = useMemo(() => data?.daily ?? [], [data]);

  return (
    <Card className="flex flex-col">
      <CardHeader
        title="Activity"
        description={`Daily totals over the last ${days} days (UTC)`}
        action={
          <Segmented
            ariaLabel="Time window"
            size="sm"
            value={days}
            onChange={onDaysChange}
            options={ANALYTICS_WINDOWS.map((d) => ({ value: d, label: d === 365 ? '1y' : `${d}d` }))}
          />
        }
      />
      <div className="flex flex-wrap gap-1.5 px-5 pt-4" role="group" aria-label="Series">
        {ACTIVITY_SERIES.map((s) => {
          const on = active.includes(s);
          return (
            <button
              key={s}
              type="button"
              aria-pressed={on}
              onClick={() => toggle(s)}
              className={cn(
                'inline-flex h-7 items-center gap-1.5 rounded-full border px-2.5 text-xs font-medium transition',
                on ? 'border-border-strong bg-surface text-foreground shadow-card' : 'border-dashed border-border text-subtle hover:text-muted',
              )}
            >
              <span
                className="size-2 rounded-full"
                style={{ background: on ? SERIES_COLOR[s] : 'transparent', boxShadow: on ? undefined : `inset 0 0 0 1.5px ${SERIES_COLOR[s]}` }}
              />
              {ACTIVITY_LABELS[s]}
              {data && <span className="tabular text-muted">{formatNumber(data.totals[s])}</span>}
            </button>
          );
        })}
      </div>
      <div className="relative h-72 px-2 pt-4 pb-3 sm:px-3">
        {loading && !data ? (
          <Skeleton className="mx-3 h-full" />
        ) : (
          <>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={daily} margin={{ top: 8, right: 12, left: -12, bottom: 0 }}>
                <defs>
                  {ACTIVITY_SERIES.map((s) => (
                    <linearGradient key={s} id={`fill-${s}`} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={SERIES_COLOR[s]} stopOpacity={0.18} />
                      <stop offset="100%" stopColor={SERIES_COLOR[s]} stopOpacity={0} />
                    </linearGradient>
                  ))}
                </defs>
                <CartesianGrid vertical={false} stroke="var(--chart-grid)" />
                <XAxis
                  dataKey="date"
                  tickFormatter={formatDay}
                  tick={{ fill: 'var(--chart-axis)', fontSize: 11 }}
                  axisLine={{ stroke: 'var(--chart-grid)' }}
                  tickLine={false}
                  minTickGap={28}
                  tickMargin={8}
                />
                <YAxis
                  allowDecimals={false}
                  tick={{ fill: 'var(--chart-axis)', fontSize: 11 }}
                  axisLine={false}
                  tickLine={false}
                  width={44}
                  domain={[0, (max: number) => Math.max(4, max)]}
                />
                <Tooltip
                  content={<ChartTooltip />}
                  cursor={{ stroke: 'var(--border-strong)', strokeWidth: 1 }}
                  isAnimationActive={false}
                />
                {visible.map((s) => (
                  <Area
                    key={s}
                    type="monotone"
                    dataKey={s}
                    stroke={SERIES_COLOR[s]}
                    strokeWidth={2}
                    fill={`url(#fill-${s})`}
                    dot={false}
                    activeDot={{ r: 4, strokeWidth: 2, stroke: 'var(--surface)' }}
                    isAnimationActive={false}
                  />
                ))}
              </AreaChart>
            </ResponsiveContainer>
            {(isEmpty || visible.length === 0) && (
              <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                <div className="flex items-center gap-2 rounded-full border border-border bg-surface px-3.5 py-1.5 text-xs text-muted shadow-card">
                  <LineIcon className="size-3.5 text-primary-ink" />
                  {visible.length === 0
                    ? 'Pick a series above to plot it'
                    : `No ${visible.map((s) => ACTIVITY_LABELS[s].toLowerCase()).join(', ')} in this window yet`}
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </Card>
  );
}
