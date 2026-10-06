'use client';

import { Trash2, UsersRound } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { TD, TH, THead, TR, Table } from '@/shared/components/data-table';
import { formatDate, formatNumber, timeAgo } from '@/shared/lib/format';
import { useGroups } from '../application/use-content';
import type { Group } from '../domain/group';
import { ListCard } from './list-card';
import { Thumb } from './thumb';
import { useRemoveFlow } from './use-remove-flow';

export function GroupsScreen() {
  const list = useGroups();
  const remove = useRemoveFlow<Group>('group', (g) => ({
    title: `Remove “${g.name}”?`,
    description: `The group, its ${formatNumber(g.memberCount)} memberships and its whole chat history will be deleted. This can’t be undone.`,
  }));

  return (
    <>
      <ListCard
        list={list}
        noun="groups"
        empty={{ icon: UsersRound, title: 'No groups yet', description: 'Groups riders create to plan rides together will appear here.' }}
      >
        <Table>
          <THead>
            <tr>
              <TH>Group</TH>
              <TH className="text-right">Members</TH>
              <TH className="hidden md:table-cell">Owner</TH>
              <TH className="hidden md:table-cell">Last message</TH>
              <TH className="hidden lg:table-cell">Created</TH>
              <TH className="w-12">
                <span className="sr-only">Actions</span>
              </TH>
            </tr>
          </THead>
          <tbody>
            {list.items.map((g) => (
              <TR key={g.id}>
                <TD className="min-w-64">
                  <div className="flex items-center gap-3">
                    <Thumb src={g.coverImageUrl} className="size-10" fallback={UsersRound} />
                    <div className="min-w-0">
                      <div className="truncate font-medium">{g.name}</div>
                      <div className="line-clamp-1 text-xs text-muted">{g.description || 'No description'}</div>
                    </div>
                  </div>
                </TD>
                <TD className="tabular text-right">{formatNumber(g.memberCount)}</TD>
                <TD className="hidden md:table-cell">{g.organizerName}</TD>
                <TD className="hidden whitespace-nowrap text-muted md:table-cell">{g.lastMessageAt ? timeAgo(g.lastMessageAt) : 'No messages'}</TD>
                <TD className="hidden whitespace-nowrap text-muted lg:table-cell">{formatDate(g.createdAt)}</TD>
                <TD className="text-right">
                  <Button variant="ghost" size="icon-sm" onClick={() => remove.ask(g)} aria-label={`Remove ${g.name}`} className="hover:text-danger-ink">
                    <Trash2 />
                  </Button>
                </TD>
              </TR>
            ))}
          </tbody>
        </Table>
      </ListCard>
      {remove.dialog}
    </>
  );
}
