import type { ActivityCategory, RideDifficulty, RideRequestStatus, RideType } from '../constants/enums.js';
import type { Db, PrismaClient } from '../db/prisma.js';
import type { Prisma } from '../db/prisma.js';

/** Organizer and the avatars of the first five approved riders, loaded with every ride. */
export const rideInclude = {
  organizer: { select: { id: true, name: true, avatarUrl: true } },
  requests: {
    where: { status: 'approved' },
    orderBy: [{ decidedAt: 'asc' }, { id: 'asc' }],
    take: 5,
    select: { user: { select: { avatarUrl: true } } },
  },
} satisfies Prisma.RideInclude;

export type RideRecord = Prisma.RideGetPayload<{ include: typeof rideInclude }>;

export const rideRequestInclude = {
  ride: { select: { id: true, title: true, startsAt: true, organizerId: true } },
  user: { select: { id: true, name: true, avatarUrl: true, bio: true, experienceLevel: true } },
} satisfies Prisma.RideRequestInclude;

export type RideRequestRecord = Prisma.RideRequestGetPayload<{ include: typeof rideRequestInclude }>;

export interface MyRequestRecord {
  id: string;
  rideId: string;
  status: RideRequestStatus;
  declineReason: string | null;
  requestedAt: Date;
}

export interface RideFilters {
  category?: ActivityCategory;
  rideType?: RideType;
  difficulty?: RideDifficulty;
  q?: string;
  from?: Date;
  to?: Date;
}

export interface NewRide {
  organizerId: string;
  title: string;
  description: string;
  rideType: RideType;
  category: ActivityCategory;
  difficulty: RideDifficulty;
  startsAt: Date;
  meetingPoint: string;
  distanceKm: number;
  durationMinutes: number;
  maxParticipants: number;
  requirements: string[];
  imageUrl: string;
}

/** Keyset condition for `ORDER BY startsAt, id` in either direction. */
function startsAtKeyset(after: [Date, string] | null, direction: 'asc' | 'desc'): Prisma.RideWhereInput {
  if (!after) return {};
  const op = direction === 'asc' ? 'gt' : 'lt';
  return { OR: [{ startsAt: { [op]: after[0] } }, { startsAt: after[0], id: { [op]: after[1] } }] };
}

/** Data access for rides, join requests and participants. */
export class RideRepository {
  constructor(private readonly prisma: PrismaClient) {}

  filterWhere(filters: RideFilters): Prisma.RideWhereInput {
    const q = filters.q?.trim();
    return {
      ...(filters.category ? { category: filters.category } : {}),
      ...(filters.rideType ? { rideType: filters.rideType } : {}),
      ...(filters.difficulty ? { difficulty: filters.difficulty } : {}),
      ...(filters.from || filters.to
        ? { startsAt: { ...(filters.from ? { gte: filters.from } : {}), ...(filters.to ? { lte: filters.to } : {}) } }
        : {}),
      ...(q
        ? { OR: [{ title: { contains: q, mode: 'insensitive' } }, { meetingPoint: { contains: q, mode: 'insensitive' } }] }
        : {}),
    };
  }

  /** One page of rides ordered by start time (plus one probe row for `nextCursor`). */
  findPage(where: Prisma.RideWhereInput, options: { direction: 'asc' | 'desc'; after: [Date, string] | null; limit: number }) {
    return this.prisma.ride.findMany({
      where: { AND: [where, startsAtKeyset(options.after, options.direction)] },
      orderBy: [{ startsAt: options.direction }, { id: options.direction }],
      take: options.limit + 1,
      include: rideInclude,
    });
  }

  findById(id: string, db: Db = this.prisma): Promise<RideRecord | null> {
    return db.ride.findUnique({ where: { id }, include: rideInclude });
  }

  /** The viewer's own request for each ride, in one query. */
  async myRequests(rideIds: string[], viewerId: string | null): Promise<Map<string, MyRequestRecord>> {
    if (!viewerId || rideIds.length === 0) return new Map();
    const rows = await this.prisma.rideRequest.findMany({
      where: { userId: viewerId, rideId: { in: rideIds } },
      select: { id: true, rideId: true, status: true, declineReason: true, requestedAt: true },
    });
    return new Map(rows.map((row) => [row.rideId, row]));
  }

  create(data: NewRide, db: Db = this.prisma): Promise<RideRecord> {
    return db.ride.create({ data, include: rideInclude });
  }

  update(id: string, data: Prisma.RideUpdateInput, db: Db = this.prisma): Promise<RideRecord> {
    return db.ride.update({ where: { id }, data, include: rideInclude });
  }

  async delete(id: string, db: Db = this.prisma): Promise<void> {
    await db.ride.deleteMany({ where: { id } });
  }

  /** Locks the ride row (capacity checks, edits) for the rest of the transaction. */
  async lockRide(db: Db, id: string): Promise<void> {
    await db.$queryRaw`SELECT id FROM rides WHERE id = ${id}::uuid FOR UPDATE`;
  }

  /** Locks a request and its ride, so concurrent approvals of one ride serialise. */
  async lockRequestAndRide(db: Db, requestId: string): Promise<void> {
    await db.$queryRaw`SELECT rr.id FROM ride_requests rr JOIN rides r ON r.id = rr.ride_id
                        WHERE rr.id = ${requestId}::uuid FOR UPDATE OF rr, r`;
  }

  findRequest(id: string, db: Db = this.prisma): Promise<RideRequestRecord | null> {
    return db.rideRequest.findUnique({ where: { id }, include: rideRequestInclude });
  }

  findRequestFor(rideId: string, userId: string, db: Db = this.prisma) {
    return db.rideRequest.findUnique({ where: { rideId_userId: { rideId, userId } } });
  }

  createRequest(db: Db, data: { rideId: string; userId: string; message: string | null }): Promise<RideRequestRecord> {
    return db.rideRequest.create({ data, include: rideRequestInclude });
  }

  /** A declined rider asking again: back to pending, decision cleared. */
  resubmitRequest(db: Db, id: string, message: string | null): Promise<RideRequestRecord> {
    return db.rideRequest.update({
      where: { id },
      data: { status: 'pending', message, declineReason: null, decidedAt: null, decidedById: null, requestedAt: new Date() },
      include: rideRequestInclude,
    });
  }

  decideRequest(
    db: Db,
    id: string,
    decision: { status: 'approved' | 'declined'; deciderId: string; declineReason: string | null },
  ): Promise<RideRequestRecord> {
    return db.rideRequest.update({
      where: { id },
      data: { status: decision.status, declineReason: decision.declineReason, decidedAt: new Date(), decidedById: decision.deciderId },
      include: rideRequestInclude,
    });
  }

  async deleteRequest(db: Db, id: string): Promise<void> {
    await db.rideRequest.delete({ where: { id } });
  }

  /** Requests newest first (keyset on requestedAt, id). */
  findRequestsPage(where: Prisma.RideRequestWhereInput, after: [Date, string] | null, limit: number) {
    return this.prisma.rideRequest.findMany({
      where: {
        AND: [
          where,
          after ? { OR: [{ requestedAt: { lt: after[0] } }, { requestedAt: after[0], id: { lt: after[1] } }] } : {},
        ],
      },
      orderBy: [{ requestedAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: rideRequestInclude,
    });
  }

  /** Approved riders in the order they were approved. */
  findParticipantsPage(rideId: string, after: [Date, string] | null, limit: number) {
    return this.prisma.rideRequest.findMany({
      where: {
        rideId,
        status: 'approved',
        ...(after ? { OR: [{ decidedAt: { gt: after[0] } }, { decidedAt: after[0], id: { gt: after[1] } }] } : {}),
      },
      orderBy: [{ decidedAt: 'asc' }, { id: 'asc' }],
      take: limit + 1,
      select: { id: true, rideId: true, decidedAt: true, requestedAt: true, user: { select: { id: true, name: true, avatarUrl: true } } },
    });
  }

  /** Everyone who should hear about a change to the ride: approved riders and pending requesters. */
  async audience(rideId: string, db: Db = this.prisma): Promise<string[]> {
    const rows = await db.rideRequest.findMany({
      where: { rideId, status: { in: ['approved', 'pending'] } },
      select: { userId: true },
    });
    return rows.map((row) => row.userId);
  }

  countPendingForOrganizer(organizerId: string): Promise<number> {
    return this.prisma.rideRequest.count({ where: { status: 'pending', ride: { organizerId, startsAt: { gt: new Date() } } } });
  }

  /**
   * Claims rides starting within `leadMinutes` whose reminders have not been
   * sent, marking them sent in the same statement. SKIP LOCKED makes this safe
   * to run on several instances at once.
   */
  async claimDueReminders(db: Db, leadMinutes: number) {
    return db.$queryRaw<Array<{ id: string; title: string; starts_at: Date; organizer_id: string }>>`
      UPDATE rides SET reminder_sent_at = now()
       WHERE id IN (
         SELECT id FROM rides
          WHERE reminder_sent_at IS NULL
            AND starts_at > now()
            AND starts_at <= now() + make_interval(mins => ${leadMinutes}::int)
          ORDER BY starts_at
          LIMIT 200
          FOR UPDATE SKIP LOCKED)
      RETURNING id, title, starts_at, organizer_id`;
  }

  approvedRiderIds(rideId: string, db: Db = this.prisma): Promise<Array<{ userId: string }>> {
    return db.rideRequest.findMany({ where: { rideId, status: 'approved' }, select: { userId: true } });
  }
}
