'use client';

import { useState } from 'react';
import { Check, CheckCircle2, Hourglass, X, XCircle } from 'lucide-react';
import { Badge, type BadgeTone } from '@/shared/ui/badge';
import { Button } from '@/shared/ui/button';
import { Dialog, DialogBody, DialogContent, DialogFooter } from '@/shared/ui/dialog';
import { Field, Textarea } from '@/shared/ui/input';
import { TD, TH, THead, TR, Table } from '@/shared/components/data-table';
import { Segmented } from '@/shared/components/segmented';
import { UserCell } from '@/shared/components/user-cell';
import { formatDate, formatDateTime, humanize, timeAgo } from '@/shared/lib/format';
import { useDecideRequest, useRideRequests } from '../application/use-content';
import { REQUEST_STATUSES, type RideRequest, type RideRequestStatus } from '../domain/ride-request';
import { ListCard } from './list-card';

const STATUS: Record<RideRequestStatus, { tone: BadgeTone; icon: React.ComponentType }> = {
  pending: { tone: 'warning', icon: Hourglass },
  approved: { tone: 'success', icon: CheckCircle2 },
  declined: { tone: 'danger', icon: XCircle },
};

export function RequestsScreen() {
  const [status, setStatus] = useState<RideRequestStatus | 'all'>('pending');
  const list = useRideRequests(status);
  const decide = useDecideRequest();
  const [declining, setDeclining] = useState<RideRequest | null>(null);

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
        <p className="text-xs text-muted">Organizers usually decide in the app; you can step in on any ride.</p>
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
              <TH className="text-right">
                <span className="sr-only">Actions</span>
              </TH>
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
                  <TD className="text-right whitespace-nowrap">
                    {r.status === 'pending' && (
                      <div className="inline-flex gap-1">
                        <Button
                          size="sm"
                          variant="soft"
                          loading={decide.isPending && decide.variables?.id === r.id && decide.variables.approve}
                          onClick={() => decide.mutate({ id: r.id, approve: true })}
                          aria-label={`Approve ${r.userName}`}
                        >
                          <Check /> <span className="hidden sm:inline">Approve</span>
                        </Button>
                        <Button size="sm" variant="danger-ghost" onClick={() => setDeclining(r)} aria-label={`Decline ${r.userName}`}>
                          <X /> <span className="hidden sm:inline">Decline</span>
                        </Button>
                      </div>
                    )}
                  </TD>
                </TR>
              );
            })}
          </tbody>
        </Table>
      </ListCard>
      <DeclineDialog request={declining} onClose={() => setDeclining(null)} />
    </>
  );
}

function DeclineDialog({ request, onClose }: { request: RideRequest | null; onClose: () => void }) {
  const decide = useDecideRequest();
  const [reason, setReason] = useState('');
  const close = () => {
    if (decide.isPending) return;
    setReason('');
    onClose();
  };
  return (
    <Dialog open={!!request} onOpenChange={(o) => !o && close()}>
      {request && (
        <DialogContent title={`Decline ${request.userName}?`} description={`They asked to join “${request.rideTitle}”.`}>
          <form
            className="flex min-h-0 flex-1 flex-col"
            onSubmit={(e) => {
              e.preventDefault();
              decide.mutate({ id: request.id, approve: false, reason: reason.trim() || null }, { onSuccess: close });
            }}
          >
            <DialogBody>
              <Field label="Reason" htmlFor="decline-reason" hint="Optional. Shared with the rider.">
                <Textarea
                  id="decline-reason"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  maxLength={500}
                  className="min-h-20"
                  placeholder="This ride is for advanced riders."
                  autoFocus
                />
              </Field>
            </DialogBody>
            <DialogFooter>
              <Button type="button" variant="secondary" onClick={close} disabled={decide.isPending}>
                Cancel
              </Button>
              <Button type="submit" variant="danger" loading={decide.isPending}>
                Decline request
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      )}
    </Dialog>
  );
}
