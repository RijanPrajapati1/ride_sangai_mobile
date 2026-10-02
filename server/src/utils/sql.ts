/**
 * Builds positional parameters for dynamic SQL without string-concatenating
 * values: `const p = new SqlParams(); where.push(\`category = ${p.add(cat)}\`)`.
 */
export class SqlParams {
  readonly values: unknown[] = [];

  add(value: unknown): string {
    this.values.push(value);
    return `$${this.values.length}`;
  }
}

/** Escapes LIKE wildcards in user input for `ILIKE '%' || $1 || '%'`. */
export function likeEscape(input: string): string {
  return input.replace(/[\\%_]/g, (ch) => `\\${ch}`);
}

/** Trims every entry, drops empties and case-insensitive duplicates (keeps the first). */
export function cleanList(items: readonly string[] | undefined): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of items ?? []) {
    const item = raw.trim();
    const key = item.toLowerCase();
    if (!item || seen.has(key)) continue;
    seen.add(key);
    out.push(item);
  }
  return out;
}
