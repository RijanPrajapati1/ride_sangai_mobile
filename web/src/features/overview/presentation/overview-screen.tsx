'use client';

import { useState } from 'react';
import {
  Bike,
  CalendarClock,
  Hourglass,
  MapPin,
  MessageSquareText,
  Newspaper,
  UsersRound,
  UserRoundPlus,
} from 'lucide-react';
import { PageHeader } from '@/shared/layout/page-header';
import { formatNumber } from '@/shared/lib/format';
import { RecentFeedbackPreview } from '@/features/feedback';
import { TopRidersPreview } from '@/features/top-users';
import { useAnalytics, useStats } from '../application/use-overview';
import type { AnalyticsWindow } from '../domain/analytics';
import { ActiveUsersCard } from './active-users-card';
import { ActivityChart } from './activity-chart';
import { BreakdownCard } from './breakdown-card';
import { KpiCard } from './kpi-card';
import { RatingCard } from './rating-card';

const STATUS_COLORS: Record<string, string> = {
  pending: 'var(--warning)',
  approved: 'var(--success)',
  declined: 'var(--danger)',
  open: 'var(--accent)',
  inProgress: 'var(--warning)',
  resolved: 'var(--success)',
};

export function OverviewScreen() {
  const [days, setDays] = useState<AnalyticsWindow>(30);
  const stats = useStats();
  const analytics = useAnalytics(days);
  const s = stats.data;
  const a = analytics.data;
  const openFeedback = a ? (a.feedbackByStatus.find((r) => r.key === 'open')?.count ?? 0) : undefined;
  const loadingStats = stats.isPending;
  const loadingAnalytics = analytics.isPending;

  return (
    <>
      <PageHeader
        title="Overview"
        description="How the Yatrix community is doing right now."
      />

      <section aria-label="Key numbers" className="grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3 xl:grid-cols-4">
        <KpiCard
          label="Riders"
          icon={UsersRound}
          value={s?.riders}
          loading={loadingStats}
          hint={s && (s.newRidersLast7Days > 0 ? <span className="text-success-ink">+{formatNumber(s.newRidersLast7Days)} this week</span> : 'No new riders this week')}
        />
        <KpiCard label="Rides" icon={Bike} value={s?.rides} loading={loadingStats} tone="info" hint={s && `${formatNumber(s.superadmins)} superadmin${s.superadmins === 1 ? '' : 's'} on the team`} />
        <KpiCard label="Upcoming rides" icon={CalendarClock} value={s?.upcomingRides} loading={loadingStats} tone="info" hint="Scheduled to start later" />
        <KpiCard
          label="Pending requests"
          icon={Hourglass}
          value={s?.pendingRequests}
          loading={loadingStats}
          tone={s && s.pendingRequests > 0 ? 'warning' : 'neutral'}
          hint="Waiting for an organizer"
        />
        <KpiCard label="Posts" icon={Newspaper} value={s?.posts} loading={loadingStats} tone="accent" hint={s && `${formatNumber(s.comments)} comments`} />
        <KpiCard label="Places" icon={MapPin} value={s?.places} loading={loadingStats} hint="Shared by riders" />
        <KpiCard label="Groups" icon={UserRoundPlus} value={s?.groups} loading={loadingStats} tone="info" hint="Rider communities" />
        <KpiCard
          label="Open feedback"
          icon={MessageSquareText}
          value={openFeedback}
          loading={loadingAnalytics}
          tone={openFeedback ? 'accent' : 'neutral'}
          hint={openFeedback ? 'Needs a reply' : 'All caught up'}
        />
      </section>

      <section className="mt-4 grid gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <ActivityChart data={a} loading={loadingAnalytics} days={days} onDaysChange={setDays} />
        </div>
        <div className="flex flex-col gap-4">
          <ActiveUsersCard data={a?.activeUsers} loading={loadingAnalytics} />
          <RatingCard average={a?.feedbackAverageRating} count={a?.feedbackRatings} loading={loadingAnalytics} />
        </div>
      </section>

      <section aria-label="Breakdowns" className="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <BreakdownCard
          title="Rides by category"
          description="All rides, all time"
          data={a?.ridesByCategory}
          loading={loadingAnalytics}
          order={['cycling', 'trekking', 'hiking', 'riding']}
          emptyText="No rides have been created yet."
        />
        <BreakdownCard
          title="Join requests by status"
          description="All requests, all time"
          data={a?.requestsByStatus}
          loading={loadingAnalytics}
          order={['pending', 'approved', 'declined']}
          colorFor={(k) => STATUS_COLORS[k] ?? 'var(--primary)'}
          emptyText="No one has asked to join a ride yet."
        />
        <BreakdownCard
          title="Feedback by status"
          description="All feedback, all time"
          data={a?.feedbackByStatus}
          loading={loadingAnalytics}
          order={['open', 'inProgress', 'resolved']}
          colorFor={(k) => STATUS_COLORS[k] ?? 'var(--primary)'}
          emptyText="No feedback has arrived yet."
        />
      </section>

      <section className="mt-4 grid gap-4 lg:grid-cols-2">
        <TopRidersPreview />
        <RecentFeedbackPreview />
      </section>
    </>
  );
}
