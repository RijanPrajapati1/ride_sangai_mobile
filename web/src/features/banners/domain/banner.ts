export const BANNER_CATEGORIES = ['cycling', 'trekking', 'hiking', 'riding'] as const;
export type BannerCategory = (typeof BANNER_CATEGORIES)[number];

/** A home-screen banner (`GET /superadmin/banners`). */
export interface Banner {
  id: string;
  category: BannerCategory | null;
  title: string;
  subtitle: string;
  ctaLabel: string;
  ctaUrl: string | null;
  imageUrl: string | null;
  icon: string | null;
  theme: string | null;
  sortOrder: number;
  isActive: boolean;
  startsAt: string | null;
  endsAt: string | null;
}

/** Body for `POST /superadmin/banners` / `PATCH /superadmin/banners/:id`. */
export type BannerInput = Omit<Banner, 'id'>;

export type BannerState = 'live' | 'scheduled' | 'ended' | 'inactive';

export function bannerState(b: Banner, now = Date.now()): BannerState {
  if (!b.isActive) return 'inactive';
  if (b.startsAt && Date.parse(b.startsAt) > now) return 'scheduled';
  if (b.endsAt && Date.parse(b.endsAt) <= now) return 'ended';
  return 'live';
}
