import { execFileSync } from 'node:child_process';
import pg from 'pg';
import { testDatabaseUrl } from './test-config.js';

/**
 * Runs once per `vitest run`: creates the test database if needed, wipes its
 * schema and applies the Prisma migrations, so tests always run against the
 * current schema.
 */
export default async function globalSetup(): Promise<void> {
  const url = testDatabaseUrl();
  const name = decodeURIComponent(new URL(url).pathname.slice(1));

  const adminUrl = new URL(url);
  adminUrl.pathname = '/postgres';
  const admin = new pg.Client({ connectionString: adminUrl.toString() });
  await admin.connect();
  try {
    const exists = await admin.query('SELECT 1 FROM pg_database WHERE datname = $1', [name]);
    if (!exists.rowCount) await admin.query(`CREATE DATABASE "${name.replaceAll('"', '""')}"`);
  } finally {
    await admin.end();
  }

  const client = new pg.Client({ connectionString: url });
  await client.connect();
  try {
    await client.query('DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;');
  } finally {
    await client.end();
  }

  execFileSync('npx', ['prisma', 'migrate', 'deploy'], {
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'pipe',
  });
}
