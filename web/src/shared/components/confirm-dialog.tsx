'use client';

import { AlertDialog } from 'radix-ui';
import { AlertTriangle } from 'lucide-react';
import { Button } from '@/shared/ui/button';

/**
 * Confirmation for destructive actions. Stays open while `onConfirm` runs and
 * closes when it resolves (errors are toasted by the mutation cache).
 */
export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel = 'Delete',
  destructive = true,
  loading,
  onConfirm,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description: React.ReactNode;
  confirmLabel?: string;
  destructive?: boolean;
  loading?: boolean;
  onConfirm: () => void;
}) {
  return (
    <AlertDialog.Root open={open} onOpenChange={(o) => !loading && onOpenChange(o)}>
      <AlertDialog.Portal>
        <AlertDialog.Overlay className="fixed inset-0 z-50 bg-[#0b1215]/50 backdrop-blur-[2px] data-[state=open]:animate-fade-in" />
        <AlertDialog.Content className="fixed top-1/2 left-1/2 z-50 w-[calc(100vw-2rem)] max-w-md -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border bg-surface p-5 shadow-pop outline-none data-[state=open]:animate-zoom-in">
          <div className="flex gap-4">
            <div
              className={
                destructive
                  ? 'flex size-10 shrink-0 items-center justify-center rounded-full bg-danger-soft text-danger-ink'
                  : 'flex size-10 shrink-0 items-center justify-center rounded-full bg-primary-soft text-primary-ink'
              }
            >
              <AlertTriangle className="size-5" />
            </div>
            <div className="min-w-0">
              <AlertDialog.Title className="text-base font-semibold">{title}</AlertDialog.Title>
              <AlertDialog.Description className="mt-1.5 text-sm text-muted">{description}</AlertDialog.Description>
            </div>
          </div>
          <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <AlertDialog.Cancel asChild>
              <Button variant="secondary" disabled={loading}>
                Cancel
              </Button>
            </AlertDialog.Cancel>
            <Button
              variant={destructive ? 'danger' : 'primary'}
              loading={loading}
              onClick={(e) => {
                e.preventDefault();
                onConfirm();
              }}
            >
              {confirmLabel}
            </Button>
          </div>
        </AlertDialog.Content>
      </AlertDialog.Portal>
    </AlertDialog.Root>
  );
}
