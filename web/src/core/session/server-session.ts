import 'server-only';
import { createHash } from 'node:crypto';
import type { NextRequest, NextResponse } from 'next/server';
import { API_TIMEOUT_MS, API_URL, IS_PROD } from '@/core/config/env';
import type { ApiErrorBody } from '@/core/http/errors';
import { ACCESS_COOKIE, ACCESS_COOKIE_PATH, REFRESH_COOKIE, REFRESH_COOKIE_PATH } from './cookies';
import type { TokenEnvelope } from './tokens';

/** Refresh when the access token has less than this left. */
const REFRESH_LEEWAY_MS = 30_000;
/**
 * How long a finished refresh is remembered. Requests that were already in
 * flight with the old (now used) refresh token get this result instead of
 * replaying the token, which the API would treat as theft and revoke.
 */
const REFRESH_RESULT_TTL_MS = 60_000;

export interface SessionTokens {
  accessToken: string;
  refreshToken: string;
  /** Epoch ms. */
  refreshExpiresAt: number;
}

export type RefreshResult =
  | { ok: true; tokens: SessionTokens; auth: TokenEnvelope }
  | { ok: false; ended: boolean; status: number; body: ApiErrorBody };

export const SESSION_ENDED: ApiErrorBody = {
  error: { code: 'SESSION_ENDED', message: 'Your session has ended. Please sign in again.' },
};

export const API_UNREACHABLE: ApiErrorBody = {
  error: { code: 'API_UNREACHABLE', message: 'The Ride Sangai API could not be reached. Try again shortly.' },
};

export function apiUrl(path: string): string {
  return `${API_URL}/${path.replace(/^\/+/, '')}`;
}

/** fetch() against the API with a timeout and no caching. */
export function apiFetch(path: string, init: RequestInit = {}): Promise<Response> {
  return fetch(apiUrl(path), {
    ...init,
    cache: 'no-store',
    redirect: 'manual',
    signal: AbortSignal.timeout(API_TIMEOUT_MS),
  });
}

export async function readErrorBody(res: Response): Promise<ApiErrorBody> {
  try {
    const body = (await res.json()) as Partial<ApiErrorBody>;
    if (body?.error?.message) return body as ApiErrorBody;
  } catch {
    // fall through
  }
  return { error: { code: `HTTP_${res.status}`, message: `The API responded with status ${res.status}.` } };
}

/** Reads the `exp` claim (epoch ms) of a JWT without verifying it — only used for timing. */
export function tokenExpiry(token: string | undefined): number | null {
  if (!token) return null;
  const part = token.split('.')[1];
  if (!part) return null;
  try {
    const payload = JSON.parse(Buffer.from(part, 'base64url').toString('utf8')) as { exp?: unknown };
    return typeof payload.exp === 'number' ? payload.exp * 1000 : null;
  } catch {
    return null;
  }
}

export function isAccessTokenFresh(token: string | undefined): boolean {
  const exp = tokenExpiry(token);
  return exp !== null && exp - Date.now() > REFRESH_LEEWAY_MS;
}

export function tokensFromAuth(auth: TokenEnvelope): SessionTokens {
  const refreshExpiresAt = Date.parse(auth.refreshTokenExpiresAt);
  return {
    accessToken: auth.accessToken,
    refreshToken: auth.refreshToken,
    refreshExpiresAt: Number.isFinite(refreshExpiresAt)
      ? refreshExpiresAt
      : Date.now() + 7 * 24 * 3600 * 1000,
  };
}

// --- Single-flight refresh ---------------------------------------------------

interface RefreshEntry {
  promise: Promise<RefreshResult>;
}

const globalForRefresh = globalThis as unknown as { __rsRefreshFlights?: Map<string, RefreshEntry> };
const flights = (globalForRefresh.__rsRefreshFlights ??= new Map<string, RefreshEntry>());

function keyOf(refreshToken: string): string {
  return createHash('sha256').update(refreshToken).digest('hex');
}

async function doRefresh(refreshToken: string): Promise<RefreshResult> {
  let res: Response;
  try {
    res = await apiFetch('auth/refresh', {
      method: 'POST',
      headers: { 'content-type': 'application/json', accept: 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
  } catch {
    return { ok: false, ended: false, status: 502, body: API_UNREACHABLE };
  }
  if (res.ok) {
    const auth = (await res.json()) as TokenEnvelope;
    if (!auth.user?.isSuperadmin) {
      // The account lost the superadmin role: end this session.
      await apiFetch('auth/logout', {
        method: 'POST',
        headers: { authorization: `Bearer ${auth.accessToken}` },
      }).catch(() => undefined);
      return {
        ok: false,
        ended: true,
        status: 403,
        body: { error: { code: 'NOT_SUPERADMIN', message: 'This account no longer has superadmin access.' } },
      };
    }
    return { ok: true, auth, tokens: tokensFromAuth(auth) };
  }
  const body = await readErrorBody(res);
  // 400/401 means the refresh token is invalid, expired, reused or revoked.
  const ended = res.status === 400 || res.status === 401 || res.status === 403;
  return { ok: false, ended, status: ended ? 401 : res.status, body: ended ? SESSION_ENDED : body };
}

/**
 * Exchanges a refresh token for a new pair. Concurrent callers with the same
 * refresh token share one request, and the result is remembered briefly so a
 * late request carrying the old cookie never replays the single-use token.
 *
 * Note: this is per server process. Running several instances requires sticky
 * sessions or a shared store (see README).
 */
export function refreshSession(refreshToken: string): Promise<RefreshResult> {
  const key = keyOf(refreshToken);
  const existing = flights.get(key);
  if (existing) return existing.promise;
  const promise = doRefresh(refreshToken).then((result) => {
    // Remember successes and terminal failures; forget transient failures right away.
    const ttl = result.ok || result.ended ? REFRESH_RESULT_TTL_MS : 0;
    setTimeout(() => flights.delete(key), ttl).unref?.();
    return result;
  });
  flights.set(key, { promise });
  return promise;
}

// --- Cookies -------------------------------------------------------------------

const baseCookie = { httpOnly: true, secure: IS_PROD, sameSite: 'lax' as const };

export function setSessionCookies(res: NextResponse, tokens: SessionTokens): void {
  const maxAge = Math.max(0, Math.floor((tokens.refreshExpiresAt - Date.now()) / 1000));
  // The access cookie lives as long as the session so its presence tells the
  // route guard that a session exists; the token inside expires after ~15 min
  // and is refreshed by the BFF.
  res.cookies.set(ACCESS_COOKIE, tokens.accessToken, { ...baseCookie, path: ACCESS_COOKIE_PATH, maxAge });
  res.cookies.set(REFRESH_COOKIE, tokens.refreshToken, { ...baseCookie, path: REFRESH_COOKIE_PATH, maxAge });
}

export function clearSessionCookies(res: NextResponse): void {
  res.cookies.set(ACCESS_COOKIE, '', { ...baseCookie, path: ACCESS_COOKIE_PATH, maxAge: 0 });
  res.cookies.set(REFRESH_COOKIE, '', { ...baseCookie, path: REFRESH_COOKIE_PATH, maxAge: 0 });
}

export function readSessionCookies(req: NextRequest): { access?: string; refresh?: string } {
  return {
    access: req.cookies.get(ACCESS_COOKIE)?.value || undefined,
    refresh: req.cookies.get(REFRESH_COOKIE)?.value || undefined,
  };
}

/**
 * Returns a usable access token for this request, refreshing first when the
 * current one is missing, expired or about to expire.
 */
export async function ensureAccessToken(
  req: NextRequest,
): Promise<
  | { ok: true; accessToken: string; rotated: SessionTokens | null }
  | { ok: false; ended: boolean; status: number; body: ApiErrorBody }
> {
  const { access, refresh } = readSessionCookies(req);
  if (access && isAccessTokenFresh(access)) return { ok: true, accessToken: access, rotated: null };
  if (!refresh) return { ok: false, ended: true, status: 401, body: SESSION_ENDED };
  const result = await refreshSession(refresh);
  if (!result.ok) return result;
  return { ok: true, accessToken: result.tokens.accessToken, rotated: result.tokens };
}
