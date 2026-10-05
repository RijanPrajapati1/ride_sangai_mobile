import 'server-only';
import { NextResponse, type NextRequest } from 'next/server';
import { CSRF_ERROR, isSameOrigin } from '@/core/session/csrf';
import { apiFetch, clearSessionCookies, ensureAccessToken } from '@/core/session/server-session';

export async function handleLogout(req: NextRequest) {
  if (!isSameOrigin(req)) return NextResponse.json(CSRF_ERROR, { status: 403 });

  // Best effort: end the session on the API, then always clear the cookies.
  const session = await ensureAccessToken(req);
  if (session.ok) {
    await apiFetch('auth/logout', {
      method: 'POST',
      headers: { authorization: `Bearer ${session.accessToken}` },
    }).catch(() => undefined);
  }

  const out = new NextResponse(null, { status: 204, headers: { 'cache-control': 'no-store' } });
  clearSessionCookies(out);
  return out;
}
