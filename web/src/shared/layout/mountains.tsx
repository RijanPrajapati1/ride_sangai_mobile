import { cn } from '@/shared/lib/cn';

// Same ridges as the app's MountainBackdrop, as (x, y) percentages of the band.
const FAR = '0,42 10,26 17,34 30,2 40,22 47,16 58,36 72,0 84,24 92,18 100,30';
const MID = '0,60 12,42 26,56 42,36 56,54 70,44 86,58 100,46';
const NEAR = '0,80 18,66 36,78 52,64 70,78 86,68 100,76';

/**
 * Layered translucent mountain ridges, the Yatrix motif. Fills its positioned
 * parent's bottom; set the band height with `className` (e.g. `h-1/2`).
 */
export function Mountains({ className, color = 'white' }: { className?: string; color?: string }) {
  return (
    <svg
      aria-hidden
      viewBox="0 0 100 100"
      preserveAspectRatio="none"
      className={cn('pointer-events-none absolute inset-x-0 bottom-0 w-full', className)}
    >
      <polygon points={`0,100 ${FAR} 100,100`} fill={color} fillOpacity={0.16} />
      <polygon points={`0,100 ${MID} 100,100`} fill={color} fillOpacity={0.22} />
      <polygon points={`0,100 ${NEAR} 100,100`} fill={color} fillOpacity={0.3} />
    </svg>
  );
}
