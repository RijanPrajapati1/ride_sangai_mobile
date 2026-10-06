'use client';

import { useState } from 'react';
import { ArrowRight } from 'lucide-react';
import { humanize } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

const THEME_BG: Record<string, string> = {
  primary: 'linear-gradient(135deg, #15897E 0%, #1FB6A8 100%)',
  accent: 'linear-gradient(135deg, #E85A28 0%, #FF6B35 100%)',
  dark: 'linear-gradient(135deg, #0E1518 0%, #233036 100%)',
};

/** Approximates how the banner looks in the app. */
export function BannerPreview({
  title,
  subtitle,
  ctaLabel,
  theme,
  imageUrl,
  category,
  className,
}: {
  title: string;
  subtitle: string;
  ctaLabel: string;
  theme: string | null;
  imageUrl: string | null;
  category: string | null;
  className?: string;
}) {
  const [imgFailed, setImgFailed] = useState(false);
  const showImage = !!imageUrl && !imgFailed && /^https?:\/\//.test(imageUrl);
  return (
    <div
      className={cn('relative isolate flex min-h-32 flex-col justify-end overflow-hidden rounded-xl p-4 text-white', className)}
      style={{ background: THEME_BG[theme ?? ''] ?? THEME_BG.primary }}
    >
      {showImage && (
        <>
          {/* eslint-disable-next-line @next/next/no-img-element -- remote banner image */}
          <img src={imageUrl} alt="" onError={() => setImgFailed(true)} className="absolute inset-0 -z-10 size-full object-cover" />
          <div className="absolute inset-0 -z-10 bg-gradient-to-t from-black/70 via-black/30 to-transparent" />
        </>
      )}
      {!showImage && (
        <svg aria-hidden className="absolute -right-6 -bottom-4 -z-10 h-28 w-56 text-white/10" viewBox="0 0 200 100">
          <path d="M0 100 L50 40 L80 70 L120 20 L160 60 L200 30 L200 100 Z" fill="currentColor" />
        </svg>
      )}
      {category && (
        <span className="mb-2 self-start rounded-full bg-white/20 px-2 py-0.5 text-[11px] font-medium backdrop-blur">
          {humanize(category)}
        </span>
      )}
      <div className="text-base leading-snug font-semibold">{title}</div>
      {subtitle && <div className="mt-1 line-clamp-2 text-[13px] text-white/85">{subtitle}</div>}
      {ctaLabel && (
        <span className="mt-3 inline-flex items-center gap-1 self-start rounded-full bg-white px-3 py-1 text-xs font-semibold text-[#16232B]">
          {ctaLabel} <ArrowRight className="size-3" />
        </span>
      )}
    </div>
  );
}
