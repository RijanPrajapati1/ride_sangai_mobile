'use client';

import { useState } from 'react';
import { Button } from '@/shared/ui/button';
import { Dialog, DialogBody, DialogContent, DialogFooter } from '@/shared/ui/dialog';
import { Field, Input, Select, Textarea } from '@/shared/ui/input';
import { cn } from '@/shared/lib/cn';
import { useEditContent, type EditableKind } from '../application/use-content';
import type { ContentChanges } from '../data/content.repository';

interface Base {
  key: string;
  label: string;
  hint?: string;
  /** Takes half the row on wider screens. */
  half?: boolean;
}

interface TextOptions {
  max: number;
  required?: boolean;
  placeholder?: string;
  /** An emptied field is sent as null (clears an optional value). */
  nullable?: boolean;
}

export type FieldSpec = Base &
  (
    | ({ kind: 'text' } & TextOptions)
    | ({ kind: 'textarea' } & TextOptions)
    | { kind: 'number'; min: number; max: number; integer?: boolean }
    | { kind: 'select'; options: { value: string; label: string }[] }
    | { kind: 'datetime' }
  );

/** `2026-10-10T05:00` in the browser's time zone, for `<input type="datetime-local">`. */
function toLocalInput(iso: string) {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function toText(spec: FieldSpec, value: unknown) {
  if (value === null || value === undefined) return '';
  if (spec.kind === 'datetime') return toLocalInput(String(value));
  return String(value);
}

/**
 * Edits one post, ride, place or group from a list of field specs. Validates
 * like the API does and sends only the fields that changed.
 */
export function EditContentDialog({
  kind,
  item,
  title,
  description,
  fields,
  onClose,
}: {
  kind: EditableKind;
  item: { id: string } | null;
  title: string;
  description?: string;
  fields: FieldSpec[];
  onClose: () => void;
}) {
  return (
    <Dialog open={!!item} onOpenChange={(o) => !o && onClose()}>
      {item && (
        <DialogContent title={title} description={description ?? 'The author is not notified. The change is recorded in the audit log.'}>
          <EditForm key={item.id} kind={kind} item={item} fields={fields} onDone={onClose} />
        </DialogContent>
      )}
    </Dialog>
  );
}

function EditForm({
  kind,
  item,
  fields,
  onDone,
}: {
  kind: EditableKind;
  item: { id: string };
  fields: FieldSpec[];
  onDone: () => void;
}) {
  const edit = useEditContent(kind);
  const source = item as Record<string, unknown>;
  const initial = Object.fromEntries(fields.map((f) => [f.key, toText(f, source[f.key])]));
  const [values, setValues] = useState<Record<string, string>>(initial);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    const changes: ContentChanges = {};
    for (const f of fields) {
      const raw = values[f.key] ?? '';
      const text = raw.trim();
      if (f.kind === 'text' || f.kind === 'textarea') {
        if (f.required && !text) errs[f.key] = `${f.label} is required`;
        else if (text !== initial[f.key]?.trim()) changes[f.key] = text === '' && f.nullable ? null : text;
      } else if (f.kind === 'number') {
        const n = Number(text);
        if (!text || Number.isNaN(n) || n < f.min || n > f.max || (f.integer && !Number.isInteger(n)))
          errs[f.key] = `Enter ${f.integer ? 'a whole number' : 'a number'} from ${f.min} to ${f.max}`;
        else if (text !== initial[f.key]) changes[f.key] = n;
      } else if (f.kind === 'datetime') {
        const ms = Date.parse(text);
        if (!text || Number.isNaN(ms)) errs[f.key] = 'Pick a date and time';
        else if (text !== initial[f.key]) changes[f.key] = new Date(ms).toISOString();
      } else if (raw !== initial[f.key]) {
        changes[f.key] = raw;
      }
    }
    setErrors(errs);
    if (Object.keys(errs).length) return;
    if (Object.keys(changes).length === 0) return onDone();
    edit.mutate({ id: item.id, changes }, { onSuccess: onDone });
  };

  return (
    <form onSubmit={submit} noValidate className="flex min-h-0 flex-1 flex-col">
      <DialogBody className="grid gap-4 sm:grid-cols-2">
        {fields.map((f) => {
          const id = `edit-${f.key}`;
          const error = errors[f.key];
          const set = (v: string) => {
            setValues((s) => ({ ...s, [f.key]: v }));
            if (error) setErrors((s) => ({ ...s, [f.key]: '' }));
          };
          const common = { id, value: values[f.key] ?? '', 'aria-invalid': !!error };
          return (
            <Field
              key={f.key}
              label={f.label}
              htmlFor={id}
              className={cn(!f.half && 'sm:col-span-2')}
              hint={error ? <span className="text-danger-ink">{error}</span> : f.hint}
            >
              {f.kind === 'text' || f.kind === 'textarea' ? (
                f.kind === 'textarea' ? (
                  <Textarea {...common} onChange={(e) => set(e.target.value)} maxLength={f.max} placeholder={f.placeholder} />
                ) : (
                  <Input {...common} onChange={(e) => set(e.target.value)} maxLength={f.max} placeholder={f.placeholder} />
                )
              ) : f.kind === 'number' ? (
                <Input
                  {...common}
                  type="number"
                  inputMode={f.integer ? 'numeric' : 'decimal'}
                  min={f.min}
                  max={f.max}
                  step={f.integer ? 1 : 'any'}
                  onChange={(e) => set(e.target.value)}
                />
              ) : f.kind === 'datetime' ? (
                <Input {...common} type="datetime-local" onChange={(e) => set(e.target.value)} />
              ) : (
                <Select {...common} onChange={(e) => set(e.target.value)}>
                  {f.options.map((o) => (
                    <option key={o.value} value={o.value}>
                      {o.label}
                    </option>
                  ))}
                </Select>
              )}
            </Field>
          );
        })}
      </DialogBody>
      <DialogFooter>
        <Button type="button" variant="secondary" onClick={onDone} disabled={edit.isPending}>
          Cancel
        </Button>
        <Button type="submit" loading={edit.isPending}>
          Save changes
        </Button>
      </DialogFooter>
    </form>
  );
}
