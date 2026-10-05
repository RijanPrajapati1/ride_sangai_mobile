'use client';

import { MapPin, Star, Trash2 } from 'lucide-react';
import { Badge } from '@/shared/ui/badge';
import { Button } from '@/shared/ui/button';
import { TD, TH, THead, TR, Table } from '@/shared/components/data-table';
import { UserCell } from '@/shared/components/user-cell';
import { formatDate, formatNumber, humanize } from '@/shared/lib/format';
import { usePlaces } from '../application/use-content';
import type { Place } from '../domain/place';
import { ListCard } from './list-card';
import { Thumb } from './thumb';
import { useRemoveFlow } from './use-remove-flow';

export function PlacesScreen() {
  const list = usePlaces();
  const remove = useRemoveFlow<Place>('place', (p) => ({
    title: `Remove “${p.name}”?`,
    description: 'The place, its photos and all its reviews will be deleted. This can’t be undone.',
  }));

  return (
    <>
      <ListCard
        list={list}
        noun="places"
        empty={{ icon: MapPin, title: 'No places shared yet', description: 'Viewpoints, trails and cafés riders share in Explore will appear here.' }}
      >
        <Table>
          <THead>
            <tr>
              <TH>Place</TH>
              <TH>Category</TH>
              <TH className="text-right">Rating</TH>
              <TH className="hidden text-right md:table-cell">Saves</TH>
              <TH className="hidden lg:table-cell">Shared by</TH>
              <TH className="w-12">
                <span className="sr-only">Actions</span>
              </TH>
            </tr>
          </THead>
          <tbody>
            {list.items.map((p) => (
              <TR key={p.id}>
                <TD className="min-w-60">
                  <div className="flex items-center gap-3">
                    <Thumb src={p.coverImageUrl} className="size-10" fallback={MapPin} />
                    <div className="min-w-0">
                      <div className="truncate font-medium">{p.name}</div>
                      <div className="truncate text-xs text-muted">{p.locationName}</div>
                    </div>
                  </div>
                </TD>
                <TD>
                  <Badge tone="info">{humanize(p.category)}</Badge>
                  {p.activities.length > 0 && (
                    <div className="mt-1 text-xs text-muted">{p.activities.map(humanize).join(', ')}</div>
                  )}
                </TD>
                <TD className="tabular text-right whitespace-nowrap">
                  {p.averageRating == null ? (
                    <span className="text-subtle">No reviews</span>
                  ) : (
                    <span className="inline-flex items-center gap-1">
                      <Star className="size-3.5 fill-[#FFB020] text-[#FFB020]" />
                      {p.averageRating.toFixed(1)}
                      <span className="text-xs text-muted">({formatNumber(p.reviewCount)})</span>
                    </span>
                  )}
                </TD>
                <TD className="tabular hidden text-right text-muted md:table-cell">{formatNumber(p.saveCount)}</TD>
                <TD className="hidden lg:table-cell">
                  <UserCell name={p.authorName} avatarUrl={p.authorAvatarUrl} size={26} secondary={formatDate(p.createdAt)} />
                </TD>
                <TD className="text-right">
                  <Button variant="ghost" size="icon-sm" onClick={() => remove.ask(p)} aria-label={`Remove ${p.name}`} className="hover:text-danger-ink">
                    <Trash2 />
                  </Button>
                </TD>
              </TR>
            ))}
          </tbody>
        </Table>
      </ListCard>
      {remove.dialog}
    </>
  );
}
