'use client';

import { useEffect, useState } from 'react';
import { AlertCircle, Eye, EyeOff, Info, Lock, Mail } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { Field, Input } from '@/shared/ui/input';
import { Brand, BrandMark } from '@/shared/layout/brand';
import { Mountains } from '@/shared/layout/mountains';
import { ThemeToggle } from '@/shared/layout/theme';
import { errorMessage } from '@/core/http/errors';
import { loginSchema } from '../application/login.schema';
import { useLogin } from '../application/use-auth';

const REASONS: Record<string, string> = {
  expired: 'Your session has ended. Please sign in again.',
  forbidden: 'That account no longer has superadmin access.',
  'signed-out': 'You have been signed out.',
};

/** Only same-app relative paths are allowed as a post-login destination. */
function safeNext(next?: string): string {
  if (!next || !next.startsWith('/') || next.startsWith('//') || next.startsWith('/\\')) return '/';
  if (next.startsWith('/login') || next.startsWith('/api')) return '/';
  return next;
}

export function LoginScreen({ next, reason }: { next?: string; reason?: string }) {
  const login = useLogin();
  const [showPassword, setShowPassword] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<{ email?: string; password?: string }>({});
  const notice = reason ? REASONS[reason] : undefined;
  // Until React has hydrated, a submit would fall back to a native form post;
  // keep the button disabled so credentials only ever go through the BFF.
  const [hydrated, setHydrated] = useState(false);
  // eslint-disable-next-line react-hooks/set-state-in-effect -- one-time hydration flag
  useEffect(() => setHydrated(true), []);

  function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const parsed = loginSchema.safeParse({ email: form.get('email'), password: form.get('password') });
    if (!parsed.success) {
      const errs: typeof fieldErrors = {};
      for (const issue of parsed.error.issues) {
        const key = issue.path[0] as 'email' | 'password';
        errs[key] ??= issue.message;
      }
      setFieldErrors(errs);
      return;
    }
    setFieldErrors({});
    login.mutate(parsed.data, {
      onSuccess: () => window.location.assign(safeNext(next)),
    });
  }

  return (
    <div className="grid min-h-dvh lg:grid-cols-[1.05fr_1fr]">
      {/* Brand panel: the app's teal sign-in hero */}
      <div
        className="relative hidden overflow-hidden lg:block"
        style={{ background: 'linear-gradient(135deg, #1fb6a8 0%, #0e9083 45%, #0b6f66 100%)' }}
      >
        <div aria-hidden className="absolute top-[22%] right-[16%] size-28 rounded-full bg-white/25" />
        <Mountains className="h-[55%]" />
        <div className="relative flex h-full flex-col justify-between p-12 text-white">
          <div className="flex items-center gap-3">
            <BrandMark className="size-11 rounded-2xl ring-2 ring-white/60" />
            <div>
              <div className="text-lg font-extrabold">Yatrix</div>
              <div className="text-xs font-semibold tracking-wider text-white/75 uppercase">Superadmin</div>
            </div>
          </div>
          <div className="max-w-md pb-28">
            <h1 className="text-[40px] leading-[1.1] font-extrabold tracking-tight">Keep the community riding together.</h1>
            <p className="mt-4 text-[15px] leading-relaxed text-white/85">
              Look after riders, edit or remove anything that breaks the guidelines, send announcements and answer
              feedback, all in one place.
            </p>
          </div>
        </div>
      </div>

      {/* Form */}
      <div className="flex flex-col">
        <div className="flex items-center justify-between p-4 sm:p-6">
          <div className="lg:invisible">
            <Brand />
          </div>
          <ThemeToggle />
        </div>
        <div className="flex flex-1 items-center justify-center px-4 pb-16 sm:px-6">
          <div className="w-full max-w-sm">
            <h2 className="text-[28px] font-extrabold tracking-tight">Welcome back</h2>
            <p className="mt-1.5 text-sm text-muted">Use your Yatrix superadmin account.</p>

            {notice && !login.isError && (
              <div className="mt-6 flex items-start gap-2.5 rounded-lg border border-border bg-surface-2 px-3 py-2.5 text-sm text-muted">
                <Info className="mt-0.5 size-4 shrink-0 text-primary-ink" />
                {notice}
              </div>
            )}
            {login.isError && (
              <div
                role="alert"
                className="mt-6 flex items-start gap-2.5 rounded-lg border border-danger/30 bg-danger-soft px-3 py-2.5 text-sm text-danger-ink"
              >
                <AlertCircle className="mt-0.5 size-4 shrink-0" />
                {errorMessage(login.error)}
              </div>
            )}

            <form className="mt-6 flex flex-col gap-4" method="post" onSubmit={onSubmit} noValidate>
              <Field label="Email" htmlFor="email" hint={fieldErrors.email && <span className="text-danger-ink">{fieldErrors.email}</span>}>
                <div className="relative">
                  <Mail className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-subtle" />
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    autoComplete="username"
                    placeholder="you@yatrix.app"
                    className="h-11 pl-9"
                    aria-invalid={!!fieldErrors.email}
                    autoFocus
                  />
                </div>
              </Field>
              <Field label="Password" htmlFor="password" hint={fieldErrors.password && <span className="text-danger-ink">{fieldErrors.password}</span>}>
                <div className="relative">
                  <Lock className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-subtle" />
                  <Input
                    id="password"
                    name="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="current-password"
                    placeholder="••••••••"
                    className="h-11 pr-10 pl-9"
                    aria-invalid={!!fieldErrors.password}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute top-1/2 right-2 -translate-y-1/2 rounded-md p-1.5 text-subtle hover:text-foreground"
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                  >
                    {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                  </button>
                </div>
              </Field>
              <Button type="submit" size="lg" className="mt-2 w-full" loading={login.isPending} disabled={!hydrated}>
                Sign in
              </Button>
            </form>
            <p className="mt-8 text-center text-xs text-subtle">
              Riders manage their own rides and posts in the Yatrix app. This dashboard is for the platform team.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
