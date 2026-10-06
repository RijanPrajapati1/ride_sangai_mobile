'use client';

import { useState } from 'react';
import { cn } from '@/shared/lib/cn';
import { initials } from '@/shared/lib/format';

const TONES = [
  'bg-primary-soft text-primary-ink',
  'bg-accent-soft text-accent-ink',
  'bg-info-soft text-info-ink',
  'bg-warning-soft text-warning-ink',
  'bg-success-soft text-success-ink',
];

function toneFor(seed: string) {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  return TONES[h % TONES.length];
}

export function Avatar({
  name,
  src,
  size = 32,
  className,
}: {
  name: string;
  src?: string | null;
  size?: number;
  className?: string;
}) {
  const [failed, setFailed] = useState(false);
  const showImage = !!src && !failed && /^https?:\/\//.test(src);
  return (
    <span
      className={cn(
        'inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full font-semibold',
        !showImage && toneFor(name),
        className,
      )}
      style={{ width: size, height: size, fontSize: Math.max(10, Math.round(size * 0.38)) }}
      aria-hidden
    >
      {showImage ? (
        // eslint-disable-next-line @next/next/no-img-element -- remote avatars from any host
        <img src={src} alt="" className="size-full object-cover" onError={() => setFailed(true)} />
      ) : (
        initials(name)
      )}
    </span>
  );
}
