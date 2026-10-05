import pg from 'pg';
import type { AppConfig } from '../config/env.js';

/**
 * Creates the node-postgres pool every database query goes through
 * (pool size, statement timeout, application name).
 */
export function createPool(config: AppConfig['db'], applicationName = 'ride-sangai-api'): pg.Pool {
  const pool = new pg.Pool({
    connectionString: config.url,
    max: config.poolMax,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
    application_name: applicationName,
    ssl: config.ssl ? { rejectUnauthorized: false } : undefined,
    ...(config.statementTimeoutMs > 0 ? { statement_timeout: config.statementTimeoutMs } : {}),
    idle_in_transaction_session_timeout: 60_000,
    // Every session runs in UTC. The Prisma pg adapter reads/writes timestamps
    // without their offset, so a non-UTC server timezone (e.g. Asia/Kathmandu)
    // would otherwise shift times written by Prisma against SQL now().
    options: '-c TimeZone=UTC',
  });
  // An idle client erroring (e.g. the server restarted) must not crash the process.
  pool.on('error', (err) => console.error('Unexpected error on idle Postgres client', err));
  return pool;
}
