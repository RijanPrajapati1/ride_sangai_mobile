import { afterAll, beforeAll, beforeEach } from 'vitest';
import { buildApp, type App } from '../../src/app.js';
import type { AppConfig } from '../../src/config/env.js';
import { createPrisma, type PrismaClient } from '../../src/db/prisma.js';
import { MemoryMailer } from '../../src/utils/mailer.js';
import { testConfig } from './test-config.js';

export interface TestContext {
  app: App;
  prisma: PrismaClient;
  mailer: MemoryMailer;
  config: AppConfig;
}

/** Empties every table (except Prisma's migrations ledger) between tests. */
export async function resetDatabase(prisma: PrismaClient): Promise<void> {
  const tables = await prisma.$queryRaw<Array<{ tablename: string }>>`
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`;
  if (tables.length === 0) return;
  await prisma.$executeRawUnsafe(
    `TRUNCATE ${tables.map((t) => `"${t.tablename}"`).join(', ')} RESTART IDENTITY CASCADE`,
  );
}

/**
 * Standard per-file setup: one app for the whole file, a clean database
 * before every test.
 *
 *   const ctx = useTestApp();
 *   it('works', async () => { const res = await ctx.app.inject({ ... }) });
 */
export function useTestApp(configOverrides: Record<string, string> = {}): TestContext {
  const ctx = {} as TestContext;

  beforeAll(async () => {
    ctx.config = testConfig(configOverrides);
    ctx.prisma = createPrisma(ctx.config.db);
    ctx.mailer = new MemoryMailer();
    ctx.app = await buildApp(ctx.config, { prisma: ctx.prisma, mailer: ctx.mailer, logger: false });
    await ctx.app.ready();
  });

  beforeEach(async () => {
    await resetDatabase(ctx.prisma);
    ctx.mailer.passwordResets.length = 0;
  });

  afterAll(async () => {
    await ctx.app?.close();
    await ctx.prisma?.$disconnect();
  });

  return ctx;
}
