'use client';

import { useState } from 'react';
import { CheckCircle2, Hourglass, XCircle } from 'lucide-react';
import { Badge, type BadgeTone } from '@/shared/ui/badge';
import { TD, TH, THead, TR, Table } from '@/shared/components/data-table';
import { Segmented } from '@/shared/components/segmented';
import { UserCell } from '@/shared/components/user-cell';
import { formatDate, formatDateTime, humanize, timeAgo } from '@/shared/lib/format';
import { useRideRequests } from '../application/use-content';
import { REQUEST_STATUSES, type RideRequestStatus } from '../domain/ride-request';
import { ListCard } from './list-card';

const STATUS: Record<RideRequestStatus, { tone: BadgeTone; icon: React.ComponentType }> = {
  pending: { tone: 'warning', icon: Hourglass },
  approved: { tone: 'success', icon: CheckCircle2 },
  declined: { tone: 'danger', icon: XCircle },
};

export function RequestsScreen() {
  const [status, setStatus] = useState<RideRequestStatus | 'all'>('pending');
  const list = useRideRequests(status);

  return (
    <>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <Segmented
          ariaLabel="Status"
          value={status}
          onChange={setStatus}
          options={[
            { value: 'all' as const, label: 'All' },
            ...REQUEST_STATUSES.map((s) => ({ value: s, label: humanize(s) })),
          ]}
        />
        <p className="text-xs text-muted">Organizers approve or decline requests in the app.</p>
      </div>
      <ListCard
        list={list}
        noun="requests"
        empty={{
          icon: Hourglass,
          title: status === 'pending' ? 'No pending requests' : status === 'all' ? 'No join requests yet' : `No ${status} requests`,
          description: 'When riders ask to join a ride, their requests show up here.',
        }}
      >
        <Table>
          <THead>
            <tr>
              <TH>Rider</TH>
              <TH>Ride</TH>
              <TH>Status</TH>
              <TH className="hidden md:table-cell">Requested</TH>
              <TH className="hidden lg:table-cell">Note</TH>
            </tr>
          </THead>
          <tbody>
            {list.items.map((r) => {
              const s = STATUS[r.status];
              const Icon = s.icon;
              return (
                <TR key={r.id}>
                  <TD className="min-w-48">
                    <UserCell name={r.userName} avatarUrl={r.userAvatarUrl} secondary={humanize(r.experienceLevel)} />
                  </TD>
                  <TD className="min-w-48">
                    <div className="font-medium">{r.rideTitle}</div>
                    <div className="text-xs text-muted">{formatDate(r.rideDate)}</div>
                  </TD>
                  <TD>
                    <Badge tone={s.tone}>
                      <Icon /> {humanize(r.status)}
                    </Badge>
                    {r.decidedAt && <div className="mt-1 text-xs text-subtle">{timeAgo(r.decidedAt)}</div>}
                  </TD>
                  <TD className="hidden whitespace-nowrap text-muted md:table-cell" title={formatDateTime(r.requestedAt)}>
                    {timeAgo(r.requestedAt)}
                  </TD>
                  <TD className="hidden max-w-72 text-[13px] text-muted lg:table-cell">
                    <span className="line-clamp-2">
                      {r.status === 'declined' && r.declineReason ? `Declined: ${r.declineReason}` : r.message || '—'}
                    </span>
                  </TD>
                </TR>
              );
            })}
          </tbody>
        </Table>
      </ListCard>
    </>
  );
}
