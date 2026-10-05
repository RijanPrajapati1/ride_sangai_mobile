import { Prisma, type PrismaClient } from '../db/prisma.js';

/** Leaderboard metrics. Each maps to a fixed SQL column (never user input). */
export const TOP_USER_METRICS = ['followers', 'ridesOrganized', 'ridesJoined', 'posts', 'likesReceived', 'places'] as const;
export type TopUserMetric = (typeof TOP_USER_METRICS)[number];

const METRIC_COLUMN: Record<TopUserMetric, Prisma.Sql> = {
  followers: Prisma.raw('followers_count'),
  ridesOrganized: Prisma.raw('rides_organized'),
  ridesJoined: Prisma.raw('rides_joined'),
  posts: Prisma.raw('posts'),
  likesReceived: Prisma.raw('likes_received'),
  places: Prisma.raw('places'),
};

export interface DailyActivity {
  day: Date;
  signups: number;
  rides: number;
  joinRequests: number;
  posts: number;
  comments: number;
  messages: number;
  places: number;
  feedback: number;
}

export interface TopUserRow {
  id: string;
  name: string;
  email: string;
  avatar_url: string;
  created_at: Date;
  followers_count: number;
  rides_organized: number;
  rides_joined: number;
  posts: number;
  likes_received: number;
  places: number;
}

/** Aggregate and moderation-log queries for the admin dashboard. */
export class AdminRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async stats() {
    const now = new Date();
    const weekAgo = new Date(now.getTime() - 7 * 86_400_000);
    const [
      riders,
      superadmins,
      rides,
      upcomingRides,
      pendingRequests,
      posts,
      comments,
      groups,
      places,
      newRidersLast7Days,
    ] = await this.prisma.$transaction([
      this.prisma.user.count({ where: { role: 'user' } }),
      this.prisma.user.count({ where: { role: 'superadmin' } }),
      this.prisma.ride.count(),
      this.prisma.ride.count({ where: { startsAt: { gt: now } } }),
      this.prisma.rideRequest.count({ where: { status: 'pending' } }),
      this.prisma.post.count(),
      this.prisma.comment.count(),
      this.prisma.group.count(),
      this.prisma.place.count(),
      this.prisma.user.count({ where: { role: 'user', createdAt: { gte: weekAgo } } }),
    ]);
    return {
      riders,
      superadmins,
      rides,
      upcomingRides,
      pendingRequests,
      posts,
      comments,
      groups,
      places,
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

  /**
   * One row per UTC day from [from] to today, with how many of each thing
   * were created that day. Days with no activity are included as zeros.
   */
  dailyActivity(from: Date) {
    return this.prisma.$queryRaw<DailyActivity[]>`
      WITH days AS (
        SELECT generate_series(${from}::timestamptz::date, now()::date, interval '1 day')::date AS day
      ),
      signups AS (SELECT created_at::date AS day, count(*)::int AS n FROM users
                  WHERE role = 'user' AND created_at >= ${from} GROUP BY 1),
      rides AS (SELECT created_at::date AS day, count(*)::int AS n FROM rides
                WHERE created_at >= ${from} GROUP BY 1),
      join_requests AS (SELECT requested_at::date AS day, count(*)::int AS n FROM ride_requests
                        WHERE requested_at >= ${from} GROUP BY 1),
      posts AS (SELECT created_at::date AS day, count(*)::int AS n FROM posts
                WHERE created_at >= ${from} GROUP BY 1),
      comments AS (SELECT created_at::date AS day, count(*)::int AS n FROM comments
                   WHERE created_at >= ${from} GROUP BY 1),
      messages AS (SELECT created_at::date AS day, count(*)::int AS n FROM messages
                   WHERE created_at >= ${from} GROUP BY 1),
      places AS (SELECT created_at::date AS day, count(*)::int AS n FROM places
                 WHERE created_at >= ${from} GROUP BY 1),
      feedback AS (SELECT created_at::date AS day, count(*)::int AS n FROM feedback
                   WHERE created_at >= ${from} GROUP BY 1)
      SELECT days.day::timestamptz AS day,
             coalesce(signups.n, 0) AS signups,
             coalesce(rides.n, 0) AS rides,
             coalesce(join_requests.n, 0) AS "joinRequests",
             coalesce(posts.n, 0) AS posts,
             coalesce(comments.n, 0) AS comments,
             coalesce(messages.n, 0) AS messages,
             coalesce(places.n, 0) AS places,
             coalesce(feedback.n, 0) AS feedback
      FROM days
      LEFT JOIN signups USING (day)
      LEFT JOIN rides USING (day)
      LEFT JOIN join_requests USING (day)
      LEFT JOIN posts USING (day)
      LEFT JOIN comments USING (day)
      LEFT JOIN messages USING (day)
      LEFT JOIN places USING (day)
      LEFT JOIN feedback USING (day)
      ORDER BY days.day`;
  }

  /** Distinct users with a session used in each window (24 hours, 7 days, 30 days). */
  async activeUsers(now: Date) {
    const since = (days: number) => new Date(now.getTime() - days * 86_400_000);
    const [rows] = await this.prisma.$queryRaw<{ day: number; week: number; month: number }[]>`
      SELECT count(DISTINCT user_id) FILTER (WHERE last_used_at >= ${since(1)})::int AS day,
             count(DISTINCT user_id) FILTER (WHERE last_used_at >= ${since(7)})::int AS week,
             count(DISTINCT user_id) FILTER (WHERE last_used_at >= ${since(30)})::int AS month
      FROM sessions
      WHERE last_used_at >= ${since(30)}`;
    return { last24Hours: rows?.day ?? 0, last7Days: rows?.week ?? 0, last30Days: rows?.month ?? 0 };
  }

  async breakdowns() {
    const [ridesByCategory, ridesByDifficulty, requestsByStatus, placesByCategory, feedbackByStatus, feedbackRating] =
      await this.prisma.$transaction([
        this.prisma.ride.groupBy({ by: ['category'], _count: { _all: true }, orderBy: { category: 'asc' } }),
        this.prisma.ride.groupBy({ by: ['difficulty'], _count: { _all: true }, orderBy: { difficulty: 'asc' } }),
        this.prisma.rideRequest.groupBy({ by: ['status'], _count: { _all: true }, orderBy: { status: 'asc' } }),
        this.prisma.place.groupBy({ by: ['category'], _count: { _all: true }, orderBy: { category: 'asc' } }),
        this.prisma.feedback.groupBy({ by: ['status'], _count: { _all: true }, orderBy: { status: 'asc' } }),
        this.prisma.feedback.aggregate({ _avg: { rating: true }, _count: { rating: true } }),
      ]);
    const count = (row: { _count: true | { _all?: number } | undefined }) =>
      typeof row._count === 'object' ? (row._count._all ?? 0) : 0;
    return {
      ridesByCategory: ridesByCategory.map((row) => ({ key: row.category, count: count(row) })),
      ridesByDifficulty: ridesByDifficulty.map((row) => ({ key: row.difficulty, count: count(row) })),
      requestsByStatus: requestsByStatus.map((row) => ({ key: row.status, count: count(row) })),
      placesByCategory: placesByCategory.map((row) => ({ key: row.category, count: count(row) })),
      feedbackByStatus: feedbackByStatus.map((row) => ({ key: row.status, count: count(row) })),
      feedbackAverageRating: feedbackRating._avg.rating,
      feedbackRatings: feedbackRating._count.rating,
    };
  }

  /** Riders ranked by [metric], with every metric included for the table. */
  topUsers(metric: TopUserMetric, limit: number) {
    return this.prisma.$queryRaw<TopUserRow[]>`
      SELECT * FROM (
        SELECT u.id, u.name, u.email, u.avatar_url, u.created_at, u.followers_count,
               (SELECT count(*) FROM rides r WHERE r.organizer_id = u.id)::int AS rides_organized,
               (SELECT count(*) FROM ride_requests rr WHERE rr.user_id = u.id AND rr.status = 'approved')::int
                 AS rides_joined,
               (SELECT count(*) FROM posts p WHERE p.author_id = u.id)::int AS posts,
               (SELECT coalesce(sum(p.like_count), 0) FROM posts p WHERE p.author_id = u.id)::int AS likes_received,
               (SELECT count(*) FROM places pl WHERE pl.author_id = u.id)::int AS places
        FROM users u
        WHERE u.role = 'user'
      ) ranked
      ORDER BY ${METRIC_COLUMN[metric]} DESC, name ASC, id ASC
      LIMIT ${limit}`;
  }
}
