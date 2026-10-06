'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import { Dialog as DialogPrimitive } from 'radix-ui';
import { Menu, X } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { cn } from '@/shared/lib/cn';
import { Brand } from './brand';
import { ThemeToggle } from './theme';

export interface NavItem {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  /** Also active for these path prefixes. */
  match?: string;
  badge?: React.ReactNode;
}

export interface NavSection {
  title?: string;
  items: NavItem[];
}

function isActive(pathname: string, item: NavItem) {
  if (item.href === '/') return pathname === '/';
  const base = item.match ?? item.href;
  return pathname === base || pathname.startsWith(`${base}/`);
}

function Nav({ sections, onNavigate }: { sections: NavSection[]; onNavigate?: () => void }) {
  const pathname = usePathname();
  return (
    <nav className="flex flex-col gap-5" aria-label="Main">
      {sections.map((section, i) => (
        <div key={section.title ?? i} className="flex flex-col gap-0.5">
          {section.title && (
            <div className="px-3 pb-1.5 text-[11px] font-semibold tracking-wider text-subtle uppercase">
              {section.title}
            </div>
          )}
          {section.items.map((item) => {
            const active = isActive(pathname, item);
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onNavigate}
                aria-current={active ? 'page' : undefined}
                className={cn(
                  'group flex h-9 items-center gap-3 rounded-lg px-3 text-sm font-medium transition-colors',
                  active
                    ? 'bg-primary-soft text-primary-ink'
                    : 'text-muted hover:bg-surface-2 hover:text-foreground',
                )}
              >
                <Icon className={cn('size-[18px] shrink-0', active ? 'text-primary-ink' : 'text-subtle group-hover:text-foreground')} />
                <span className="flex-1 truncate">{item.label}</span>
                {item.badge}
              </Link>
            );
          })}
        </div>
      ))}
    </nav>
  );
}

function SidebarFooter() {
  return (
    <div className="rounded-xl border border-border bg-surface-2/60 p-3 text-xs text-muted">
      <div className="font-medium text-foreground">Platform team only</div>
      Actions here are recorded in the audit log.
    </div>
  );
}

export function AppShell({
  sections,
  userMenu,
  children,
}: {
  sections: NavSection[];
  userMenu: React.ReactNode;
  children: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  return (
    <div className="min-h-dvh">
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r border-border bg-surface lg:flex">
        <div className="flex h-16 items-center px-5">
          <Link href="/" aria-label="Overview">
            <Brand />
          </Link>
        </div>
        <div className="flex-1 overflow-y-auto px-3 py-3">
          <Nav sections={sections} />
        </div>
        <div className="p-3">
          <SidebarFooter />
        </div>
      </aside>

      {/* Mobile drawer */}
      <DialogPrimitive.Root open={open} onOpenChange={setOpen}>
        <DialogPrimitive.Portal>
          <DialogPrimitive.Overlay className="fixed inset-0 z-40 bg-[#0b1215]/50 data-[state=open]:animate-fade-in lg:hidden" />
          <DialogPrimitive.Content className="fixed inset-y-0 left-0 z-50 flex w-[18rem] max-w-[85vw] flex-col border-r border-border bg-surface shadow-pop outline-none data-[state=open]:animate-slide-in-left lg:hidden">
            <DialogPrimitive.Title className="sr-only">Navigation</DialogPrimitive.Title>
            <DialogPrimitive.Description className="sr-only">Dashboard sections</DialogPrimitive.Description>
            <div className="flex h-16 items-center justify-between px-5">
              <Brand />
              <DialogPrimitive.Close asChild>
                <Button variant="ghost" size="icon-sm" aria-label="Close navigation">
                  <X />
                </Button>
              </DialogPrimitive.Close>
            </div>
            <div className="flex-1 overflow-y-auto px-3 py-3">
              <Nav sections={sections} onNavigate={() => setOpen(false)} />
            </div>
            <div className="p-3">
              <SidebarFooter />
            </div>
          </DialogPrimitive.Content>
        </DialogPrimitive.Portal>
      </DialogPrimitive.Root>

      <div className="lg:pl-64">
        <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-border bg-background/85 px-4 backdrop-blur-md sm:px-6 lg:px-8">
          <Button variant="ghost" size="icon" className="-ml-1 lg:hidden" onClick={() => setOpen(true)} aria-label="Open navigation">
            <Menu />
          </Button>
          <div className="lg:hidden">
            <Link href="/" aria-label="Overview" className="flex items-center gap-2 text-[15px] font-semibold">
              Ride Sangai
            </Link>
          </div>
          <div className="ml-auto flex items-center gap-1.5">
            <ThemeToggle />
            {userMenu}
          </div>
        </header>
        <main className="mx-auto w-full max-w-[1400px] px-4 py-6 sm:px-6 lg:px-8 lg:py-8">{children}</main>
      </div>
    </div>
  );
}
