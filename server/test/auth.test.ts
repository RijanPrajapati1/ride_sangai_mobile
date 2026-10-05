import { describe, expect, it } from 'vitest';
import { useTestApp } from './helpers/context.js';
import { registerUser } from './helpers/factories.js';

const ctx = useTestApp();

describe('auth', () => {
  it('registers, returns tokens and the AuthUser shape', async () => {
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { name: '  Alex Shrestha ', email: 'Alex@Example.com', password: 'biker1234' },
    });
    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.user).toEqual({
      id: expect.any(String),
      name: 'Alex Shrestha',
      email: 'alex@example.com',
      avatarUrl: '',
      isAdmin: false,
    });
    expect(body.tokenType).toBe('Bearer');
    expect(body.refreshToken).toEqual(expect.any(String));
  });

  it('rejects duplicate emails case-insensitively', async () => {
    await registerUser(ctx.app, { email: 'dup@example.com' });
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { name: 'X', email: 'DUP@example.com', password: 'biker1234' },
    });
    expect(res.statusCode).toBe(409);
    expect(res.json().error.code).toBe('EMAIL_TAKEN');
  });

  it('validates input with field details', async () => {
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { email: 'nope' },
    });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('VALIDATION_ERROR');
  });

  it('logs in and rejects bad credentials with the app message', async () => {
    const user = await registerUser(ctx.app);
    const ok = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: user.email, password: user.password },
    });
    expect(ok.statusCode).toBe(200);
    const bad = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: user.email, password: 'wrong-pass' },
    });
    expect(bad.statusCode).toBe(401);
    expect(bad.json().error.message).toBe('Invalid email or password.');
  });

  it('requires a token by default and returns /auth/me', async () => {
    const user = await registerUser(ctx.app);
    expect((await ctx.app.inject({ method: 'GET', url: '/api/v1/auth/me' })).statusCode).toBe(401);
    const me = await ctx.app.inject({ method: 'GET', url: '/api/v1/auth/me', headers: user.headers });
    expect(me.statusCode).toBe(200);
    expect(me.json().id).toBe(user.id);
  });

  it('rotates refresh tokens and revokes the session on reuse', async () => {
    const user = await registerUser(ctx.app);
    const first = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: user.refreshToken },
    });
    expect(first.statusCode).toBe(200);
    const replay = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: user.refreshToken },
    });
    expect(replay.statusCode).toBe(401);
    expect(replay.json().error.code).toBe('REFRESH_TOKEN_REUSED');
    // The rotated token belonged to the same (now revoked) session.
    const next = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: first.json().refreshToken },
    });
    expect(next.statusCode).toBe(401);
  });

  it('logout revokes the access token immediately', async () => {
    const user = await registerUser(ctx.app);
    const out = await ctx.app.inject({ method: 'POST', url: '/api/v1/auth/logout', headers: user.headers });
    expect(out.statusCode).toBe(204);
    const me = await ctx.app.inject({ method: 'GET', url: '/api/v1/auth/me', headers: user.headers });
    expect(me.statusCode).toBe(401);
    expect(me.json().error.code).toBe('SESSION_REVOKED');
  });

  it('resets a password with an emailed token and signs out everywhere', async () => {
    const user = await registerUser(ctx.app);
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/forgot-password',
      payload: { email: user.email },
    });
    expect(res.statusCode).toBe(202);
    const unknown = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/forgot-password',
      payload: { email: 'nobody@example.com' },
    });
    expect(unknown.statusCode).toBe(202);
    expect(ctx.mailer.passwordResets).toHaveLength(1);
    const token = new URL(ctx.mailer.passwordResets[0]!.resetUrl).searchParams.get('token')!;
    const reset = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/reset-password',
      payload: { token, password: 'new-password-1' },
    });
    expect(reset.statusCode).toBe(204);
    expect(
      (await ctx.app.inject({ method: 'GET', url: '/api/v1/auth/me', headers: user.headers })).statusCode,
    ).toBe(401);
    const login = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: user.email, password: 'new-password-1' },
    });
    expect(login.statusCode).toBe(200);
    const again = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/reset-password',
      payload: { token, password: 'another-pass-2' },
    });
    expect(again.json().error.code).toBe('INVALID_RESET_TOKEN');
  });

  it('serves health and the OpenAPI document publicly', async () => {
    expect((await ctx.app.inject({ method: 'GET', url: '/health' })).statusCode).toBe(200);
    expect((await ctx.app.inject({ method: 'GET', url: '/health/ready' })).json().database).toBe('up');
    const docs = await ctx.app.inject({ method: 'GET', url: '/docs/json' });
    expect(docs.statusCode).toBe(200);
    expect(docs.json().paths['/api/v1/auth/login']).toBeDefined();
  });

  it('answers CORS preflights for protected routes without a token', async () => {
    const res = await ctx.app.inject({
      method: 'OPTIONS',
      url: '/api/v1/auth/me',
      headers: {
        origin: 'http://localhost:5555',
        'access-control-request-method': 'GET',
        'access-control-request-headers': 'authorization',
      },
    });
    expect(res.statusCode).toBe(204);
    expect(res.headers['access-control-allow-origin']).toBe('http://localhost:5555');
  });

  it('returns a consistent 404 envelope for unknown routes', async () => {
    const res = await ctx.app.inject({ method: 'GET', url: '/api/v1/nope' });
    expect(res.statusCode).toBe(404);
    expect(res.json().error.code).toBe('ROUTE_NOT_FOUND');
  });
});
