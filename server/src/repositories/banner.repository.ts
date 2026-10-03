import type { ActivityCategory } from '../constants/enums.js';
import type { PrismaClient } from '../db/prisma.js';
import type { Prisma } from '../db/prisma.js';

/** Data access for home-screen banners. */
export class BannerRepository {
  constructor(private readonly prisma: PrismaClient) {}

  /** Active banners for a category (or all categories), within their schedule window. */
  active(category: ActivityCategory | undefined) {
    const now = new Date();
    return this.prisma.banner.findMany({
      where: {
        isActive: true,
        AND: [
          { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
          { OR: [{ endsAt: null }, { endsAt: { gt: now } }] },
          category ? { OR: [{ category: null }, { category }] } : {},
        ],
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
      take: 10,
    });
  }

  all() {
    return this.prisma.banner.findMany({ orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }] });
  }

  findById(id: string) {
    return this.prisma.banner.findUnique({ where: { id } });
  }

  create(data: Prisma.BannerCreateInput) {
    return this.prisma.banner.create({ data });
  }

  update(id: string, data: Prisma.BannerUpdateInput) {
    return this.prisma.banner.update({ where: { id }, data });
  }

  async delete(id: string): Promise<boolean> {
    return (await this.prisma.banner.deleteMany({ where: { id } })).count > 0;
  }
}
