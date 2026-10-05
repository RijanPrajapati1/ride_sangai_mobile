'use client';

import { useState } from 'react';
import { CalendarRange, GalleryHorizontalEnd, Link2, Pencil, Plus, Trash2 } from 'lucide-react';
import { Badge, type BadgeTone } from '@/shared/ui/badge';
import { Button } from '@/shared/ui/button';
import { Card } from '@/shared/ui/card';
import { Skeleton } from '@/shared/ui/skeleton';
import { Switch } from '@/shared/ui/switch';
import { PageHeader } from '@/shared/layout/page-header';
import { ConfirmDialog } from '@/shared/components/confirm-dialog';
import { EmptyState, ErrorState } from '@/shared/components/states';
import { formatDateTime } from '@/shared/lib/format';
import { useBanners, useRemoveBanner, useToggleBanner } from '../application/use-banners';
import { bannerState, type Banner, type BannerState } from '../domain/banner';
import { BannerFormDialog } from './banner-form-dialog';
import { BannerPreview } from './banner-preview';

const STATE: Record<BannerState, { label: string; tone: BadgeTone }> = {
  live: { label: 'Live', tone: 'success' },
  scheduled: { label: 'Scheduled', tone: 'info' },
  ended: { label: 'Ended', tone: 'neutral' },
  inactive: { label: 'Paused', tone: 'neutral' },
};

function schedule(b: Banner) {
  if (!b.startsAt && !b.endsAt) return 'Always on';
  if (b.startsAt && b.endsAt) return `${formatDateTime(b.startsAt)} → ${formatDateTime(b.endsAt)}`;
  if (b.startsAt) return `From ${formatDateTime(b.startsAt)}`;
  return `Until ${formatDateTime(b.endsAt)}`;
}

function BannerCard({ banner, onEdit, onDelete }: { banner: Banner; onEdit: () => void; onDelete: () => void }) {
  const toggle = useToggleBanner();
  const state = STATE[bannerState(banner)];
  return (
    <Card className="flex flex-col overflow-hidden">
      <div className="p-3 pb-0">
        <BannerPreview {...banner} className={banner.isActive ? undefined : 'opacity-60 grayscale-[40%]'} />
      </div>
      <div className="flex flex-1 flex-col gap-2.5 p-4">
        <div className="flex items-center gap-2">
          <Badge tone={state.tone}>{state.label}</Badge>
          <span className="text-xs text-muted">Order {banner.sortOrder}</span>
          <div className="ml-auto flex items-center gap-2">
            <span className="text-xs text-muted">{banner.isActive ? 'Active' : 'Off'}</span>
            <Switch
              checked={banner.isActive}
              disabled={toggle.isPending}
              onCheckedChange={() => toggle.mutate(banner)}
              aria-label={banner.isActive ? 'Pause banner' : 'Activate banner'}
            />
          </div>
        </div>
        <div className="flex items-start gap-1.5 text-xs text-muted">
          <CalendarRange className="mt-px size-3.5 shrink-0" /> {schedule(banner)}
        </div>
        {banner.ctaUrl && (
          <div className="flex items-start gap-1.5 text-xs text-muted">
            <Link2 className="mt-px size-3.5 shrink-0" /> <span className="truncate">{banner.ctaUrl}</span>
          </div>
        )}
        <div className="mt-auto flex gap-2 pt-1">
          <Button variant="secondary" size="sm" onClick={onEdit} className="flex-1">
            <Pencil /> Edit
          </Button>
          <Button variant="danger-ghost" size="sm" onClick={onDelete} aria-label={`Delete ${banner.title}`}>
            <Trash2 /> Delete
          </Button>
        </div>
      </div>
    </Card>
  );
}

export function BannersScreen() {
  const banners = useBanners();
  const remove = useRemoveBanner();
  const [editing, setEditing] = useState<Banner | undefined>();
  const [formOpen, setFormOpen] = useState(false);
  const [deleting, setDeleting] = useState<Banner | null>(null);

  const openNew = () => {
    setEditing(undefined);
    setFormOpen(true);
  };

  return (
    <>
      <PageHeader
        title="Banners"
        description="Promotions shown on the home screen of the app."
        actions={
          <Button onClick={openNew}>
            <Plus /> New banner
          </Button>
        }
      />
      {banners.isPending ? (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 3 }, (_, i) => (
            <Card key={i} className="p-3">
              <Skeleton className="h-32 rounded-xl" />
              <div className="flex flex-col gap-2 p-1 pt-4">
                <Skeleton className="h-4 w-24" />
                <Skeleton className="h-3 w-40" />
                <Skeleton className="mt-2 h-8" />
              </div>
            </Card>
          ))}
        </div>
      ) : banners.isError ? (
        <Card>
          <ErrorState error={banners.error} onRetry={() => void banners.refetch()} />
        </Card>
      ) : banners.data.length === 0 ? (
        <Card>
          <EmptyState
            icon={GalleryHorizontalEnd}
            title="No banners yet"
            description="Create a banner to highlight a ride, a new feature or a seasonal campaign on the app's home screen."
            action={
              <Button onClick={openNew}>
                <Plus /> Create the first banner
              </Button>
            }
          />
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {banners.data.map((b) => (
            <BannerCard
              key={b.id}
              banner={b}
              onEdit={() => {
                setEditing(b);
                setFormOpen(true);
              }}
              onDelete={() => setDeleting(b)}
            />
          ))}
        </div>
      )}

      <BannerFormDialog open={formOpen} banner={editing} onOpenChange={setFormOpen} />
      <ConfirmDialog
        open={!!deleting}
        onOpenChange={(o) => !o && setDeleting(null)}
        title={`Delete “${deleting?.title ?? ''}”?`}
        description="The banner disappears from the app immediately. To hide it temporarily, pause it instead."
        loading={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting, { onSuccess: () => setDeleting(null) })}
      />
    </>
  );
}
