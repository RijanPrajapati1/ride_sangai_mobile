import { Star } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/card';
import { Skeleton } from '@/shared/ui/skeleton';
import { formatNumber } from '@/shared/lib/format';

export function RatingCard({
  average,
  count,
  loading,
}: {
  average: number | null | undefined;
  count: number | undefined;
  loading: boolean;
}) {
  return (
    <Card className="flex flex-col">
      <CardHeader title="Feedback rating" description="Average of rated feedback, all time" />
      <div className="flex flex-1 flex-col items-center justify-center gap-3 px-5 py-6">
        {loading && average === undefined ? (
          <Skeleton className="h-14 w-28" />
        ) : average == null ? (
          <>
            <div className="flex gap-1" aria-hidden>
              {Array.from({ length: 5 }, (_, i) => (
                <Star key={i} className="size-6 text-border-strong" />
              ))}
            </div>
            <p className="text-sm text-muted">No ratings yet</p>
          </>
        ) : (
          <>
            <div className="flex items-baseline gap-1">
              <span className="text-5xl font-semibold tracking-tight">{average.toFixed(1)}</span>
              <span className="text-lg text-muted">/ 5</span>
            </div>
            <div className="flex gap-1" role="img" aria-label={`${average.toFixed(1)} out of 5 stars`}>
              {Array.from({ length: 5 }, (_, i) => {
                const fill = Math.max(0, Math.min(1, average - i));
                return (
                  <span key={i} className="relative size-6">
                    <Star className="absolute inset-0 size-6 text-border-strong" />
                    <span className="absolute inset-0 overflow-hidden" style={{ width: `${fill * 100}%` }}>
                      <Star className="size-6 fill-[#FFB020] text-[#FFB020]" />
                    </span>
                  </span>
                );
              })}
            </div>
            <p className="text-sm text-muted">
              from <span className="tabular font-medium text-foreground">{formatNumber(count ?? 0)}</span> rated{' '}
              {count === 1 ? 'response' : 'responses'}
            </p>
          </>
        )}
      </div>
    </Card>
  );
}
