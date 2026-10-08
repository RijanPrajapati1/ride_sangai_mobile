'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Ban, CircleCheck, KeyRound, LogOut, Pencil, ShieldCheck, ShieldOff, Trash2, UserRound } from 'lucide-react';
import { DropdownMenuItem, DropdownMenuSeparator } from '@/shared/ui/dropdown-menu';
import { ConfirmDialog } from '@/shared/components/confirm-dialog';
import { useEnableUser, useRemoveUser, useSetRole, useSignOutUser } from '../application/use-users';
import type { ManagedUser } from '../domain/user';
import { DisableUserDialog, EditUserDialog, SetPasswordDialog } from './user-dialogs';

type Action = 'edit' | 'disable' | 'enable' | 'signOut' | 'password' | 'promote' | 'demote' | 'remove';

/**
 * Everything a superadmin can do to an account, as menu items plus the dialogs
 * they open. Shared by the users table and the user page so both stay in sync.
 * Render `dialogs` once; call `menuItems(user)` inside a dropdown.
 */
export function useUserActions({ afterRemove }: { afterRemove?: () => void } = {}) {
  const [pending, setPending] = useState<{ action: Action; user: ManagedUser } | null>(null);
  const setRole = useSetRole();
  const remove = useRemoveUser();
  const enable = useEnableUser();
  const signOut = useSignOutUser();
  const router = useRouter();
  const close = () => setPending(null);
  const is = (action: Action) => (pending?.action === action ? pending.user : null);
  const ask = (action: Action, user: ManagedUser) => setPending({ action, user });

  const menuItems = (u: ManagedUser, { showView = true } = {}) => {
    const isAdmin = u.role === 'superadmin';
    return (
      <>
        {showView && (
          <DropdownMenuItem asChild>
            <Link href={`/users/${u.id}`}>
              <UserRound /> View details
            </Link>
          </DropdownMenuItem>
        )}
        <DropdownMenuItem onSelect={() => ask('edit', u)}>
          <Pencil /> Edit profile
        </DropdownMenuItem>
        <DropdownMenuItem onSelect={() => ask('password', u)}>
          <KeyRound /> Set new password
        </DropdownMenuItem>
        <DropdownMenuItem onSelect={() => ask('signOut', u)}>
          <LogOut /> Sign out everywhere
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        {isAdmin ? (
          <DropdownMenuItem onSelect={() => ask('demote', u)}>
            <ShieldOff /> Remove superadmin role
          </DropdownMenuItem>
        ) : (
          <DropdownMenuItem onSelect={() => ask('promote', u)} disabled={!!u.disabledAt}>
            <ShieldCheck /> Make superadmin
          </DropdownMenuItem>
        )}
        {u.disabledAt ? (
          <DropdownMenuItem onSelect={() => ask('enable', u)}>
            <CircleCheck /> Enable account
          </DropdownMenuItem>
        ) : (
          <DropdownMenuItem destructive disabled={isAdmin} onSelect={() => ask('disable', u)}>
            <Ban /> {isAdmin ? 'Demote before disabling' : 'Disable account'}
          </DropdownMenuItem>
        )}
        <DropdownMenuItem destructive disabled={isAdmin} onSelect={() => ask('remove', u)}>
          <Trash2 /> {isAdmin ? 'Demote before removing' : 'Remove account'}
        </DropdownMenuItem>
      </>
    );
  };

  const promote = is('promote');
  const demote = is('demote');
  const toRemove = is('remove');
  const toEnable = is('enable');
  const toSignOut = is('signOut');

  const dialogs = (
    <>
      <EditUserDialog user={is('edit')} onClose={close} />
      <DisableUserDialog user={is('disable')} onClose={close} />
      <SetPasswordDialog user={is('password')} onClose={close} />
      <ConfirmDialog
        open={!!promote || !!demote}
        onOpenChange={(o) => !o && close()}
        destructive={!!demote}
        title={promote ? `Make ${promote.name} a superadmin?` : `Remove ${demote?.name ?? ''}’s superadmin role?`}
        description={
          promote
            ? 'They will be able to sign in to this dashboard and use every power in it, including managing other users.'
            : 'They will lose access to this dashboard and become a regular rider.'
        }
        confirmLabel={promote ? 'Make superadmin' : 'Demote'}
        loading={setRole.isPending}
        onConfirm={() => {
          const user = promote ?? demote;
          if (user) setRole.mutate({ user, role: promote ? 'superadmin' : 'user' }, { onSuccess: close });
        }}
      />
      <ConfirmDialog
        open={!!toEnable}
        onOpenChange={(o) => !o && close()}
        destructive={false}
        title={`Enable ${toEnable?.name ?? ''}?`}
        description="They will be able to sign in to the app again."
        confirmLabel="Enable account"
        loading={enable.isPending}
        onConfirm={() => toEnable && enable.mutate(toEnable, { onSuccess: close })}
      />
      <ConfirmDialog
        open={!!toSignOut}
        onOpenChange={(o) => !o && close()}
        destructive={false}
        title={`Sign ${toSignOut?.name ?? ''} out everywhere?`}
        description="Every device they're signed in on is logged out. They can sign straight back in."
        confirmLabel="Sign out"
        loading={signOut.isPending}
        onConfirm={() => toSignOut && signOut.mutate(toSignOut, { onSuccess: close })}
      />
      <ConfirmDialog
        open={!!toRemove}
        onOpenChange={(o) => !o && close()}
        title={`Remove ${toRemove?.name ?? 'this rider'}?`}
        description="This deletes the account and everything they own: rides, posts, places, groups and messages. This can't be undone. To only stop them signing in, disable the account instead."
        confirmLabel="Remove account"
        loading={remove.isPending}
        onConfirm={() =>
          toRemove &&
          remove.mutate(toRemove, {
            onSuccess: () => {
              close();
              if (afterRemove) afterRemove();
              else router.refresh();
            },
          })
        }
      />
    </>
  );

  return { menuItems, dialogs, ask };
}
