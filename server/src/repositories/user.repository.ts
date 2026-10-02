import type { ExperienceLevel, RideType, UserRole } from '../constants/enums.js';
import type { Db, PrismaClient } from '../db/prisma.js';
import { Prisma } from '../db/prisma.js';

/** Everything needed to render a profile for a given viewer. */
export interface ProfileRecord {
  id: string;
  name: string;
  email: string;
  avatarUrl: string;
  bio: string;
  location: string;
  experienceLevel: ExperienceLevel;
  preferredRideType: RideType;
  interests: string[];
  followersCount: number;
  followingCount: number;
  role: UserRole;
  createdAt: Date;
  lastLoginAt: Date | null;
  publicProfile: boolean;
  showRidingStats: boolean;
  totalRides: number;
  completedRides: number;
  isFollowing: boolean;
}

function profileSelect(viewerId: string | null) {
  return {
    id: true,
    name: true,
    email: true,
    avatarUrl: true,
    bio: true,
    location: true,
    experienceLevel: true,
    preferredRideType: true,
    interests: true,
    followersCount: true,
    followingCount: true,
    role: true,
    createdAt: true,
    lastLoginAt: true,
    preferences: { select: { publicProfile: true, showRidingStats: true } },
    // `take: 1` with the viewer filter answers "does the viewer follow them?".
    followers: viewerId ? { where: { followerId: viewerId }, select: { followerId: true }, take: 1 } : false,
  } satisfies Prisma.UserSelect;
}

type ProfileSelectResult = Prisma.UserGetPayload<{ select: ReturnType<typeof profileSelect> }>;

export interface FollowEdgeRecord {
  id: string;
  name: string;
  avatarUrl: string;
  location: string;
  isFollowing: boolean;
  followedAt: Date;
}

/** Data access for rider profiles, preferences and follows. */
export class UserRepository {
  constructor(private readonly prisma: PrismaClient) {}

  /**
   * Ride stats for many users in one round trip: rides organized plus rides
   * joined (approved); "completed" are those that have started.
   */
  async rideStats(userIds: string[], db: Db = this.prisma): Promise<Map<string, { total: number; completed: number }>> {
    if (userIds.length === 0) return new Map();
    const rows = await db.$queryRaw<Array<{ id: string; total: number; completed: number }>>`
      SELECT u.id,
             (SELECT count(*)::int FROM rides r WHERE r.organizer_id = u.id)
           + (SELECT count(*)::int FROM ride_requests rr WHERE rr.user_id = u.id AND rr.status = 'approved') AS total,
             (SELECT count(*)::int FROM rides r WHERE r.organizer_id = u.id AND r.starts_at < now())
           + (SELECT count(*)::int FROM ride_requests rr JOIN rides r ON r.id = rr.ride_id
               WHERE rr.user_id = u.id AND rr.status = 'approved' AND r.starts_at < now()) AS completed
        FROM unnest(${userIds}::uuid[]) AS u(id)`;
    return new Map(rows.map((row) => [row.id, { total: row.total, completed: row.completed }]));
  }

  private async withStats(rows: ProfileSelectResult[], db: Db = this.prisma): Promise<ProfileRecord[]> {
    const stats = await this.rideStats(rows.map((row) => row.id), db);
    return rows.map(({ preferences, followers, ...user }) => ({
      ...user,
      publicProfile: preferences?.publicProfile ?? true,
      showRidingStats: preferences?.showRidingStats ?? true,
      totalRides: stats.get(user.id)?.total ?? 0,
      completedRides: stats.get(user.id)?.completed ?? 0,
      isFollowing: Array.isArray(followers) && followers.length > 0,
    }));
  }

  async findProfile(userId: string, viewerId: string | null, db: Db = this.prisma): Promise<ProfileRecord | null> {
    const row = await db.user.findUnique({ where: { id: userId }, select: profileSelect(viewerId) });
    if (!row) return null;
    const [profile] = await this.withStats([row], db);
    return profile ?? null;
  }

  async exists(userId: string, db: Db = this.prisma): Promise<boolean> {
    return (await db.user.count({ where: { id: userId } })) > 0;
  }

  findCredentials(userId: string, db: Db = this.prisma) {
    return db.user.findUnique({ where: { id: userId }, select: { name: true, passwordHash: true, role: true } });
  }

  async update(userId: string, data: Prisma.UserUpdateInput, db: Db = this.prisma): Promise<void> {
    await db.user.update({ where: { id: userId }, data, select: { id: true } });
  }

  async delete(userId: string, db: Db = this.prisma): Promise<boolean> {
    const result = await db.user.deleteMany({ where: { id: userId } });
    return result.count > 0;
  }

  /** Returns the preferences row, creating the default one for older accounts. */
  getOrCreatePreferences(userId: string, db: Db = this.prisma) {
    return db.userPreferences.upsert({ where: { userId }, create: { userId }, update: {} });
  }

  updatePreferences(userId: string, data: Prisma.UserPreferencesUpdateInput, db: Db = this.prisma) {
    return db.userPreferences.upsert({ where: { userId }, create: { userId, ...(data as object) }, update: data });
  }

  /** Inserts the follow edge; returns false when it already existed. */
  async insertFollow(followerId: string, followingId: string, db: Db = this.prisma): Promise<boolean> {
    const result = await db.follow.createMany({ data: [{ followerId, followingId }], skipDuplicates: true });
    return result.count > 0;
  }

  async deleteFollow(followerId: string, followingId: string, db: Db = this.prisma): Promise<void> {
    await db.follow.deleteMany({ where: { followerId, followingId } });
  }

  async followersCount(userId: string, db: Db = this.prisma): Promise<number> {
    const row = await db.user.findUniqueOrThrow({ where: { id: userId }, select: { followersCount: true } });
    return row.followersCount;
  }

  /**
   * Riders to follow: not the viewer, not already followed, not admins, not
   * private. Riders whose preferred ride type is in `rideTypes` (the requested
   * category) come first; the rest is filled with the most-followed riders.
   */
  async recommended(viewerId: string, rideTypes: readonly RideType[], limit: number): Promise<ProfileRecord[]> {
    const base: Prisma.UserWhereInput = {
      id: { not: viewerId },
      role: 'user',
      OR: [{ preferences: { is: null } }, { preferences: { is: { publicProfile: true } } }],
      followers: { none: { followerId: viewerId } },
    };
    const orderBy: Prisma.UserOrderByWithRelationInput[] = [{ followersCount: 'desc' }, { id: 'asc' }];
    const select = profileSelect(viewerId);
    const preferred = await this.prisma.user.findMany({
      where: { ...base, preferredRideType: { in: [...rideTypes] } },
      orderBy,
      take: limit,
      select,
    });
    const rest =
      preferred.length < limit
        ? await this.prisma.user.findMany({
            where: { ...base, preferredRideType: { notIn: [...rideTypes] } },
            orderBy,
            take: limit - preferred.length,
            select,
          })
        : [];
    return this.withStats([...preferred, ...rest]);
  }

  /** Alphabetical rider list (keyset on name, id). */
  async list(options: {
    viewerId: string | null;
    q?: string;
    role?: UserRole;
    includePrivate?: boolean;
    after: [string, string] | null;
    limit: number;
  }): Promise<ProfileRecord[]> {
    const q = options.q?.trim();
    const and: Prisma.UserWhereInput[] = [];
    if (options.role) and.push({ role: options.role });
    if (!options.includePrivate) {
      and.push({
        OR: [
          { preferences: { is: null } },
          { preferences: { is: { publicProfile: true } } },
          ...(options.viewerId ? [{ id: options.viewerId }] : []),
        ],
      });
    }
    if (q) {
      and.push({
        OR: [{ name: { contains: q, mode: 'insensitive' } }, ...(options.includePrivate ? [{ email: { contains: q.toLowerCase() } }] : [])],
      });
    }
    if (options.after) {
      const [name, id] = options.after;
      and.push({ OR: [{ name: { gt: name } }, { name, id: { gt: id } }] });
    }
    const rows = await this.prisma.user.findMany({
      where: { AND: and },
      orderBy: [{ name: 'asc' }, { id: 'asc' }],
      take: options.limit + 1,
      select: profileSelect(options.viewerId),
    });
    return this.withStats(rows);
  }

  async followEdges(
    userId: string,
    direction: 'followers' | 'following',
    viewerId: string,
    after: [Date, string] | null,
    limit: number,
  ): Promise<FollowEdgeRecord[]> {
    const userSelect = {
      select: {
        id: true,
        name: true,
        avatarUrl: true,
        location: true,
        followers: { where: { followerId: viewerId }, select: { followerId: true }, take: 1 },
      },
    } as const;
    const toEdge = (createdAt: Date, user: { id: string; name: string; avatarUrl: string; location: string; followers: unknown[] }) => ({
      id: user.id,
      name: user.name,
      avatarUrl: user.avatarUrl,
      location: user.location,
      isFollowing: user.followers.length > 0,
      followedAt: createdAt,
    });

    if (direction === 'followers') {
      const rows = await this.prisma.follow.findMany({
        where: {
          followingId: userId,
          ...(after ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], followerId: { lt: after[1] } }] } : {}),
        },
        orderBy: [{ createdAt: 'desc' }, { followerId: 'desc' }],
        take: limit + 1,
        select: { createdAt: true, follower: userSelect },
      });
      return rows.map((row) => toEdge(row.createdAt, row.follower));
    }
    const rows = await this.prisma.follow.findMany({
      where: {
        followerId: userId,
        ...(after ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], followingId: { lt: after[1] } }] } : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { followingId: 'desc' }],
      take: limit + 1,
      select: { createdAt: true, following: userSelect },
    });
    return rows.map((row) => toEdge(row.createdAt, row.following));
  }
}
