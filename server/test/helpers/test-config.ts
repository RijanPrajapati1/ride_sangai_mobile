import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { loadConfig, loadDotEnv, type AppConfig } from '../../src/config/env.js';

/**
 * Tests run against a separate database: TEST_DATABASE_URL, or DATABASE_URL
 * with `_test` appended to the database name. The name must end in `_test`
 * because the test run drops and recreates its schema.
 */
export function testDatabaseUrl(): string {
  loadDotEnv();
  const explicit = process.env.TEST_DATABASE_URL?.trim();
  let url: URL;
  if (explicit) {
    url = new URL(explicit);
  } else {
    const base = process.env.DATABASE_URL?.trim();
    if (!base) throw new Error('Set TEST_DATABASE_URL (or DATABASE_URL) in server/.env to run the tests');
    url = new URL(base);
    url.pathname = `/${decodeURIComponent(url.pathname.slice(1))}_test`;
  }
  const name = decodeURIComponent(url.pathname.slice(1));
  if (!name.endsWith('_test')) {
    throw new Error(`Refusing to run tests against "${name}": the test database name must end with "_test"`);
  }
  return url.toString();
}

let uploadDir: string | undefined;

export function testConfig(overrides: Record<string, string> = {}): AppConfig {
  uploadDir ??= mkdtempSync(path.join(tmpdir(), 'yatrix-uploads-'));
  return loadConfig({
    ...process.env,
    NODE_ENV: 'test',
    DATABASE_URL: testDatabaseUrl(),
    DB_POOL_MAX: '10',
    LOG_LEVEL: 'silent',
    RATE_LIMIT_ENABLED: 'false',
    JOBS_ENABLED: 'false',
    DOCS_ENABLED: 'true',
    REALTIME_PG_FANOUT: 'false',
    AUTH_SESSION_CACHE_TTL_MS: '0',
    PUBLIC_URL: 'http://localhost:4000',
    UPLOAD_DIR: uploadDir,
    ...overrides,
  });
}
