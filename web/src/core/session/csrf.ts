import 'server-only';
import type { NextRequest } from 'next/server';
import { APP_ORIGIN } from '@/core/config/env';

const SAFE_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);

/**
 * CSRF defence for state-changing requests (on top of SameSite=Lax cookies):
 * the browser-supplied Origin header must match this app's origin.
 */
export function isSameOrigin(req: NextRequest): boolean {
  if (SAFE_METHODS.has(req.method)) return true;
  const origin = req.headers.get('origin');
  if (!origin || origin === 'null') return false;
  let originUrl: URL;
  try {
    originUrl = new URL(origin);
  } catch {
    return false;
  }
  if (APP_ORIGIN) return originUrl.origin === APP_ORIGIN;
  const host = req.headers.get('x-forwarded-host') ?? req.headers.get('host');
  return !!host && originUrl.host === host.split(',')[0].trim();
}

export const CSRF_ERROR = {
  error: { code: 'CSRF_REJECTED', message: 'This request was blocked because it did not come from the dashboard.' },
};
