import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';

/** 256-bit random token, URL-safe. Used for refresh and password-reset tokens. */
export function generateToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url');
}

/**
 * Tokens are stored only as SHA-256 hashes, so a database leak does not leak
 * usable tokens. (They are high-entropy, so a fast hash is appropriate here —
 * unlike passwords.)
 */
export function hashToken(token: string): string {
  return createHash('sha256').update(token, 'utf8').digest('hex');
}

export function safeEqual(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}
