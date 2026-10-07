import { cn } from '@/shared/lib/cn';

export function BrandMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 64 64" className={cn('size-8', className)} aria-hidden>
      <rect width="64" height="64" rx="16" fill="#15897E" />
      <circle cx="20" cy="40" r="10" fill="none" stroke="#fff" strokeWidth="5" />
      <circle cx="44" cy="40" r="10" fill="none" stroke="#fff" strokeWidth="5" />
      <path
        d="M20 40l9-16h11l4 16M29 24l-3-6h-5"
        fill="none"
        stroke="#FF6B35"
        strokeWidth="5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function Brand({ subtitle = 'Superadmin' }: { subtitle?: string }) {
  return (
    <div className="flex items-center gap-2.5">
      <BrandMark />
      <div className="leading-tight">
        <div className="text-[15px] font-semibold tracking-tight text-foreground">Yatrix</div>
        <div className="text-[11px] font-medium tracking-wide text-muted uppercase">{subtitle}</div>
      </div>
    </div>
  );
}
