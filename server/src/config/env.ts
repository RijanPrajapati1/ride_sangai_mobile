import { existsSync } from 'node:fs';
import path from 'node:path';

/**
 * Typed, validated runtime configuration.
 *
 * Every setting is read from environment variables (optionally loaded from
 * `server/.env`). Invalid values fail fast at boot with one aggregated error
 * instead of surfacing later as confusing runtime bugs.
 */

export type NodeEnv = 'development' | 'test' | 'production';

export interface AppConfig {
  env: NodeEnv;
  isProduction: boolean;
  host: string;
  port: number;
  logLevel: string;
  /** Public base URL of this API, used to build absolute links (uploads, emails). */
  publicUrl: string;
  trustProxy: boolean;
  /** `true` allows any origin (fine for native mobile clients); otherwise an allow-list. */
  corsOrigins: true | string[];
  bodyLimitBytes: number;
  db: {
    url: string;
    poolMax: number;
    statementTimeoutMs: number;
    ssl: boolean;
  };
  auth: {
    accessTokenSecret: string;
    accessTokenTtlSeconds: number;
    refreshTokenTtlDays: number;
    issuer: string;
    /** How long a verified session lookup is cached in memory (0 disables). */
    sessionCacheTtlMs: number;
    passwordResetTtlMinutes: number;
    /** Link the password-reset email points to; `{token}` is replaced. */
    passwordResetUrl: string;
    hash: { memoryCostKib: number; timeCost: number };
  };
  rateLimit: {
    enabled: boolean;
    max: number;
    windowMs: number;
    /** Stricter per-IP budget for credential endpoints (login, register, reset). */
    authMax: number;
  };
  uploads: {
    dir: string;
    maxBytes: number;
  };
  docs: { enabled: boolean };
  jobs: { enabled: boolean; rideReminderLeadMinutes: number };
  realtime: {
    enabled: boolean;
    /** Fan realtime events out across instances with Postgres LISTEN/NOTIFY. */
    pgFanout: boolean;
  };
}

const DEV_JWT_SECRET = 'dev-only-insecure-secret-change-me-0123456789abcdef';

type Env = Record<string, string | undefined>;

class ConfigReader {
  readonly errors: string[] = [];

  constructor(private readonly env: Env) {}

  private raw(name: string): string | undefined {
    const value = this.env[name];
    if (value === undefined) return undefined;
    const trimmed = value.trim();
    return trimmed === '' ? undefined : trimmed;
  }

  string(name: string, fallback?: string): string {
    const value = this.raw(name) ?? fallback;
    if (value === undefined) {
      this.errors.push(`${name} is required`);
      return '';
    }
    return value;
  }

  optionalString(name: string): string | undefined {
    return this.raw(name);
  }

  int(name: string, fallback: number, { min = -Infinity, max = Infinity } = {}): number {
    const value = this.raw(name);
    if (value === undefined) return fallback;
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
      this.errors.push(`${name} must be an integer between ${min} and ${max} (got "${value}")`);
      return fallback;
    }
    return parsed;
  }

  bool(name: string, fallback: boolean): boolean {
    const value = this.raw(name);
    if (value === undefined) return fallback;
    const normalized = value.toLowerCase();
    if (['1', 'true', 'yes', 'on'].includes(normalized)) return true;
    if (['0', 'false', 'no', 'off'].includes(normalized)) return false;
    this.errors.push(`${name} must be a boolean (got "${value}")`);
    return fallback;
  }

  oneOf<T extends string>(name: string, allowed: readonly T[], fallback: T): T {
    const value = this.raw(name);
    if (value === undefined) return fallback;
    if (!(allowed as readonly string[]).includes(value)) {
      this.errors.push(`${name} must be one of ${allowed.join(', ')} (got "${value}")`);
      return fallback;
    }
    return value as T;
  }
}

/** Loads `server/.env` (or `$DOTENV_PATH`) into `process.env` without overriding existing variables. */
export function loadDotEnv(file = process.env.DOTENV_PATH ?? path.resolve(process.cwd(), '.env')): void {
  if (existsSync(file)) process.loadEnvFile(file);
}

export function loadConfig(env: Env = process.env): AppConfig {
  const r = new ConfigReader(env);
  const nodeEnv = r.oneOf<NodeEnv>('NODE_ENV', ['development', 'test', 'production'], 'development');
  const isProduction = nodeEnv === 'production';
  const isTest = nodeEnv === 'test';

  const port = r.int('PORT', 4000, { min: 0, max: 65535 });
  const host = r.string('HOST', '0.0.0.0');

  let accessTokenSecret = r.optionalString('JWT_ACCESS_SECRET');
  if (!accessTokenSecret) {
    if (isProduction) r.errors.push('JWT_ACCESS_SECRET is required in production');
    accessTokenSecret = DEV_JWT_SECRET;
  } else if (accessTokenSecret.length < 32) {
    r.errors.push('JWT_ACCESS_SECRET must be at least 32 characters');
  }

  const corsRaw = r.string('CORS_ORIGINS', '*');
  const corsOrigins: true | string[] =
    corsRaw === '*'
      ? true
      : corsRaw
          .split(',')
          .map((origin) => origin.trim())
          .filter(Boolean);

  const publicUrl = r.string('PUBLIC_URL', `http://localhost:${port}`).replace(/\/+$/, '');

  const config: AppConfig = {
    env: nodeEnv,
    isProduction,
    host,
    port,
    logLevel: r.oneOf(
      'LOG_LEVEL',
      ['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'],
      isTest ? 'silent' : 'info',
    ),
    publicUrl,
    trustProxy: r.bool('TRUST_PROXY', false),
    corsOrigins,
    bodyLimitBytes: r.int('BODY_LIMIT_BYTES', 1_048_576, { min: 1024 }),
    db: {
      url: r.string('DATABASE_URL'),
      poolMax: r.int('DB_POOL_MAX', 20, { min: 1, max: 500 }),
      statementTimeoutMs: r.int('DB_STATEMENT_TIMEOUT_MS', 10_000, { min: 0 }),
      ssl: r.bool('DB_SSL', false),
    },
    auth: {
      accessTokenSecret,
      accessTokenTtlSeconds: r.int('JWT_ACCESS_TTL_SECONDS', 900, { min: 60, max: 86_400 }),
      refreshTokenTtlDays: r.int('REFRESH_TOKEN_TTL_DAYS', 30, { min: 1, max: 365 }),
      issuer: r.string('JWT_ISSUER', 'yatrix'),
      sessionCacheTtlMs: r.int('AUTH_SESSION_CACHE_TTL_MS', isTest ? 0 : 5_000, { min: 0, max: 60_000 }),
      passwordResetTtlMinutes: r.int('PASSWORD_RESET_TTL_MINUTES', 30, { min: 5, max: 1_440 }),
      passwordResetUrl: r.string('PASSWORD_RESET_URL', 'yatrix://reset-password?token={token}'),
      hash: {
        // OWASP-recommended argon2id baseline; tests use cheap params to stay fast.
        memoryCostKib: r.int('PASSWORD_HASH_MEMORY_KIB', isTest ? 1024 : 19_456, { min: 1024 }),
        timeCost: r.int('PASSWORD_HASH_TIME_COST', isTest ? 1 : 2, { min: 1, max: 10 }),
      },
    },
    rateLimit: {
      enabled: r.bool('RATE_LIMIT_ENABLED', !isTest),
      max: r.int('RATE_LIMIT_MAX', 300, { min: 1 }),
      windowMs: r.int('RATE_LIMIT_WINDOW_MS', 60_000, { min: 1000 }),
      authMax: r.int('RATE_LIMIT_AUTH_MAX', 10, { min: 1 }),
    },
    uploads: {
      dir: path.resolve(r.string('UPLOAD_DIR', './uploads')),
      maxBytes: r.int('UPLOAD_MAX_BYTES', 5 * 1024 * 1024, { min: 1024 }),
    },
    docs: { enabled: r.bool('DOCS_ENABLED', !isProduction) },
    jobs: {
      enabled: r.bool('JOBS_ENABLED', !isTest),
      rideReminderLeadMinutes: r.int('RIDE_REMINDER_LEAD_MINUTES', 120, { min: 5, max: 2_880 }),
    },
    realtime: {
      enabled: r.bool('REALTIME_ENABLED', true),
      pgFanout: r.bool('REALTIME_PG_FANOUT', false),
    },
  };

  if (r.errors.length > 0) {
    throw new Error(`Invalid configuration:\n  - ${r.errors.join('\n  - ')}`);
  }
  return Object.freeze(config);
}
