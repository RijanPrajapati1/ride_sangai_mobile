import { Bug, CheckCircle2, CircleDot, Heart, Lightbulb, Loader, MessageCircle, Star } from 'lucide-react';
import { Badge, type BadgeTone } from '@/shared/ui/badge';
import { cn } from '@/shared/lib/cn';
import { CATEGORY_LABELS, STATUS_LABELS, type FeedbackCategory, type FeedbackStatus } from '../domain/feedback';

const CATEGORY: Record<FeedbackCategory, { tone: BadgeTone; icon: React.ComponentType }> = {
  bug: { tone: 'danger', icon: Bug },
  idea: { tone: 'info', icon: Lightbulb },
  praise: { tone: 'success', icon: Heart },
  other: { tone: 'neutral', icon: MessageCircle },
};

const STATUS: Record<FeedbackStatus, { tone: BadgeTone; icon: React.ComponentType }> = {
  open: { tone: 'accent', icon: CircleDot },
  inProgress: { tone: 'warning', icon: Loader },
  resolved: { tone: 'success', icon: CheckCircle2 },
};

export function CategoryBadge({ category }: { category: FeedbackCategory }) {
  const { tone, icon: Icon } = CATEGORY[category];
  return (
    <Badge tone={tone}>
      <Icon /> {CATEGORY_LABELS[category]}
    </Badge>
  );
}

export function StatusBadge({ status }: { status: FeedbackStatus }) {
  const { tone, icon: Icon } = STATUS[status];
  return (
    <Badge tone={tone}>
      <Icon /> {STATUS_LABELS[status]}
    </Badge>
  );
}

export function Stars({ rating, className }: { rating: number | null; className?: string }) {
  if (rating == null) return null;
  return (
    <span className={cn('inline-flex items-center gap-0.5', className)} role="img" aria-label={`${rating} out of 5 stars`}>
      {Array.from({ length: 5 }, (_, i) => (
        <Star key={i} className={cn('size-3.5', i < rating ? 'fill-[#FFB020] text-[#FFB020]' : 'text-border-strong')} />
      ))}
    </span>
  );
}
