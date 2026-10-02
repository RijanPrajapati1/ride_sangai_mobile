import type { App } from '../../src/app.js';
import type { PrismaClient } from '../../src/db/prisma.js';

export interface TestUser {
  id: string;
  name: string;
  email: string;
  password: string;
  accessToken: string;
  refreshToken: string;
  /** Spread into `inject({ headers })`. */
  headers: { authorization: string };
}

let counter = 0;

/** Registers a user through the real API and returns their tokens. */
export async function registerUser(
  app: App,
  overrides: Partial<{ name: string; email: string; password: string }> = {},
): Promise<TestUser> {
  counter += 1;
  const input = {
    name: overrides.name ?? `Rider ${counter}`,
    email: overrides.email ?? `rider${counter}.${Date.now()}@example.com`,
    password: overrides.password ?? 'correct-horse-battery',
  };
  const res = await app.inject({ method: 'POST', url: '/api/v1/auth/register', payload: input });
  if (res.statusCode !== 201) throw new Error(`registerUser failed (${res.statusCode}): ${res.body}`);
  const body = res.json() as { user: { id: string }; accessToken: string; refreshToken: string };
  return {
    id: body.user.id,
    name: input.name,
    email: input.email.toLowerCase(),
    password: input.password,
    accessToken: body.accessToken,
    refreshToken: body.refreshToken,
    headers: { authorization: `Bearer ${body.accessToken}` },
  };
}

/** Registers a user and promotes them to admin (takes effect on their next request). */
export async function registerAdmin(app: App, prisma: PrismaClient, overrides: Parameters<typeof registerUser>[1] = {}) {
  const user = await registerUser(app, { name: 'Admin', ...overrides });
  await prisma.user.update({ where: { id: user.id }, data: { role: 'admin' } });
  return user;
}

/** ISO timestamp `days` from now (negative for the past). */
export function daysFromNow(days: number, hour = 7): string {
  const date = new Date(Date.now() + days * 86_400_000);
  date.setUTCHours(hour, 0, 0, 0);
  return date.toISOString();
}
