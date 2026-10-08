'use client';

/**
 * The signed-in area's frame: sidebar sections, the user menu and the open
 * feedback badge, placed in the shared app shell. Navigation only.
 */
import {
  FileClock,
  GalleryHorizontalEnd,
  LayoutDashboard,
  Layers,
  Megaphone,
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
      { href: '/announcements', label: 'Announcements', icon: Megaphone },
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
