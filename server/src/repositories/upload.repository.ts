import type { PrismaClient } from '../db/prisma.js';

type Purpose = 'avatar' | 'rideCover' | 'post' | 'groupCover' | 'other';

/** Data access for uploaded file records. */
export class UploadRepository {
  constructor(private readonly prisma: PrismaClient) {}

  create(data: {
    id: string;
    ownerId: string;
    storageKey: string;
    contentType: string;
    sizeBytes: number;
    purpose: Purpose | null;
  }) {
    return this.prisma.upload.create({ data });
  }

  findOwned(id: string, ownerId: string) {
    return this.prisma.upload.findFirst({ where: { id, ownerId } });
  }

  async delete(id: string): Promise<void> {
    await this.prisma.upload.deleteMany({ where: { id } });
  }
}
