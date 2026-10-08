'use client';

import { useState } from 'react';
import { Eye, EyeOff } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { Dialog, DialogBody, DialogContent, DialogFooter } from '@/shared/ui/dialog';
import { Field, Input, Select, Textarea } from '@/shared/ui/input';
import { humanize } from '@/shared/lib/format';
import { useDisableUser, useSetPassword, useUpdateUser } from '../application/use-users';
import { EXPERIENCE_LEVELS, RIDE_TYPES, type ManagedUser, type UserUpdate } from '../domain/user';

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function Err({ msg }: { msg?: string }) {
  return msg ? <span className="text-danger-ink">{msg}</span> : null;
}

/** Edits anyone's profile, including the email they sign in with. */
export function EditUserDialog({ user, onClose }: { user: ManagedUser | null; onClose: () => void }) {
  return (
    <Dialog open={!!user} onOpenChange={(o) => !o && onClose()}>
      {user && (
        <DialogContent title={`Edit ${user.name}`} description="Changes show in the app right away. The rider is not notified.">
          <EditUserForm key={user.id} user={user} onDone={onClose} />
        </DialogContent>
      )}
    </Dialog>
  );
}

function EditUserForm({ user, onDone }: { user: ManagedUser; onDone: () => void }) {
  const update = useUpdateUser();
  const [values, setValues] = useState({
    name: user.name,
    email: user.email ?? '',
    bio: user.bio,
    location: user.location,
    avatarUrl: user.avatarUrl,
    experienceLevel: user.experienceLevel,
    preferredRideType: user.preferredRideType,
    interests: user.cyclingInterests.join(', '),
  });
  const [errors, setErrors] = useState<{ name?: string; email?: string; avatarUrl?: string }>({});
  const set = (key: keyof typeof values, value: string) => setValues((v) => ({ ...v, [key]: value }));

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const errs: typeof errors = {};
    if (!values.name.trim()) errs.name = 'Name is required';
    if (!EMAIL.test(values.email.trim())) errs.email = 'Enter a valid email';
    if (values.avatarUrl.trim() && !/^https?:\/\//.test(values.avatarUrl.trim())) errs.avatarUrl = 'Use an http(s) image URL';
    setErrors(errs);
    if (Object.keys(errs).length) return;

    // Only send what changed, so the audit log names the right fields.
    const interests = values.interests
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    const input: UserUpdate = {};
    if (values.name.trim() !== user.name) input.name = values.name.trim();
    if (values.email.trim().toLowerCase() !== (user.email ?? '')) input.email = values.email.trim();
    if (values.bio.trim() !== user.bio) input.bio = values.bio.trim();
    if (values.location.trim() !== user.location) input.location = values.location.trim();
    if (values.avatarUrl.trim() !== user.avatarUrl) input.avatarUrl = values.avatarUrl.trim();
    if (values.experienceLevel !== user.experienceLevel) input.experienceLevel = values.experienceLevel as UserUpdate['experienceLevel'];
    if (values.preferredRideType !== user.preferredRideType) input.preferredRideType = values.preferredRideType;
    if (interests.join('|') !== user.cyclingInterests.join('|')) input.cyclingInterests = interests;
    if (Object.keys(input).length === 0) return onDone();
    update.mutate({ user, input }, { onSuccess: onDone });
  };

  return (
    <form onSubmit={submit} noValidate className="flex min-h-0 flex-1 flex-col">
      <DialogBody className="flex flex-col gap-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Name" htmlFor="u-name" hint={<Err msg={errors.name} />}>
            <Input id="u-name" value={values.name} onChange={(e) => set('name', e.target.value)} maxLength={80} aria-invalid={!!errors.name} />
          </Field>
          <Field label="Email" htmlFor="u-email" hint={errors.email ? <Err msg={errors.email} /> : 'They sign in with this.'}>
            <Input id="u-email" type="email" value={values.email} onChange={(e) => set('email', e.target.value)} maxLength={254} aria-invalid={!!errors.email} />
          </Field>
        </div>
        <Field label="Bio" htmlFor="u-bio">
          <Textarea id="u-bio" value={values.bio} onChange={(e) => set('bio', e.target.value)} maxLength={500} className="min-h-20" />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Location" htmlFor="u-location">
            <Input id="u-location" value={values.location} onChange={(e) => set('location', e.target.value)} maxLength={120} placeholder="Kathmandu" />
          </Field>
          <Field label="Experience" htmlFor="u-level">
            <Select id="u-level" value={values.experienceLevel} onChange={(e) => set('experienceLevel', e.target.value)}>
              {EXPERIENCE_LEVELS.map((l) => (
                <option key={l} value={l}>
                  {humanize(l)}
                </option>
              ))}
            </Select>
          </Field>
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Preferred ride type" htmlFor="u-type">
            <Select id="u-type" value={values.preferredRideType} onChange={(e) => set('preferredRideType', e.target.value)}>
              {Object.entries(RIDE_TYPES).map(([category, types]) => (
                <optgroup key={category} label={humanize(category)}>
                  {types.map((t) => (
                    <option key={t} value={t}>
                      {humanize(t)}
                    </option>
                  ))}
                </optgroup>
              ))}
            </Select>
          </Field>
          <Field label="Interests" htmlFor="u-interests" hint="Separate with commas.">
            <Input id="u-interests" value={values.interests} onChange={(e) => set('interests', e.target.value)} placeholder="Hill climbs, Photography" />
          </Field>
        </div>
        <Field label="Photo URL" htmlFor="u-avatar" hint={errors.avatarUrl ? <Err msg={errors.avatarUrl} /> : 'Leave empty to show their initials.'}>
          <Input id="u-avatar" value={values.avatarUrl} onChange={(e) => set('avatarUrl', e.target.value)} maxLength={2048} aria-invalid={!!errors.avatarUrl} placeholder="https://…" />
        </Field>
      </DialogBody>
      <DialogFooter>
        <Button type="button" variant="secondary" onClick={onDone} disabled={update.isPending}>
          Cancel
        </Button>
        <Button type="submit" loading={update.isPending}>
          Save changes
        </Button>
      </DialogFooter>
    </form>
  );
}

/** Disables an account, with an optional internal note on why. */
export function DisableUserDialog({ user, onClose }: { user: ManagedUser | null; onClose: () => void }) {
  const disable = useDisableUser();
  const [reason, setReason] = useState('');
  return (
    <Dialog
      open={!!user}
      onOpenChange={(o) => {
        if (o || disable.isPending) return;
        setReason('');
        onClose();
      }}
    >
      {user && (
        <DialogContent
          title={`Disable ${user.name}?`}
          description="They are signed out on every device and can't sign in until you enable the account again. Their rides and posts stay up."
        >
          <form
            className="flex min-h-0 flex-1 flex-col"
            onSubmit={(e) => {
              e.preventDefault();
              disable.mutate(
                { user, reason: reason.trim() || null },
                {
                  onSuccess: () => {
                    setReason('');
                    onClose();
                  },
                },
              );
            }}
          >
            <DialogBody>
              <Field label="Reason" htmlFor="d-reason" hint="Optional. Only superadmins see this.">
                <Textarea
                  id="d-reason"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  maxLength={300}
                  className="min-h-20"
                  placeholder="Spam, harassment, impersonation…"
                  autoFocus
                />
              </Field>
            </DialogBody>
            <DialogFooter>
              <Button type="button" variant="secondary" onClick={onClose} disabled={disable.isPending}>
                Cancel
              </Button>
              <Button type="submit" variant="danger" loading={disable.isPending}>
                Disable account
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      )}
    </Dialog>
  );
}

/** Sets a new password for someone locked out of their account. */
export function SetPasswordDialog({ user, onClose }: { user: ManagedUser | null; onClose: () => void }) {
  const setPassword = useSetPassword();
  const [password, setValue] = useState('');
  const [show, setShow] = useState(false);
  const [error, setError] = useState<string>();
  const close = () => {
    if (setPassword.isPending) return;
    setValue('');
    setError(undefined);
    onClose();
  };
  return (
    <Dialog open={!!user} onOpenChange={(o) => !o && close()}>
      {user && (
        <DialogContent
          title={`Set a new password for ${user.name}`}
          description="They are signed out everywhere. Share the new password with them privately."
        >
          <form
            className="flex min-h-0 flex-1 flex-col"
            noValidate
            onSubmit={(e) => {
              e.preventDefault();
              if (password.length < 8) return setError('Use at least 8 characters');
              setPassword.mutate({ user, password }, { onSuccess: close });
            }}
          >
            <DialogBody>
              <Field label="New password" htmlFor="p-new" hint={error ? <Err msg={error} /> : 'At least 8 characters.'}>
                <div className="relative">
                  <Input
                    id="p-new"
                    type={show ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => {
                      setValue(e.target.value);
                      setError(undefined);
                    }}
                    maxLength={128}
                    autoComplete="new-password"
                    className="pr-10"
                    aria-invalid={!!error}
                    autoFocus
                  />
                  <button
                    type="button"
                    onClick={() => setShow((s) => !s)}
                    className="absolute top-1/2 right-2 -translate-y-1/2 rounded p-1 text-subtle hover:text-foreground"
                    aria-label={show ? 'Hide password' : 'Show password'}
                  >
                    {show ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                  </button>
                </div>
              </Field>
            </DialogBody>
            <DialogFooter>
              <Button type="button" variant="secondary" onClick={close} disabled={setPassword.isPending}>
                Cancel
              </Button>
              <Button type="submit" loading={setPassword.isPending}>
                Set password
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      )}
    </Dialog>
  );
}
