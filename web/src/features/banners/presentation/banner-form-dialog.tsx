'use client';

import { useState } from 'react';
import { Button } from '@/shared/ui/button';
import { Dialog, DialogBody, DialogContent, DialogFooter } from '@/shared/ui/dialog';
import { Field, Input, Select, Textarea } from '@/shared/ui/input';
import { Switch } from '@/shared/ui/switch';
import { humanize } from '@/shared/lib/format';
import { bannerFormSchema, toBannerInput, toFormValues, type BannerFormValues } from '../application/banner-form.schema';
import { useSaveBanner } from '../application/use-banners';
import { BANNER_CATEGORIES, type Banner } from '../domain/banner';
import { BannerPreview } from './banner-preview';

type Errors = Partial<Record<keyof BannerFormValues, string>>;

const THEMES = ['primary', 'accent', 'dark'];

function Err({ msg }: { msg?: string }) {
  return msg ? <span className="text-danger-ink">{msg}</span> : null;
}

function BannerForm({ banner, onDone }: { banner?: Banner; onDone: () => void }) {
  const [values, setValues] = useState<BannerFormValues>(() => toFormValues(banner));
  const [errors, setErrors] = useState<Errors>({});
  const save = useSaveBanner();
  const set = <K extends keyof BannerFormValues>(key: K, value: BannerFormValues[K]) => {
    setValues((v) => ({ ...v, [key]: value }));
    setErrors((e) => (e[key] ? { ...e, [key]: undefined } : e));
  };

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const parsed = bannerFormSchema.safeParse(values);
    if (!parsed.success) {
      const errs: Errors = {};
      for (const issue of parsed.error.issues) {
        const key = issue.path[0] as keyof BannerFormValues;
        errs[key] ??= issue.message;
      }
      setErrors(errs);
      return;
    }
    setErrors({});
    save.mutate({ id: banner?.id, input: toBannerInput(parsed.data) }, { onSuccess: onDone });
  };

  const preview = {
    title: values.title || 'Banner title',
    subtitle: values.subtitle,
    ctaLabel: values.ctaLabel,
    theme: values.theme || null,
    imageUrl: values.imageUrl || null,
    category: values.category || null,
  };

  return (
    <form onSubmit={submit} noValidate className="flex min-h-0 flex-1 flex-col">
      <DialogBody className="flex flex-col gap-4">
        <BannerPreview {...preview} />
        <Field label="Title" htmlFor="b-title" hint={<Err msg={errors.title} />}>
          <Input id="b-title" value={values.title} onChange={(e) => set('title', e.target.value)} maxLength={80} aria-invalid={!!errors.title} placeholder="Monsoon trails are open" />
        </Field>
        <Field label="Subtitle" htmlFor="b-subtitle" hint={<Err msg={errors.subtitle} />}>
          <Textarea id="b-subtitle" value={values.subtitle} onChange={(e) => set('subtitle', e.target.value)} maxLength={240} className="min-h-16" placeholder="Join a group ride this weekend and explore the valley." />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Category" htmlFor="b-category" hint="Show only on that activity's home tab.">
            <Select id="b-category" value={values.category} onChange={(e) => set('category', e.target.value as BannerFormValues['category'])}>
              <option value="">All activities</option>
              {BANNER_CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {humanize(c)}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Theme" htmlFor="b-theme" hint={<Err msg={errors.theme} />}>
            <Input id="b-theme" list="banner-themes" value={values.theme} onChange={(e) => set('theme', e.target.value)} maxLength={32} placeholder="primary" />
            <datalist id="banner-themes">
              {THEMES.map((t) => (
                <option key={t} value={t} />
              ))}
            </datalist>
          </Field>
          <Field label="Button label" htmlFor="b-cta" hint={<Err msg={errors.ctaLabel} />}>
            <Input id="b-cta" value={values.ctaLabel} onChange={(e) => set('ctaLabel', e.target.value)} maxLength={40} placeholder="Find a ride" />
          </Field>
          <Field label="Button link" htmlFor="b-url" hint={<Err msg={errors.ctaUrl} />}>
            <Input id="b-url" value={values.ctaUrl} onChange={(e) => set('ctaUrl', e.target.value)} placeholder="/rides or https://…" aria-invalid={!!errors.ctaUrl} />
          </Field>
          <Field label="Image URL" htmlFor="b-image" hint={<Err msg={errors.imageUrl} />} className="sm:col-span-2">
            <Input id="b-image" value={values.imageUrl} onChange={(e) => set('imageUrl', e.target.value)} placeholder="https://…" aria-invalid={!!errors.imageUrl} />
          </Field>
          <Field label="Icon" htmlFor="b-icon" hint="Material icon name, e.g. group_add.">
            <Input id="b-icon" value={values.icon} onChange={(e) => set('icon', e.target.value)} maxLength={64} placeholder="directions_bike" />
          </Field>
          <Field label="Sort order" htmlFor="b-sort" hint={errors.sortOrder ? <Err msg={errors.sortOrder} /> : 'Lower numbers show first.'}>
            <Input
              id="b-sort"
              type="number"
              min={-1000}
              max={1000}
              step={1}
              value={String(values.sortOrder)}
              onChange={(e) => set('sortOrder', e.target.value)}
              aria-invalid={!!errors.sortOrder}
            />
          </Field>
          <Field label="Starts" htmlFor="b-start" hint="Optional. Your local time.">
            <Input id="b-start" type="datetime-local" value={values.startsAt} onChange={(e) => set('startsAt', e.target.value)} />
          </Field>
          <Field label="Ends" htmlFor="b-end" hint={errors.endsAt ? <Err msg={errors.endsAt} /> : 'Optional.'}>
            <Input id="b-end" type="datetime-local" value={values.endsAt} onChange={(e) => set('endsAt', e.target.value)} aria-invalid={!!errors.endsAt} />
          </Field>
        </div>
        <label className="flex items-center justify-between gap-4 rounded-lg border border-border bg-surface-2/50 px-3.5 py-3">
          <span>
            <span className="block text-sm font-medium">Active</span>
            <span className="block text-xs text-muted">Inactive banners are never shown in the app.</span>
          </span>
          <Switch checked={values.isActive} onCheckedChange={(c) => set('isActive', c)} aria-label="Active" />
        </label>
      </DialogBody>
      <DialogFooter>
        <Button type="button" variant="secondary" onClick={onDone} disabled={save.isPending}>
          Cancel
        </Button>
        <Button type="submit" loading={save.isPending}>
          {banner ? 'Save changes' : 'Create banner'}
        </Button>
      </DialogFooter>
    </form>
  );
}

export function BannerFormDialog({
  open,
  banner,
  onOpenChange,
}: {
  open: boolean;
  banner?: Banner;
  onOpenChange: (open: boolean) => void;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      {open && (
        <DialogContent
          title={banner ? 'Edit banner' : 'New banner'}
          description="Banners appear on the home screen of the Yatrix app."
          className="max-w-2xl"
        >
          <BannerForm key={banner?.id ?? 'new'} banner={banner} onDone={() => onOpenChange(false)} />
        </DialogContent>
      )}
    </Dialog>
  );
}
