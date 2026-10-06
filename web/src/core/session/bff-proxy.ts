import 'server-only';
import { NextResponse, type NextRequest } from 'next/server';
import { CSRF_ERROR, isSameOrigin } from '@/core/session/csrf';
import {
  API_UNREACHABLE,
  SESSION_ENDED,
  apiFetch,
  clearSessionCookies,
  ensureAccessToken,
  readErrorBody,
  readSessionCookies,
  refreshSession,
  setSessionCookies,
  type SessionTokens,
} from '@/core/session/server-session';
import type { ApiErrorBody } from '@/core/http/errors';

/**
 * Backend-for-frontend proxy: `/api/backend/<path>` → `${API_URL}/<path>`.
 *
 * Only an explicit allowlist is forwarded. The bearer token comes from the
 * httpOnly cookie and is never exposed to the browser.
 */

const SEGMENT = /^[A-Za-z0-9_-]+$/;
const MAX_BODY_BYTES = 1_000_000;

function isAllowed(method: string, segments: string[]): boolean {
  if (segments.length === 0 || segments.length > 6) return false;
  if (!segments.every((s) => SEGMENT.test(s))) return false;
  const path = segments.join('/');
  if (path === 'auth/me') return method === 'GET';
  return segments[0] === 'superadmin' && segments.length >= 2;
}

function errorResponse(body: ApiErrorBody, status: number, opts: { clear?: boolean; rotated?: SessionTokens | null } = {}) {
  const res = NextResponse.json(body, { status, headers: { 'cache-control': 'no-store' } });
  if (opts.clear) clearSessionCookies(res);
  else if (opts.rotated) setSessionCookies(res, opts.rotated);
  return res;
}

export async function bffProxy(req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) {
  const { path: segments } = await ctx.params;
  const method = req.method.toUpperCase();

  if (!isAllowed(method, segments)) {
    return errorResponse({ error: { code: 'NOT_FOUND', message: 'This endpoint is not available.' } }, 404);
  }
  if (!isSameOrigin(req)) return errorResponse(CSRF_ERROR, 403);

  let body: ArrayBuffer | undefined;
  if (method !== 'GET' && method !== 'HEAD') {
    const declared = Number(req.headers.get('content-length') ?? 0);
    if (declared > MAX_BODY_BYTES) {
      return errorResponse({ error: { code: 'PAYLOAD_TOO_LARGE', message: 'The request is too large.' } }, 413);
    }
    body = await req.arrayBuffer();
    if (body.byteLength > MAX_BODY_BYTES) {
      return errorResponse({ error: { code: 'PAYLOAD_TOO_LARGE', message: 'The request is too large.' } }, 413);
    }
    if (body.byteLength === 0) body = undefined;
  }

  const session = await ensureAccessToken(req);
  if (!session.ok) return errorResponse(session.body, session.status, { clear: session.ended });
  let rotated = session.rotated;

  const target = `${segments.join('/')}${req.nextUrl.search}`;
  const send = (accessToken: string) => {
    const headers: Record<string, string> = {
      authorization: `Bearer ${accessToken}`,
      accept: 'application/json',
    };
    if (body) headers['content-type'] = req.headers.get('content-type') ?? 'application/json';
    return apiFetch(target, { method, headers, body });
  };

  let upstream: Response;
  try {
    upstream = await send(session.accessToken);
    if (upstream.status === 401) {
      const err = await readErrorBody(upstream.clone());
      const { refresh } = readSessionCookies(req);
      if (err.error.code === 'TOKEN_EXPIRED' && refresh) {
        // The token expired in flight (or clocks disagree): refresh once and retry.
        const result = await refreshSession(rotated?.refreshToken ?? refresh);
        if (!result.ok) return errorResponse(result.body, result.status, { clear: result.ended });
        rotated = result.tokens;
        upstream = await send(result.tokens.accessToken);
      }
    }
  } catch {
    return errorResponse(API_UNREACHABLE, 502, { rotated });
  }

  if (upstream.status === 401) {
    // Revoked, invalid or otherwise ended session: sign the browser out.
    return errorResponse(SESSION_ENDED, 401, { clear: true });
  }

  const headers = new Headers({ 'cache-control': 'no-store' });
  const contentType = upstream.headers.get('content-type');
  if (contentType) headers.set('content-type', contentType);
  const requestId = upstream.headers.get('x-request-id');
  if (requestId) headers.set('x-request-id', requestId);
  const retryAfter = upstream.headers.get('retry-after');
  if (retryAfter) headers.set('retry-after', retryAfter);

  const hasBody = upstream.status !== 204 && upstream.status !== 304 && method !== 'HEAD';
  const out = new NextResponse(hasBody ? await upstream.arrayBuffer() : null, {
    status: upstream.status,
    headers,
  });
  if (rotated) setSessionCookies(out, rotated);
  return out;
}
