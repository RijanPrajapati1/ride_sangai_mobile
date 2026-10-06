'use client';

import { useState } from 'react';
import { ShieldCheck, ShieldOff, Trash2, UserRound, UsersRound } from 'lucide-react';
import { Badge } from '@/shared/ui/badge';
import { Card } from '@/shared/ui/card';
import { DropdownMenuItem, DropdownMenuSeparator } from '@/shared/ui/dropdown-menu';
import { PageHeader } from '@/shared/layout/page-header';
import { ConfirmDialog } from '@/shared/components/confirm-dialog';
import { TD, TH, THead, TR, Table, TableSkeleton } from '@/shared/components/data-table';
import { RowActions } from '@/shared/components/row-actions';
import { SearchInput } from '@/shared/components/search-input';
import { Segmented } from '@/shared/components/segmented';
import { EmptyState, ErrorState, LoadMore } from '@/shared/components/states';
import { UserCell } from '@/shared/components/user-cell';
import { formatDate, formatNumber, timeAgo } from '@/shared/lib/format';
import { useDebouncedValue } from '@/shared/lib/use-debounced-value';
import { useRemoveUser, useSetRole, useUsers } from '../application/use-users';
import type { ManagedUser, UserRole } from '../domain/user';

type PendingAction = { kind: 'role'; user: ManagedUser; role: UserRole } | { kind: 'remove'; user: ManagedUser };

export function UsersScreen() {
  const [role, setRole] = useState<UserRole>('user');
  const [search, setSearch] = useState('');
  const q = useDebouncedValue(search, 300);
  const list = useUsers({ role, q });
  const setRoleMutation = useSetRole();
  const removeMutation = useRemoveUser();
  const [pending, setPending] = useState<PendingAction | null>(null);

  const confirm = () => {
    if (!pending) return;
    const done = { onSuccess: () => setPending(null) };
    if (pending.kind === 'role') setRoleMutation.mutate({ user: pending.user, role: pending.role }, done);
    else removeMutation.mutate(pending.user, done);
  };

  return (
    <>
      <PageHeader title="Users" description="Everyone with a Ride Sangai account. Promote teammates or remove abusive accounts." />
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <Segmented
          ariaLabel="Role"
          value={role}
          onChange={setRole}
          options={[
            { value: 'user', label: 'Riders' },
            { value: 'superadmin', label: 'Superadmins' },
          ]}
        />
        <SearchInput value={search} onChange={setSearch} placeholder="Search name or email" className="w-full sm:ml-auto sm:w-72" />
      </div>

      <Card className="overflow-hidden">
        {list.isLoading ? (
          <TableSkeleton rows={8} columns={6} />
        ) : list.isError ? (
          <ErrorState error={list.error} onRetry={() => void list.refetch()} />
        ) : list.items.length === 0 ? (
          q ? (
            <EmptyState icon={UserRound} title="No matches" description={`Nobody matches “${q}”. Try part of a name or email.`} />
          ) : role === 'user' ? (
            <EmptyState icon={UsersRound} title="No riders yet" description="People who sign up in the Ride Sangai app will appear here." />
          ) : (
            <EmptyState icon={ShieldCheck} title="No superadmins" description="Promote a rider to give them access to this dashboard." />
          )
        ) : (
          <>
            <Table>
              <THead>
                <tr>
                  <TH>{role === 'user' ? 'Rider' : 'Superadmin'}</TH>
                  <TH className="hidden sm:table-cell">Role</TH>
                  <TH className="hidden md:table-cell">Joined</TH>
                  <TH className="hidden lg:table-cell">Last sign-in</TH>
                  <TH className="text-right">Followers</TH>
                  <TH className="hidden text-right sm:table-cell">Rides</TH>
                  <TH className="w-12">
                    <span className="sr-only">Actions</span>
                  </TH>
                </tr>
              </THead>
              <tbody>
                {list.items.map((u) => (
                  <TR key={u.id}>
                    <TD className="min-w-56">
                      <UserCell
                        name={u.name}
                        avatarUrl={u.avatarUrl}
                        secondary={u.email ?? '—'}
                        trailing={u.isMe && <Badge tone="primary">You</Badge>}
                      />
                    </TD>
                    <TD className="hidden sm:table-cell">
                      {u.role === 'superadmin' ? (
                        <Badge tone="primary">
                          <ShieldCheck /> Superadmin
                        </Badge>
                      ) : (
                        <Badge>Rider</Badge>
                      )}
                    </TD>
                    <TD className="hidden whitespace-nowrap text-muted md:table-cell">{formatDate(u.createdAt)}</TD>
                    <TD className="hidden whitespace-nowrap text-muted lg:table-cell" title={u.lastLoginAt ?? undefined}>
                      {timeAgo(u.lastLoginAt)}
                    </TD>
                    <TD className="tabular text-right">{formatNumber(u.followersCount)}</TD>
                    <TD className="tabular hidden text-right text-muted sm:table-cell">{formatNumber(u.totalRides)}</TD>
                    <TD className="text-right">
                      {u.isMe ? (
                        <span className="text-xs text-subtle" title="You can't change your own account here">
                          —
                        </span>
                      ) : (
                        <RowActions label={`Actions for ${u.name}`}>
                          {u.role === 'user' ? (
                            <DropdownMenuItem onSelect={() => setPending({ kind: 'role', user: u, role: 'superadmin' })}>
                              <ShieldCheck /> Make superadmin
                            </DropdownMenuItem>
                          ) : (
                            <DropdownMenuItem onSelect={() => setPending({ kind: 'role', user: u, role: 'user' })}>
                              <ShieldOff /> Remove superadmin role
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          <DropdownMenuItem
                            destructive
                            disabled={u.role === 'superadmin'}
                            onSelect={() => setPending({ kind: 'remove', user: u })}
                          >
                            <Trash2 /> {u.role === 'superadmin' ? 'Demote before removing' : 'Remove account'}
                          </DropdownMenuItem>
                        </RowActions>
                      )}
                    </TD>
                  </TR>
                ))}
              </tbody>
            </Table>
            <LoadMore
              count={list.items.length}
              hasMore={list.hasMore}
              loading={list.isLoadingMore}
              onClick={list.loadMore}
              noun={role === 'user' ? 'riders' : 'superadmins'}
            />
          </>
        )}
      </Card>

      <ConfirmDialog
        open={pending?.kind === 'role'}
        onOpenChange={(o) => !o && setPending(null)}
        destructive={pending?.kind === 'role' && pending.role === 'user'}
        title={
          pending?.kind === 'role' && pending.role === 'superadmin'
            ? `Make ${pending.user.name} a superadmin?`
            : `Remove ${pending?.user.name ?? ''}’s superadmin role?`
        }
        description={
          pending?.kind === 'role' && pending.role === 'superadmin'
            ? 'They will be able to sign in to this dashboard, moderate content and manage other users.'
            : 'They will lose access to this dashboard and become a regular rider.'
        }
        confirmLabel={pending?.kind === 'role' && pending.role === 'superadmin' ? 'Make superadmin' : 'Demote'}
        loading={setRoleMutation.isPending}
        onConfirm={confirm}
      />
      <ConfirmDialog
        open={pending?.kind === 'remove'}
        onOpenChange={(o) => !o && setPending(null)}
        title={`Remove ${pending?.user.name ?? 'this rider'}?`}
        description="This deletes the account and everything they own — rides, posts, places, groups and messages. This can't be undone."
        confirmLabel="Remove account"
        loading={removeMutation.isPending}
        onConfirm={confirm}
      />
    </>
  );
}
