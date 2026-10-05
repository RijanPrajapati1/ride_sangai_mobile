'use client';

/**
 * Composition root for the signed-in area: wires feature entry points into the
 * shared app shell. Navigation only — no business logic.
 */
import {
  FileClock,
  GalleryHorizontalEnd,
  LayoutDashboard,
  Layers,
  MessageSquareText,
  Trophy,
  UsersRound,
} from 'lucide-react';
import { UserMenu } from '@/features/auth';
import { OpenFeedbackBadge } from '@/features/feedback';
import { AppShell, type NavSection } from '@/shared/layout/app-shell';

const SECTIONS: NavSection[] = [
  {
    items: [{ href: '/', label: 'Overview', icon: LayoutDashboard }],
  },
  {
    title: 'Community',
    items: [
      { href: '/users', label: 'Users', icon: UsersRound },
      { href: '/top-users', label: 'Top riders', icon: Trophy },
      { href: '/content/posts', label: 'Content', icon: Layers, match: '/content' },
      { href: '/feedback', label: 'Feedback', icon: MessageSquareText, badge: <OpenFeedbackBadge /> },
    ],
  },
  {
    title: 'Platform',
    items: [
      { href: '/banners', label: 'Banners', icon: GalleryHorizontalEnd },
      { href: '/audit-log', label: 'Audit log', icon: FileClock },
    ],
  },
];

export function DashboardShell({ children }: { children: React.ReactNode }) {
  return (
    <AppShell sections={SECTIONS} userMenu={<UserMenu />}>
      {children}
    </AppShell>
  );
}
