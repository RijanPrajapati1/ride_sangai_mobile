'use client';

import { useState } from 'react';
import { Pencil, Trash2, UsersRound } from 'lucide-react';
import { DropdownMenuItem, DropdownMenuSeparator } from '@/shared/ui/dropdown-menu';
import { TD, TH, THead, TR, Table } from '@/shared/components/data-table';
import { RowActions } from '@/shared/components/row-actions';
import { formatDate, formatNumber, timeAgo } from '@/shared/lib/format';
import { useGroups } from '../application/use-content';
import type { Group } from '../domain/group';
import { EditContentDialog, type FieldSpec } from './edit-content-dialog';
import { ListCard } from './list-card';
import { Thumb } from './thumb';
import { useRemoveFlow } from './use-remove-flow';

const GROUP_FIELDS: FieldSpec[] = [
  { key: 'name', label: 'Name', kind: 'text', max: 80, required: true },
  { key: 'description', label: 'Description', kind: 'textarea', max: 1000, required: true },
];

export function GroupsScreen() {
  const list = useGroups();
  const [editing, setEditing] = useState<Group | null>(null);
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
                  <RowActions label={`Actions for ${g.name}`}>
                    <DropdownMenuItem onSelect={() => setEditing(g)}>
                      <Pencil /> Edit group
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem destructive onSelect={() => remove.ask(g)}>
                      <Trash2 /> Remove group
                    </DropdownMenuItem>
                  </RowActions>
                </TD>
              </TR>
            ))}
          </tbody>
        </Table>
      </ListCard>
      {remove.dialog}
      <EditContentDialog
        kind="group"
        item={editing}
        title={`Edit “${editing?.name ?? ''}”`}
        fields={GROUP_FIELDS}
        onClose={() => setEditing(null)}
      />
    </>
  );
}
