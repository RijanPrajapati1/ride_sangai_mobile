'use client';

import { ApiError, toApiError } from './errors';

type Query = Record<string, string | number | boolean | null | undefined>;

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';
  query?: Query;
  body?: unknown;
  signal?: AbortSignal;
}

let redirecting = false;

/**
 * Sends the browser to /login (a full page load, so no state of the ended
 * session survives). Only the first call wins, so a burst of 401s — or a
 * sign-out racing in-flight requests — cannot redirect twice.
 */
export function goToLogin(reason?: string, { keepLocation = true } = {}) {
  if (redirecting || typeof window === 'undefined') return;
  redirecting = true;
  const next = `${window.location.pathname}${window.location.search}`;
  const params = new URLSearchParams();
  if (keepLocation && next && next !== '/') params.set('next', next);
  if (reason) params.set('reason', reason);
  const qs = params.toString();
  // A full page load (not a client navigation) drops all cached data of the ended session.
  // eslint-disable-next-line @next/next/no-location-assign-relative-destination
  window.location.assign(`/login${qs ? `?${qs}` : ''}`);
}

async function send(url: string, init: RequestInit): Promise<Response> {
  try {
    return await fetch(url, { ...init, credentials: 'same-origin', cache: 'no-store' });
  } catch (err) {
    if (err instanceof DOMException && err.name === 'AbortError') throw err;
    throw new ApiError(0, 'NETWORK_ERROR', 'Could not reach the dashboard server. Check your connection.');
  }
}

async function parse<T>(res: Response): Promise<T> {
  if (res.status === 204) return undefined as T;
  let data: unknown = null;
  try {
    data = await res.json();
  } catch {
    // non-JSON body
  }
  if (!res.ok) throw toApiError(res.status, data);
  return data as T;
}

function jsonInit(opts: RequestOptions): RequestInit {
  return {
    method: opts.method ?? 'GET',
    headers: opts.body !== undefined ? { 'content-type': 'application/json' } : undefined,
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
    signal: opts.signal,
  };
}

/**
 * Calls the Ride Sangai API through the BFF proxy (`/api/backend/*`). Used by
 * feature repositories. The browser never sees tokens: the session lives in
 * httpOnly cookies that only the Next.js server reads.
 */
export async function apiRequest<T>(path: string, opts: RequestOptions = {}): Promise<T> {
  const url = new URL(`/api/backend/${path.replace(/^\/+/, '')}`, window.location.origin);
  for (const [key, value] of Object.entries(opts.query ?? {})) {
    if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value));
  }
  const res = await send(url.toString(), jsonInit(opts));
  try {
    return await parse<T>(res);
  } catch (err) {
    if (err instanceof ApiError) {
      if (err.status === 401) goToLogin('expired');
      else if (err.status === 403 && (err.code === 'FORBIDDEN' || err.code === 'NOT_SUPERADMIN')) {
        // The account lost superadmin access: end the session.
        void fetch('/api/auth/logout', { method: 'POST' }).finally(() => goToLogin('forbidden'));
      }
    }
    throw err;
  }
}

/** Calls one of the BFF's own endpoints (e.g. `/api/auth/login`). */
export async function bffRequest<T>(path: string, opts: RequestOptions = {}): Promise<T> {
  return parse<T>(await send(path, jsonInit(opts)));
}
