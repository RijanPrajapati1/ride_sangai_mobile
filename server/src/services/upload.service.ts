import { randomUUID } from 'node:crypto';
import type { UploadRepository } from '../repositories/upload.repository.js';
import { AppError, notFound } from '../utils/errors.js';
import { sniffImage, type FileStorage } from '../utils/storage.js';

export type UploadPurpose = 'avatar' | 'rideCover' | 'post' | 'groupCover' | 'other';

/** Image uploads (avatars, ride covers, post images, group covers). */
export class UploadService {
  constructor(
    private readonly repo: UploadRepository,
    private readonly storage: FileStorage,
  ) {}

  async upload(ownerId: string, data: Buffer, purpose: UploadPurpose | null) {
    const image = sniffImage(data);
    if (!image) throw new AppError(415, 'UNSUPPORTED_MEDIA_TYPE', 'Only JPEG, PNG, WebP and GIF images can be uploaded.');
    const id = randomUUID();
    const now = new Date();
    const key = `${now.getUTCFullYear()}/${String(now.getUTCMonth() + 1).padStart(2, '0')}/${id}.${image.ext}`;
    await this.storage.save(key, data, image.contentType);
    try {
      const record = await this.repo.create({ id, ownerId, storageKey: key, contentType: image.contentType, sizeBytes: data.length, purpose });
      return { id: record.id, url: this.storage.publicUrl(key), contentType: record.contentType, sizeBytes: record.sizeBytes, purpose: record.purpose };
    } catch (err) {
      await this.storage.remove(key);
      throw err;
    }
  }

  async remove(ownerId: string, id: string): Promise<void> {
    const upload = await this.repo.findOwned(id, ownerId);
    if (!upload) throw notFound('This upload could not be found.', 'UPLOAD_NOT_FOUND');
    await this.repo.delete(id);
    await this.storage.remove(upload.storageKey);
  }
}
