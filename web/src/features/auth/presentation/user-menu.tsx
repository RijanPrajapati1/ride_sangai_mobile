'use client';

import { ChevronDown, LogOut, ShieldCheck } from 'lucide-react';
import { Avatar } from '@/shared/ui/avatar';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/shared/ui/dropdown-menu';
import { Skeleton } from '@/shared/ui/skeleton';
import { useCurrentUser, useLogout } from '../application/use-auth';

export function UserMenu() {
  const { data: user } = useCurrentUser();
  const logout = useLogout();

  if (!user) return <Skeleton className="h-9 w-9 rounded-full sm:w-40" />;

  return (
    <DropdownMenu>
      <DropdownMenuTrigger className="flex items-center gap-2 rounded-full py-1 pr-2 pl-1 outline-none transition hover:bg-surface-2 data-[state=open]:bg-surface-2 sm:rounded-lg">
        <Avatar name={user.name} src={user.avatarUrl} size={30} />
        <span className="hidden max-w-36 truncate text-sm font-medium sm:block">{user.name}</span>
        <ChevronDown className="hidden size-4 text-muted sm:block" />
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-64">
        <DropdownMenuLabel>
          <div className="flex items-center gap-3">
            <Avatar name={user.name} src={user.avatarUrl} size={36} />
            <div className="min-w-0">
              <div className="truncate text-sm font-semibold">{user.name}</div>
              <div className="truncate text-xs text-muted">{user.email}</div>
            </div>
          </div>
          <div className="mt-2.5 inline-flex items-center gap-1 rounded-full bg-primary-soft px-2 py-0.5 text-xs font-medium text-primary-ink">
            <ShieldCheck className="size-3" /> Superadmin
          </div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem destructive disabled={logout.isPending} onSelect={() => logout.mutate()}>
          <LogOut /> {logout.isPending ? 'Signing out…' : 'Sign out'}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
