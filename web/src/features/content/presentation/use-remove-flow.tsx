'use client';

import { useState } from 'react';
import { ConfirmDialog } from '@/shared/components/confirm-dialog';
import { useRemoveContent, type ContentKind } from '../application/use-content';

/** Confirm-then-delete for one content kind. Render `dialog` once in the screen. */
export function useRemoveFlow<T extends { id: string }>(
  kind: ContentKind,
  copy: (item: T) => { title: string; description: React.ReactNode },
) {
  const [target, setTarget] = useState<T | null>(null);
  const remove = useRemoveContent(kind);
  const text = target ? copy(target) : { title: '', description: '' };
  const dialog = (
    <ConfirmDialog
      open={!!target}
      onOpenChange={(o) => !o && setTarget(null)}
      title={text.title}
      description={text.description}
      confirmLabel="Remove"
      loading={remove.isPending}
      onConfirm={() => target && remove.mutate(target.id, { onSuccess: () => setTarget(null) })}
    />
  );
  return { ask: setTarget, dialog };
}
