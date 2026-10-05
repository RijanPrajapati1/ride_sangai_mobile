import { z } from 'zod';
import { BANNER_CATEGORIES, type Banner, type BannerInput } from '../domain/banner';

const optionalUrl = z
  .string()
  .trim()
  .max(2048)
  .refine((v) => v === '' || /^(https?:\/\/|\/)/.test(v), 'Use an http(s) URL or an app path starting with /.');

/** Form values: everything is a string/boolean while editing. */
export const bannerFormSchema = z
  .object({
    title: z.string().trim().min(1, 'A title is required.').max(80, 'Keep the title under 80 characters.'),
    subtitle: z.string().trim().max(240, 'Keep the subtitle under 240 characters.'),
    category: z.enum([...BANNER_CATEGORIES, '']),
    ctaLabel: z.string().trim().max(40, 'Keep the button label under 40 characters.'),
    ctaUrl: optionalUrl,
    imageUrl: optionalUrl,
    icon: z.string().trim().max(64),
    theme: z.string().trim().max(32),
    sortOrder: z.coerce.number().int('Use a whole number.').min(-1000).max(1000),
    isActive: z.boolean(),
    startsAt: z.string(),
    endsAt: z.string(),
  })
  .refine((v) => !v.startsAt || !v.endsAt || new Date(v.startsAt) < new Date(v.endsAt), {
    message: 'The end must be after the start.',
    path: ['endsAt'],
  });

export type BannerFormValues = z.input<typeof bannerFormSchema>;

/** `datetime-local` value (local time) ↔ ISO string. */
function toLocalInput(iso: string | null): string {
  if (!iso) return '';
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function toFormValues(b?: Banner): BannerFormValues {
  return {
    title: b?.title ?? '',
    subtitle: b?.subtitle ?? '',
    category: b?.category ?? '',
    ctaLabel: b?.ctaLabel ?? '',
    ctaUrl: b?.ctaUrl ?? '',
    imageUrl: b?.imageUrl ?? '',
    icon: b?.icon ?? '',
    theme: b?.theme ?? '',
    sortOrder: b?.sortOrder ?? 0,
    isActive: b?.isActive ?? true,
    startsAt: toLocalInput(b?.startsAt ?? null),
    endsAt: toLocalInput(b?.endsAt ?? null),
  };
}

export function toBannerInput(v: z.output<typeof bannerFormSchema>): BannerInput {
  const orNull = (s: string) => (s.trim() === '' ? null : s.trim());
  return {
    title: v.title,
    subtitle: v.subtitle,
    category: v.category === '' ? null : v.category,
    ctaLabel: v.ctaLabel,
    ctaUrl: orNull(v.ctaUrl),
    imageUrl: orNull(v.imageUrl),
    icon: orNull(v.icon),
    theme: orNull(v.theme),
    sortOrder: v.sortOrder,
    isActive: v.isActive,
    startsAt: v.startsAt ? new Date(v.startsAt).toISOString() : null,
    endsAt: v.endsAt ? new Date(v.endsAt).toISOString() : null,
  };
}
