/**
 * Classifies database errors coming through Prisma (with the pg driver
 * adapter). Prisma reports constraint violations as `P2xxx` codes; anything
 * raised by Postgres itself (CHECK constraints, triggers, timeouts) carries
 * the SQLSTATE in the driver adapter error.
 */

interface ErrorLike {
  code?: unknown;
  meta?: { driverAdapterError?: { cause?: { originalCode?: string; kind?: string } }; modelName?: string; target?: unknown };
  cause?: { originalCode?: string; code?: unknown };
}

export const PgCode = {
  uniqueViolation: '23505',
  foreignKeyViolation: '23503',
  checkViolation: '23514',
  notNullViolation: '23502',
  invalidTextRepresentation: '22P02',
  stringTooLong: '22001',
  serializationFailure: '40001',
  deadlockDetected: '40P01',
  queryCanceled: '57014',
} as const;

/** Prisma error code (e.g. P2002) if any. */
export function prismaCode(err: unknown): string | undefined {
  const code = (err as ErrorLike | null)?.code;
  return typeof code === 'string' && /^P\d{4}$/.test(code) ? code : undefined;
}

/** Postgres SQLSTATE (e.g. 23514) if the error came from the database. */
export function pgCode(err: unknown): string | undefined {
  const e = err as ErrorLike | null;
  if (!e) return undefined;
  const candidates = [e.meta?.driverAdapterError?.cause?.originalCode, e.cause?.originalCode, e.cause?.code, e.code];
  return candidates.find((c): c is string => typeof c === 'string' && /^[0-9A-Z]{5}$/.test(c));
}

export function isUniqueViolation(err: unknown): boolean {
  return prismaCode(err) === 'P2002' || pgCode(err) === PgCode.uniqueViolation;
}

export function isCheckViolation(err: unknown): boolean {
  return pgCode(err) === PgCode.checkViolation || prismaCode(err) === 'P2004';
}

/** Prisma "record to update/delete not found". */
export function isNotFound(err: unknown): boolean {
  return prismaCode(err) === 'P2025';
}

export function isRetryableTransactionError(err: unknown): boolean {
  const code = pgCode(err);
  return prismaCode(err) === 'P2034' || code === PgCode.serializationFailure || code === PgCode.deadlockDetected;
}
