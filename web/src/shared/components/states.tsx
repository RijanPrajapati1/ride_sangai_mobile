'use client';

import { AlertTriangle, RotateCw } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { errorMessage } from '@/core/http/errors';
import { cn } from '@/shared/lib/cn';

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
  className,
  compact,
}: {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description?: React.ReactNode;
  action?: React.ReactNode;
  className?: string;
  compact?: boolean;
}) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center px-6 text-center',
        compact ? 'py-8' : 'py-14',
        className,
      )}
    >
      <div className="relative mb-4">
        <div className="absolute inset-0 scale-150 rounded-full bg-primary-soft/60 blur-xl" aria-hidden />
        <div className="relative flex size-12 items-center justify-center rounded-2xl border border-border bg-surface text-primary-strong shadow-card">
          <Icon className="size-5" />
        </div>
      </div>
      <h3 className="text-[15px] font-semibold text-foreground">{title}</h3>
      {description && <p className="mt-1 max-w-sm text-sm text-muted">{description}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

export function ErrorState({ error, onRetry, className }: { error: unknown; onRetry?: () => void; className?: string }) {
  return (
    <div className={cn('flex flex-col items-center justify-center px-6 py-12 text-center', className)}>
      <div className="mb-3 flex size-11 items-center justify-center rounded-2xl bg-danger-soft text-danger-ink">
        <AlertTriangle className="size-5" />
      </div>
      <h3 className="text-[15px] font-semibold">Couldn&apos;t load this</h3>
      <p className="mt-1 max-w-sm text-sm text-muted">{errorMessage(error)}</p>
      {onRetry && (
        <Button variant="secondary" size="sm" className="mt-4" onClick={onRetry}>
          <RotateCw /> Try again
        </Button>
      )}
    </div>
  );
}

export function LoadMore({
  hasMore,
  loading,
  onClick,
  count,
  noun = 'items',
}: {
  hasMore: boolean;
  loading: boolean;
  onClick: () => void;
  count: number;
  noun?: string;
}) {
  if (count === 0) return null;
  return (
    <div className="flex items-center justify-between gap-3 border-t border-border px-4 py-3 text-[13px] text-muted">
      <span>
        Showing <span className="tabular font-medium text-foreground">{count}</span> {noun}
        {hasMore ? '' : ' · end of list'}
      </span>
      {hasMore && (
        <Button variant="secondary" size="sm" loading={loading} onClick={onClick}>
          Load more
        </Button>
      )}
    </div>
  );
}
