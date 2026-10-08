'use client';

import { useState } from 'react';
import { Bike, Pencil, Trash2 } from 'lucide-react';
import { Badge, type BadgeTone } from '@/shared/ui/badge';
import { DropdownMenuItem, DropdownMenuSeparator } from '@/shared/ui/dropdown-menu';
import { TD, TH, THead, TR, Table } from '@/shared/components/data-table';
import { RowActions } from '@/shared/components/row-actions';
import { SearchInput } from '@/shared/components/search-input';
import { Segmented } from '@/shared/components/segmented';
import { UserCell } from '@/shared/components/user-cell';
import { formatDateTime, formatDuration, humanize } from '@/shared/lib/format';
import { useDebouncedValue } from '@/shared/lib/use-debounced-value';
import { cn } from '@/shared/lib/cn';
import { useRides } from '../application/use-content';
import type { Ride, RideDifficulty, RideWhen } from '../domain/ride';
import { EditContentDialog, type FieldSpec } from './edit-content-dialog';
import { ListCard } from './list-card';
import { useRemoveFlow } from './use-remove-flow';

const DIFFICULTY_TONE: Record<RideDifficulty, BadgeTone> = { easy: 'success', moderate: 'warning', hard: 'danger' };

const RIDE_FIELDS: FieldSpec[] = [
  { key: 'title', label: 'Title', kind: 'text', max: 120, required: true },
  { key: 'description', label: 'Description', kind: 'textarea', max: 5000, required: true },
  { key: 'meetingPoint', label: 'Meeting point', kind: 'text', max: 200, required: true, half: true },
  { key: 'date', label: 'Starts', kind: 'datetime', half: true, hint: 'In your time zone.' },
  {
    key: 'difficulty',
    label: 'Difficulty',
    kind: 'select',
    half: true,
    options: (['easy', 'moderate', 'hard'] as const).map((d) => ({ value: d, label: humanize(d) })),
  },
  { key: 'maxParticipants', label: 'Max riders', kind: 'number', min: 2, max: 1000, integer: true, half: true, hint: 'Includes the organizer.' },
  { key: 'distanceKm', label: 'Distance (km)', kind: 'number', min: 0.1, max: 10000, half: true },
  { key: 'durationMinutes', label: 'Duration (minutes)', kind: 'number', min: 1, max: 43200, integer: true, half: true },
];

export function RidesScreen() {
  const [when, setWhen] = useState<RideWhen>('all');
  const [search, setSearch] = useState('');
  const q = useDebouncedValue(search, 300);
  const list = useRides(when, q);
  const remove = useRemoveFlow<Ride>('ride', (r) => ({
    title: `Remove “${r.title}”?`,
    description: `The ride is cancelled and its ${r.participantCount - 1 > 0 ? `${r.participantCount - 1} participant(s) are` : 'participants are'} notified. This can't be undone.`,
  }));
  const [now] = useState(() => Date.now());
  const [editing, setEditing] = useState<Ride | null>(null);

  return (
    <>
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <Segmented
          ariaLabel="When"
          value={when}
          onChange={setWhen}
          options={[
            { value: 'all', label: 'All' },
            { value: 'upcoming', label: 'Upcoming' },
            { value: 'past', label: 'Past' },
          ]}
        />
        <SearchInput value={search} onChange={setSearch} placeholder="Search title or meeting point" className="w-full sm:ml-auto sm:w-72" />
      </div>
      <ListCard
        list={list}
        noun="rides"
        empty={{
          icon: Bike,
          title: q ? 'No matching rides' : when === 'upcoming' ? 'No upcoming rides' : when === 'past' ? 'No past rides' : 'No rides yet',
          description: q ? 'Try a different search.' : 'Rides organized in the app will appear here.',
        }}
      >
        <Table>
          <THead>
            <tr>
              <TH>Ride</TH>
              <TH>Category</TH>
              <TH className="hidden md:table-cell">Starts</TH>
              <TH className="hidden lg:table-cell">Organizer</TH>
              <TH className="text-right">Riders</TH>
              <TH className="w-12">
                <span className="sr-only">Actions</span>
              </TH>
            </tr>
          </THead>
          <tbody>
            {list.items.map((r) => {
              const past = Date.parse(r.date) < now;
              return (
                <TR key={r.id}>
                  <TD className="min-w-60">
                    <div className="font-medium">{r.title}</div>
                    <div className="mt-0.5 text-xs text-muted">
                      {r.meetingPoint} · {r.distanceKm} km · {formatDuration(r.durationMinutes)}
                    </div>
                  </TD>
                  <TD>
                    <div className="flex flex-wrap gap-1">
                      <Badge tone="primary">{humanize(r.category)}</Badge>
                      <Badge tone={DIFFICULTY_TONE[r.difficulty]}>{humanize(r.difficulty)}</Badge>
                    </div>
                    <div className="mt-1 text-xs text-muted">{humanize(r.rideType)}</div>
                  </TD>
                  <TD className="hidden whitespace-nowrap md:table-cell">
                    <div className={cn(past && 'text-muted')}>{formatDateTime(r.date)}</div>
                    {past && <div className="text-xs text-subtle">Already started</div>}
                  </TD>
                  <TD className="hidden lg:table-cell">
                    <UserCell name={r.organizerName} avatarUrl={r.organizerAvatarUrl} size={26} />
                  </TD>
                  <TD className="tabular text-right whitespace-nowrap">
                    {r.participantCount}/{r.maxParticipants}
                    {r.isFull && (
                      <Badge tone="accent" className="ml-1.5">
                        Full
                      </Badge>
                    )}
                  </TD>
                  <TD className="text-right">
                    <RowActions label={`Actions for ${r.title}`}>
                      <DropdownMenuItem onSelect={() => setEditing(r)}>
                        <Pencil /> Edit ride
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem destructive onSelect={() => remove.ask(r)}>
                        <Trash2 /> Remove ride
                      </DropdownMenuItem>
                    </RowActions>
                  </TD>
                </TR>
              );
            })}
          </tbody>
        </Table>
      </ListCard>
      {remove.dialog}
      <EditContentDialog
        kind="ride"
        item={editing}
        title={`Edit “${editing?.title ?? ''}”`}
        description="Riders who joined or asked to join are notified of what changed."
        fields={RIDE_FIELDS}
        onClose={() => setEditing(null)}
      />
    </>
  );
}
