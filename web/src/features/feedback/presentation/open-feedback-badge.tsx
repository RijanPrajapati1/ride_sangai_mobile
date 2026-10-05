'use client';

import { useFeedbackCounts } from '../application/use-feedback';

/** Sidebar badge with the number of open feedback items. */
export function OpenFeedbackBadge() {
  const { data } = useFeedbackCounts();
  if (!data?.open) return null;
  return (
    <span className="tabular rounded-full bg-accent px-1.5 text-[11px] leading-5 font-semibold text-white">
      {data.open > 99 ? '99+' : data.open}
    </span>
  );
}
