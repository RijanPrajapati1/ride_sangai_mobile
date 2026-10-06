import { Skeleton } from '@/shared/ui/skeleton';
import { formatCompact, formatNumber } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

export function KpiCard({
  label,
  value,
  icon: Icon,
  hint,
  tone = 'primary',
  loading,
}: {
  label: string;
  value: number | undefined;
  icon: React.ComponentType<{ className?: string }>;
  hint?: React.ReactNode;
  tone?: 'primary' | 'accent' | 'info' | 'warning' | 'neutral';
  loading?: boolean;
}) {
  const toneClass = {
    primary: 'bg-primary-soft text-primary-ink',
    accent: 'bg-accent-soft text-accent-ink',
    info: 'bg-info-soft text-info-ink',
    warning: 'bg-warning-soft text-warning-ink',
    neutral: 'bg-surface-3 text-muted',
  }[tone];
  return (
    <div className="flex flex-col gap-3 rounded-xl border border-border bg-surface p-4 shadow-card">
      <div className="flex items-center justify-between gap-2">
        <span className="text-[13px] font-medium text-muted">{label}</span>
        <span className={cn('flex size-8 items-center justify-center rounded-lg', toneClass)}>
          <Icon className="size-4" />
        </span>
      </div>
      {loading || value === undefined ? (
        <Skeleton className="h-8 w-20" />
      ) : (
        <div className="text-[28px] leading-none font-semibold tracking-tight" title={formatNumber(value)}>
          {formatCompact(value)}
        </div>
      )}
      <div className="min-h-4 text-xs text-muted">{loading ? <Skeleton className="h-3 w-24" /> : hint}</div>
    </div>
  );
}
