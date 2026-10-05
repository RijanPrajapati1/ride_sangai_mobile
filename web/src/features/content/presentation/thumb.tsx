'use client';

import { useState } from 'react';
import { ImageOff } from 'lucide-react';
import { cn } from '@/shared/lib/cn';

/** A small remote image with a graceful fallback. */
export function Thumb({
  src,
  className,
  fallback: Fallback = ImageOff,
}: {
  src: string | null | undefined;
  className?: string;
  fallback?: React.ComponentType<{ className?: string }>;
}) {
  const [failed, setFailed] = useState(false);
  const ok = !!src && !failed && /^https?:\/\//.test(src);
  return (
    <span className={cn('flex shrink-0 items-center justify-center overflow-hidden rounded-lg bg-surface-3 text-subtle', className)}>
      {ok ? (
        // eslint-disable-next-line @next/next/no-img-element -- user-uploaded images from any host
        <img src={src} alt="" className="size-full object-cover" onError={() => setFailed(true)} />
      ) : (
        <Fallback className="size-4" />
      )}
    </span>
  );
}
