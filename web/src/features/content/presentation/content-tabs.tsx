'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Bike, Hourglass, MapPin, MessageCircle, MessageSquareText, Newspaper, UsersRound } from 'lucide-react';
import { cn } from '@/shared/lib/cn';

const TABS = [
  { href: '/content/posts', label: 'Posts', icon: Newspaper },
  { href: '/content/comments', label: 'Comments', icon: MessageCircle },
  { href: '/content/rides', label: 'Rides', icon: Bike },
  { href: '/content/requests', label: 'Join requests', icon: Hourglass },
  { href: '/content/places', label: 'Places', icon: MapPin },
  { href: '/content/reviews', label: 'Reviews', icon: MessageSquareText },
  { href: '/content/groups', label: 'Groups', icon: UsersRound },
];

export function ContentTabs() {
  const pathname = usePathname();
  return (
    <nav aria-label="Content type" className="-mx-4 mb-5 overflow-x-auto px-4 sm:mx-0 sm:px-0">
      <div className="flex min-w-max gap-1 border-b border-border">
        {TABS.map((t) => {
          const active = pathname === t.href || pathname.startsWith(`${t.href}/`);
          const Icon = t.icon;
          return (
            <Link
              key={t.href}
              href={t.href}
              aria-current={active ? 'page' : undefined}
              className={cn(
                '-mb-px inline-flex h-10 items-center gap-2 border-b-2 px-3 text-sm font-medium transition-colors',
                active ? 'border-primary text-foreground' : 'border-transparent text-muted hover:text-foreground',
              )}
            >
              <Icon className={cn('size-4', active ? 'text-primary-ink' : 'text-subtle')} />
              {t.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

export function ContentHeader() {
  return (
    <div className="mb-4">
      <h1 className="text-[26px] leading-tight font-extrabold tracking-tight">Content</h1>
      <p className="mt-1 text-sm text-muted">
        Everything riders have shared. Edit or remove anything that breaks the community guidelines.
      </p>
    </div>
  );
}
