import { badRequest } from './errors.js';

/** Accepts an http(s) URL, or '' to clear the image. */
export function assertImageUrl(url: string, field: string): void {
  if (url !== '' && !/^https?:\/\/\S+$/i.test(url)) {
    throw badRequest(`${field} must be an http(s) URL.`, 'VALIDATION_ERROR', [{ field, message: 'must be an http(s) URL' }]);
  }
}

/** Trims and turns blank strings into null. */
export function blankToNull(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}
