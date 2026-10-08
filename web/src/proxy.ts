import { NextResponse, type NextRequest } from 'next/server';
import { ACCESS_COOKIE, ACCESS_COOKIE_PATH, REFRESH_COOKIE, REFRESH_COOKIE_PATH } from '@/core/session/cookies';

/**
 * Runs before every page render:
 * 1. Route protection — pages need a session cookie, otherwise → /login.
 *    (The session itself is validated by the BFF on every data request.)
 * 2. A per-request nonce-based Content-Security-Policy for scripts.
 */

const PUBLIC_PATHS = new Set(['/login']);

function buildCsp(nonce: string): string {
  const isDev = process.env.NODE_ENV !== 'production';
  return [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${isDev ? " 'unsafe-eval'" : ''}`,
    // Inline style attributes are used by Radix and Recharts.
    `style-src 'self' 'unsafe-inline'`,
    // Avatars, place photos and banner images can be hosted anywhere (https).
    `img-src 'self' data: blob: https:${isDev ? ' http:' : ''}`,
    `font-src 'self' data:`,
    `connect-src 'self'${isDev ? ' ws: wss:' : ''}`,
    `object-src 'none'`,
    `base-uri 'self'`,
    `form-action 'self'`,
    `frame-ancestors 'none'`,
    ...(isDev ? [] : ['upgrade-insecure-requests']),
  ].join('; ');
}

export function proxy(req: NextRequest) {
  const { pathname, search } = req.nextUrl;
  const hasSession = !!req.cookies.get(ACCESS_COOKIE)?.value;

  if (!hasSession && !PUBLIC_PATHS.has(pathname)) {
    const url = req.nextUrl.clone();
    url.pathname = '/login';
    url.search = '';
    if (pathname !== '/') url.searchParams.set('next', `${pathname}${search}`);
    return NextResponse.redirect(url);
  }
  // The app sent us here because the session is dead (expired / forbidden /
  // signed out), so a leftover cookie must not bounce us back to '/': that
  // loops forever. Show the form and drop the stale cookies instead.
  const sessionEnded = pathname === '/login' && req.nextUrl.searchParams.has('reason');
  if (hasSession && pathname === '/login' && !sessionEnded) {
    const url = req.nextUrl.clone();
    url.pathname = '/';
    url.search = '';
    return NextResponse.redirect(url);
  }

  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const csp = buildCsp(nonce);
  const requestHeaders = new Headers(req.headers);
  requestHeaders.set('x-nonce', nonce);
  requestHeaders.set('Content-Security-Policy', csp);

  const res = NextResponse.next({ request: { headers: requestHeaders } });
  res.headers.set('Content-Security-Policy', csp);
  if (hasSession && sessionEnded) {
    res.cookies.set(ACCESS_COOKIE, '', { path: ACCESS_COOKIE_PATH, maxAge: 0 });
    res.cookies.set(REFRESH_COOKIE, '', { path: REFRESH_COOKIE_PATH, maxAge: 0 });
  }
  return res;
}

export const config = {
  // Pages only: skip route handlers, Next internals and static files.
  matcher: ['/((?!api/|_next/static|_next/image|favicon.ico|icon.svg|.*\\.(?:png|jpg|jpeg|svg|webp|ico|txt)$).*)'],
};
