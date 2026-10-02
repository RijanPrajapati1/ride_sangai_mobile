import type { PrismaClient } from '../db/prisma.js';

/** Aggregate and moderation-log queries for the admin dashboard. */
export class AdminRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async stats() {
    const now = new Date();
    const weekAgo = new Date(now.getTime() - 7 * 86_400_000);
    const [
      riders,
      admins,
      rides,
      upcomingRides,
      pendingRequests,
      posts,
      comments,
      groups,
      newRidersLast7Days,
    ] = await this.prisma.$transaction([
      this.prisma.user.count({ where: { role: 'user' } }),
      this.prisma.user.count({ where: { role: 'admin' } }),
      this.prisma.ride.count(),
      this.prisma.ride.count({ where: { startsAt: { gt: now } } }),
      this.prisma.rideRequest.count({ where: { status: 'pending' } }),
      this.prisma.post.count(),
      this.prisma.comment.count(),
      this.prisma.group.count(),
      this.prisma.user.count({ where: { role: 'user', createdAt: { gte: weekAgo } } }),
    ]);
    return {
      riders,
      admins,
      rides,
      upcomingRides,
      pendingRequests,
      posts,
      comments,
      groups,
      newRidersLast7Days,
    };
  }

  auditPage(after: [Date, string] | null, limit: number) {
    return this.prisma.adminAuditLog.findMany({
      where: after
        ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], id: { lt: after[1] } }] }
        : {},
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: { actor: { select: { name: true } } },
    });
  }
}
