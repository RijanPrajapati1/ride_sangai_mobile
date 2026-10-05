import { cn } from '@/shared/lib/cn';

const MEDALS = ['bg-[#FFE7A3] text-[#7A5300]', 'bg-[#E3E8EB] text-[#46555E]', 'bg-[#F6D9C4] text-[#7D4320]'];

export function RankBadge({ rank }: { rank: number }) {
  return (
    <span
      className={cn(
        'tabular inline-flex size-7 items-center justify-center rounded-full text-xs font-semibold',
        rank <= 3 ? MEDALS[rank - 1] : 'bg-surface-3 text-muted',
      )}
    >
      {rank}
    </span>
  );
}
