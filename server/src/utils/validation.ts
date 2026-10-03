import { badRequest } from './errors.js';

/** Accepts an http(s) URL, or '' to clear the image. */
export function assertImageUrl(url: string, field: string): void {
  if (url !== '' && !/^https?:\/\/\S+$/i.test(url)) {
    throw badRequest(`${field} must be an http(s) URL.`, 'VALIDATION_ERROR', [
      { field, message: 'must be an http(s) URL' },
    ]);
  }
}

/** Trims and turns blank strings into null. */
export function blankToNull(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
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
