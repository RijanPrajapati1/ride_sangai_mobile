import { Type } from 'typebox';
import { badRequest } from './errors.js';

/**
 * Keyset (cursor) pagination.
 *
 * Offset pagination gets slower the deeper you page and skips/duplicates rows
 * when new ones are inserted; keyset pagination is O(log n) per page and
 * stable. A cursor is an opaque base64url string encoding the sort key of the
 * last row on the previous page, e.g. `[createdAtIso, id]`.
 *
 * Usage in a repository:
 *   const after = decodeCursor(query.cursor, ['string', 'string']);
 *   const rows = await db.many(`... WHERE ($1::timestamptz IS NULL OR (created_at, id) < ($1, $2))
 *                               ORDER BY created_at DESC, id DESC LIMIT $3`,
 *                              [after?.[0] ?? null, after?.[1] ?? null, limit + 1]);
 *   return toPage(rows, limit, (row) => [row.created_at.toISOString(), row.id]);
 *
 * All timestamp columns are `timestamptz(3)` (millisecond precision), so a JS
 * Date round-trips through a cursor exactly.
 */

export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

/** Spread into a querystring schema: `Type.Object({ ...paginationQuery, q: ... })`. */
export const paginationQuery = {
  limit: Type.Optional(
    Type.Integer({ minimum: 1, maximum: MAX_PAGE_SIZE, default: DEFAULT_PAGE_SIZE, description: 'Page size (1-100).' }),
  ),
  cursor: Type.Optional(
    Type.String({ maxLength: 512, description: 'Opaque cursor from the previous page\'s `nextCursor`.' }),
  ),
};

export type CursorPart = string | number | boolean | null;
type CursorKind = 'string' | 'number' | 'boolean' | 'nullable-string' | 'nullable-number';

export interface Page<T> {
  items: T[];
  nextCursor: string | null;
}

export function encodeCursor(values: readonly CursorPart[]): string {
  return Buffer.from(JSON.stringify(values), 'utf8').toString('base64url');
}

/**
 * Decodes and shape-checks a cursor. Returns `null` when no cursor was given;
 * throws 400 INVALID_CURSOR for anything tampered with or malformed.
 */
export function decodeCursor(cursor: string | undefined, shape: readonly CursorKind[]): CursorPart[] | null {
  if (cursor === undefined || cursor === '') return null;
  let parsed: unknown;
  try {
    parsed = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
  } catch {
    throw invalidCursor();
  }
  if (!Array.isArray(parsed) || parsed.length !== shape.length) throw invalidCursor();
  parsed.forEach((value: unknown, index) => {
    const kind = shape[index]!;
    const nullable = kind.startsWith('nullable-');
    if (value === null && nullable) return;
    const base = nullable ? kind.slice('nullable-'.length) : kind;
    if (typeof value !== base) throw invalidCursor();
    if (base === 'number' && !Number.isFinite(value)) throw invalidCursor();
    if (base === 'string' && (value as string).length > 256) throw invalidCursor();
  });
  return parsed as CursorPart[];
}

function invalidCursor() {
  return badRequest('The pagination cursor is invalid or expired.', 'INVALID_CURSOR');
}

/**
 * Turns `limit + 1` fetched rows into a page: trims the probe row and derives
 * `nextCursor` from the last row that is returned.
 */
export function toPage<Row, Item = Row>(
  rows: Row[],
  limit: number,
  cursorOf: (row: Row) => readonly CursorPart[],
  map?: (row: Row) => Item,
): Page<Item> {
  const hasMore = rows.length > limit;
  const pageRows = hasMore ? rows.slice(0, limit) : rows;
  const last = pageRows[pageRows.length - 1];
  return {
    items: map ? pageRows.map(map) : (pageRows as unknown as Item[]),
    nextCursor: hasMore && last !== undefined ? encodeCursor(cursorOf(last)) : null,
  };
}

export function pageLimit(limit: number | undefined): number {
  return Math.min(Math.max(limit ?? DEFAULT_PAGE_SIZE, 1), MAX_PAGE_SIZE);
}

/** Decodes the common `[isoTimestamp, id]` cursor into a Date and an id. */
export function decodeTimeCursor(cursor: string | undefined): [Date, string] | null {
  const parts = decodeCursor(cursor, ['string', 'string']);
  if (!parts) return null;
  const date = new Date(parts[0] as string);
  if (Number.isNaN(date.getTime())) throw invalidCursor();
  return [date, parts[1] as string];
}

/** Encodes the common `[isoTimestamp, id]` cursor. */
export function timeCursor(date: Date, id: string): CursorPart[] {
  return [date.toISOString(), id];
}
