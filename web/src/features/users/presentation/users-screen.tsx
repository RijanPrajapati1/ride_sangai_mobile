'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Ban, ShieldCheck, UserRound, UsersRound } from 'lucide-react';
import { Badge } from '@/shared/ui/badge';
import { Card } from '@/shared/ui/card';
import { PageHeader } from '@/shared/layout/page-header';
import { TD, TH, THead, TR, Table, TableSkeleton } from '@/shared/components/data-table';
import { RowActions } from '@/shared/components/row-actions';
import { SearchInput } from '@/shared/components/search-input';
import { Segmented } from '@/shared/components/segmented';
import { EmptyState, ErrorState, LoadMore } from '@/shared/components/states';
import { UserCell } from '@/shared/components/user-cell';
import { formatDate, formatNumber, timeAgo } from '@/shared/lib/format';
import { useDebouncedValue } from '@/shared/lib/use-debounced-value';
import { useUsers } from '../application/use-users';
import type { ManagedUser, UserRole, UserStatus } from '../domain/user';
import { useUserActions } from './user-actions';

export function UserStatusBadge({ user }: { user: Pick<ManagedUser, 'disabledAt' | 'role'> }) {
  if (user.disabledAt)
    return (
      <Badge tone="danger">
        <Ban /> Disabled
      </Badge>
    );
  if (user.role === 'superadmin')
    return (
      <Badge tone="primary">
        <ShieldCheck /> Superadmin
      </Badge>
    );
  return <Badge tone="success">Active</Badge>;
}

export function UsersScreen() {
  const [role, setRole] = useState<UserRole>('user');
  const [status, setStatus] = useState<UserStatus>('all');
  const [search, setSearch] = useState('');
  const q = useDebouncedValue(search, 300);
  const list = useUsers({ role, status, q });
  const actions = useUserActions();

  return (
    <>
      <PageHeader
        title="Users"
        description="Everyone with a Yatrix account. Open anyone to edit their profile, reset their password, disable or remove them."
      />
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
        {role === 'user' && (
          <Segmented
            ariaLabel="Status"
            value={status}
            onChange={setStatus}
            options={[
              { value: 'all', label: 'All' },
              { value: 'active', label: 'Active' },
              { value: 'disabled', label: 'Disabled' },
            ]}
          />
        )}
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
          ) : role === 'superadmin' ? (
            <EmptyState icon={ShieldCheck} title="No superadmins" description="Promote a rider to give them access to this dashboard." />
          ) : status === 'disabled' ? (
            <EmptyState icon={Ban} title="No disabled accounts" description="Accounts you disable show up here so you can enable them again." />
          ) : (
            <EmptyState icon={UsersRound} title="No riders yet" description="People who sign up in the Yatrix app will appear here." />
          )
        ) : (
          <>
            <Table>
              <THead>
                <tr>
                  <TH>{role === 'user' ? 'Rider' : 'Superadmin'}</TH>
                  <TH className="hidden sm:table-cell">Status</TH>
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
                  <TR key={u.id} className={u.disabledAt ? 'opacity-70' : undefined}>
                    <TD className="min-w-56">
                      <Link href={`/users/${u.id}`} className="block rounded-lg outline-offset-4">
                        <UserCell
                          name={u.name}
                          avatarUrl={u.avatarUrl}
                          secondary={u.email ?? '—'}
                          trailing={
                            <>
                              {u.isMe && <Badge tone="primary">You</Badge>}
                              {/* The status column is hidden on phones. */}
                              {u.disabledAt && (
                                <Badge tone="danger" className="sm:hidden">
                                  Disabled
                                </Badge>
                              )}
                            </>
                          }
                        />
                      </Link>
                    </TD>
                    <TD className="hidden sm:table-cell">
                      <UserStatusBadge user={u} />
                    </TD>
                    <TD className="hidden whitespace-nowrap text-muted md:table-cell">{formatDate(u.createdAt)}</TD>
                    <TD className="hidden whitespace-nowrap text-muted lg:table-cell" title={u.lastLoginAt ?? undefined}>
                      {timeAgo(u.lastLoginAt)}
                    </TD>
                    <TD className="tabular text-right">{formatNumber(u.followersCount)}</TD>
                    <TD className="tabular hidden text-right text-muted sm:table-cell">{formatNumber(u.totalRides)}</TD>
                    <TD className="text-right">
                      {u.isMe ? (
                        <span className="text-xs text-subtle" title="Manage your own account from the account menu">
                          —
                        </span>
                      ) : (
                        <RowActions label={`Actions for ${u.name}`}>{actions.menuItems(u)}</RowActions>
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
      {actions.dialogs}
    </>
  );
}
