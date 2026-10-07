import 'server-only';
import { NextResponse, type NextRequest } from 'next/server';
import { z } from 'zod';
import { CSRF_ERROR, isSameOrigin } from '@/core/session/csrf';
import {
  API_UNREACHABLE,
  apiFetch,
  clearSessionCookies,
  readErrorBody,
  setSessionCookies,
  tokensFromAuth,
} from '@/core/session/server-session';
import type { TokenEnvelope } from '@/core/session/tokens';

const LoginBody = z.object({
  email: z.string().trim().email().max(254),
  password: z.string().min(1).max(128),
});

function json(body: unknown, status: number) {
  return NextResponse.json(body, { status, headers: { 'cache-control': 'no-store' } });
}

export async function handleLogin(req: NextRequest) {
  if (!isSameOrigin(req)) return json(CSRF_ERROR, 403);

  let input: z.infer<typeof LoginBody>;
  try {
    input = LoginBody.parse(await req.json());
  } catch {
    return json({ error: { code: 'VALIDATION_ERROR', message: 'Enter a valid email and password.' } }, 400);
  }

  let res: Response;
  try {
    res = await apiFetch('auth/login', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        accept: 'application/json',
        'user-agent': req.headers.get('user-agent')?.slice(0, 300) ?? 'yatrix-web',
      },
      body: JSON.stringify(input),
    });
  } catch {
    return json(API_UNREACHABLE, 502);
  }

  if (!res.ok) return json(await readErrorBody(res), res.status);

  const auth = (await res.json()) as TokenEnvelope;
  if (!auth.user?.isSuperadmin) {
    // Valid rider credentials, but not a superadmin: end the session we just created.
    await apiFetch('auth/logout', {
      method: 'POST',
      headers: { authorization: `Bearer ${auth.accessToken}` },
    }).catch(() => undefined);
    const out = json(
      {
        error: {
          code: 'NOT_SUPERADMIN',
          message: 'This account does not have superadmin access. Use the Yatrix app instead.',
        },
      },
      403,
    );
    clearSessionCookies(out);
    return out;
  }

  const out = json({ user: auth.user }, 200);
  setSessionCookies(out, tokensFromAuth(auth));
  return out;
}
