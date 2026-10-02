import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import type { AppConfig } from '../config/env.js';
import { Prisma, PrismaClient } from '../generated/prisma/client.js';
import { isRetryableTransactionError } from '../utils/db-errors.js';

export { Prisma, PrismaClient };

/** The client itself or an interactive-transaction client. Repositories accept either. */
export type Db = PrismaClient | Prisma.TransactionClient;

/**
 * Creates the Prisma client on top of a node-postgres pool we configure
 * ourselves (pool size, statement timeout, application name).
 */
export function createPrisma(config: AppConfig['db'], applicationName = 'ride-sangai-api'): PrismaClient {
  const pool = new pg.Pool({
    connectionString: config.url,
    max: config.poolMax,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
    application_name: applicationName,
    ssl: config.ssl ? { rejectUnauthorized: false } : undefined,
    ...(config.statementTimeoutMs > 0 ? { statement_timeout: config.statementTimeoutMs } : {}),
    idle_in_transaction_session_timeout: 60_000,
  });
  // An idle client erroring (e.g. the server restarted) must not crash the process.
  pool.on('error', (err) => console.error('Unexpected error on idle Postgres client', err));
  return new PrismaClient({ adapter: new PrismaPg(pool, { disposeExternalPool: true }) });
}

type AfterCommit = () => void | Promise<void>;

/**
 * What a service passes down to repositories and the notification service:
 * the client to query with, plus `afterCommit` for side effects (realtime
 * pushes, emails) that must only happen once the data is committed.
 */
export interface TxContext {
  db: Db;
  afterCommit(callback: AfterCommit): void;
}

function runDetached(callback: AfterCommit): void {
  try {
    const result = callback();
    if (result instanceof Promise)
      result.catch((err: unknown) => console.error('afterCommit callback failed', err));
  } catch (err) {
    console.error('afterCommit callback failed', err);
  }
}

export interface TransactionOptions {
  isolationLevel?: Prisma.TransactionIsolationLevel;
  /** Retries on write conflicts / deadlocks / serialization failures (default 3). */
  retries?: number;
}

/** Runs units of work in interactive transactions. */
export class UnitOfWork {
  constructor(readonly prisma: PrismaClient) {}

  /** Context for work outside a transaction; `afterCommit` callbacks run immediately. */
  get direct(): TxContext {
    return { db: this.prisma, afterCommit: runDetached };
  }

  async run<T>(work: (ctx: TxContext) => Promise<T>, options: TransactionOptions = {}): Promise<T> {
    const retries = options.retries ?? 3;
    for (let attempt = 0; ; attempt++) {
      const queue: AfterCommit[] = [];
      try {
        const result = await this.prisma.$transaction(
          (tx) => work({ db: tx, afterCommit: (callback) => queue.push(callback) }),
          {
            maxWait: 5_000,
            timeout: 15_000,
            ...(options.isolationLevel ? { isolationLevel: options.isolationLevel } : {}),
          },
        );
        for (const callback of queue) runDetached(callback);
        return result;
      } catch (err) {
        if (isRetryableTransactionError(err) && attempt < retries) {
          await new Promise((resolve) =>
            setTimeout(resolve, 10 * 2 ** attempt + Math.floor(Math.random() * 10)),
          );
          continue;
        }
        throw err;
      }
    }
  }
}
