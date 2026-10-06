import type { FeedbackCategory, FeedbackStatus } from '../constants/enums.js';
import type { Prisma, PrismaClient } from '../db/prisma.js';

const withUser = { user: { select: { id: true, name: true, email: true, avatarUrl: true } } } as const;

export type FeedbackRecord = Prisma.FeedbackGetPayload<{ include: typeof withUser }>;

export class FeedbackRepository {
  constructor(private readonly prisma: PrismaClient) {}

  create(data: {
    userId: string;
    category: FeedbackCategory;
    message: string;
    rating: number | null;
    platform: string | null;
    appVersion: string | null;
  }) {
    return this.prisma.feedback.create({ data, include: withUser });
  }

  findById(id: string) {
    return this.prisma.feedback.findUnique({ where: { id }, include: withUser });
  }

  /** Newest first, keyset-paginated on (createdAt, id). */
  page(
    filter: { status?: FeedbackStatus; category?: FeedbackCategory },
    after: [Date, string] | null,
    limit: number,
  ) {
    return this.prisma.feedback.findMany({
      where: {
        ...(filter.status ? { status: filter.status } : {}),
        ...(filter.category ? { category: filter.category } : {}),
        ...(after
          ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], id: { lt: after[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: withUser,
    });
  }

  async delete(id: string): Promise<boolean> {
    const { count } = await this.prisma.feedback.deleteMany({ where: { id } });
    return count > 0;
  }

  update(id: string, data: { status?: FeedbackStatus; adminNote?: string; resolvedAt?: Date | null }) {
    return this.prisma.feedback.update({ where: { id }, data, include: withUser });
  }
}
