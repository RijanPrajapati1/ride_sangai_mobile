import { mkdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';

/**
 * Where uploaded files live. LocalDiskStorage serves them from this server;
 * an S3/GCS implementation of the same interface can replace it without
 * touching the upload service.
 */
export interface FileStorage {
  save(key: string, data: Buffer, contentType: string): Promise<void>;
  remove(key: string): Promise<void>;
  publicUrl(key: string): string;
}

export class LocalDiskStorage implements FileStorage {
  constructor(
    private readonly dir: string,
    private readonly baseUrl: string,
  ) {}

  async save(key: string, data: Buffer): Promise<void> {
    const file = this.resolve(key);
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, data, { flag: 'wx' });
  }

  async remove(key: string): Promise<void> {
    await rm(this.resolve(key), { force: true });
  }

  publicUrl(key: string): string {
    return `${this.baseUrl}/uploads/${key}`;
  }

  private resolve(key: string): string {
    const file = path.resolve(this.dir, key);
    if (!file.startsWith(path.resolve(this.dir) + path.sep)) throw new Error('Invalid storage key');
    return file;
  }
}

/** Detects common image formats from their magic bytes (never trust the client's Content-Type). */
export function sniffImage(data: Buffer): { contentType: string; ext: string } | null {
  if (data.length >= 3 && data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff) return { contentType: 'image/jpeg', ext: 'jpg' };
  if (data.length >= 8 && data.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return { contentType: 'image/png', ext: 'png' };
  }
  if (data.length >= 12 && data.toString('ascii', 0, 4) === 'RIFF' && data.toString('ascii', 8, 12) === 'WEBP') {
    return { contentType: 'image/webp', ext: 'webp' };
  }
  if (data.length >= 6 && /^GIF8[79]a$/.test(data.toString('ascii', 0, 6))) return { contentType: 'image/gif', ext: 'gif' };
  return null;
}
