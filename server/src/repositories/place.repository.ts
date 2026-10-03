import type { ActivityCategory, PlaceCategory } from '../constants/enums.js';
import type { Db, PrismaClient } from '../db/prisma.js';
import { Prisma } from '../db/prisma.js';
import { boundingBox } from '../utils/geo.js';

function placeInclude(viewerId: string | null) {
  return {
    author: { select: { id: true, name: true, avatarUrl: true } },
    saves: viewerId ? { where: { userId: viewerId }, select: { userId: true }, take: 1 } : false,
    reviews: viewerId
      ? { where: { authorId: viewerId }, select: { id: true, rating: true, worthIt: true }, take: 1 }
      : false,
  } satisfies Prisma.PlaceInclude;
}

export type PlaceRecord = Prisma.PlaceGetPayload<{ include: ReturnType<typeof placeInclude> }>;

const reviewInclude = {
  author: { select: { id: true, name: true, avatarUrl: true } },
} satisfies Prisma.PlaceReviewInclude;
export type PlaceReviewRecord = Prisma.PlaceReviewGetPayload<{ include: typeof reviewInclude }>;

export interface PlaceFilters {
  category?: PlaceCategory;
  activity?: ActivityCategory;
  minRating?: number;
  q?: string;
}

export interface NewPlace {
  authorId: string;
  name: string;
  description: string;
  category: PlaceCategory;
  latitude: number;
  longitude: number;
  locationName: string;
  photos: string[];
  activities: ActivityCategory[];
  bestTime: string | null;
  tips: string | null;
  entryFee: string | null;
}

/** Data access for Explore: places, saves and reviews. */
export class PlaceRepository {
  constructor(private readonly prisma: PrismaClient) {}

  private filterWhere(filters: PlaceFilters): Prisma.PlaceWhereInput {
    const q = filters.q?.trim();
    return {
      ...(filters.category ? { category: filters.category } : {}),
      ...(filters.activity ? { activities: { has: filters.activity } } : {}),
      ...(filters.minRating ? { ratingAvg: { gte: filters.minRating } } : {}),
      ...(q
        ? {
            OR: [
              { name: { contains: q, mode: 'insensitive' } },
              { locationName: { contains: q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
  }

  /**
   * Places within `radiusKm` of a point, nearest first (keyset on distance, id).
   * The bounding box uses the (latitude, longitude) index; the exact haversine
   * distance then filters and orders the candidates.
   */
  async nearby(options: {
    lat: number;
    lng: number;
    radiusKm: number;
    filters: PlaceFilters;
    after: [number, string] | null;
    limit: number;
  }): Promise<Array<{ id: string; distance_km: number }>> {
    const { lat, lng, radiusKm, filters, after, limit } = options;
    const box = boundingBox(lat, lng, radiusKm);
    const q = filters.q?.trim();
    const conditions: Prisma.Sql[] = [
      Prisma.sql`p.latitude BETWEEN ${box.minLat} AND ${box.maxLat}`,
      Prisma.sql`p.longitude BETWEEN ${box.minLng} AND ${box.maxLng}`,
    ];
    if (filters.category) conditions.push(Prisma.sql`p.category = ${filters.category}::place_category`);
    if (filters.activity)
      conditions.push(Prisma.sql`${filters.activity}::activity_category = ANY (p.activities)`);
    if (filters.minRating) conditions.push(Prisma.sql`p.rating_avg >= ${filters.minRating}`);
    if (q) {
      const pattern = `%${q.replace(/[\\%_]/g, (ch) => `\\${ch}`)}%`;
      conditions.push(Prisma.sql`(p.name ILIKE ${pattern} OR p.location_name ILIKE ${pattern})`);
    }
    const keyset = after
      ? Prisma.sql`WHERE (d.distance_km, d.id) > (${after[0]}::double precision, ${after[1]}::uuid)`
      : Prisma.empty;
    return this.prisma.$queryRaw<Array<{ id: string; distance_km: number }>>`
      WITH d AS (
        SELECT p.id,
               6371 * 2 * asin(least(1, sqrt(
                 power(sin(radians(p.latitude - ${lat}) / 2), 2)
                 + cos(radians(${lat})) * cos(radians(p.latitude)) * power(sin(radians(p.longitude - ${lng}) / 2), 2)
               ))) AS distance_km
          FROM places p
         WHERE ${Prisma.join(conditions, ' AND ')}
      )
      SELECT d.id, d.distance_km FROM d
      ${keyset}
      ${after ? Prisma.sql`AND` : Prisma.sql`WHERE`} d.distance_km <= ${radiusKm}
      ORDER BY d.distance_km, d.id
      LIMIT ${limit + 1}`;
  }

  /** Loads places by id, returned in the order of `ids`. */
  async findByIds(ids: string[], viewerId: string | null): Promise<PlaceRecord[]> {
    if (ids.length === 0) return [];
    const rows = await this.prisma.place.findMany({
      where: { id: { in: ids } },
      include: placeInclude(viewerId),
    });
    const byId = new Map(rows.map((row) => [row.id, row]));
    return ids.map((id) => byId.get(id)).filter((row): row is PlaceRecord => row !== undefined);
  }

  /** top: best rated first (keyset on ratingAvg, reviewCount, id); newest: keyset on createdAt, id. */
  findPage(options: {
    sort: 'top' | 'newest';
    filters: PlaceFilters;
    authorId?: string;
    after: { ratingAvg?: number; reviewCount?: number; createdAt?: Date; id: string } | null;
    limit: number;
    viewerId: string | null;
  }) {
    const { after, sort } = options;
    let keyset: Prisma.PlaceWhereInput = {};
    if (after && sort === 'top' && after.ratingAvg !== undefined && after.reviewCount !== undefined) {
      keyset = {
        OR: [
          { ratingAvg: { lt: after.ratingAvg } },
          { ratingAvg: after.ratingAvg, reviewCount: { lt: after.reviewCount } },
          { ratingAvg: after.ratingAvg, reviewCount: after.reviewCount, id: { lt: after.id } },
        ],
      };
    } else if (after && after.createdAt) {
      keyset = {
        OR: [{ createdAt: { lt: after.createdAt } }, { createdAt: after.createdAt, id: { lt: after.id } }],
      };
    }
    return this.prisma.place.findMany({
      where: {
        AND: [
          this.filterWhere(options.filters),
          options.authorId ? { authorId: options.authorId } : {},
          keyset,
        ],
      },
      orderBy:
        sort === 'top'
          ? [{ ratingAvg: 'desc' }, { reviewCount: 'desc' }, { id: 'desc' }]
          : [{ createdAt: 'desc' }, { id: 'desc' }],
      take: options.limit + 1,
      include: placeInclude(options.viewerId),
    });
  }

  findById(id: string, viewerId: string | null, db: Db = this.prisma): Promise<PlaceRecord | null> {
    return db.place.findUnique({ where: { id }, include: placeInclude(viewerId) });
  }

  findOwner(id: string, db: Db = this.prisma) {
    return db.place.findUnique({ where: { id }, select: { id: true, authorId: true, name: true } });
  }

  create(data: NewPlace): Promise<PlaceRecord> {
    return this.prisma.place.create({ data, include: placeInclude(data.authorId) });
  }

  update(id: string, data: Prisma.PlaceUpdateInput, viewerId: string): Promise<PlaceRecord> {
    return this.prisma.place.update({ where: { id }, data, include: placeInclude(viewerId) });
  }

  async delete(id: string, db: Db = this.prisma): Promise<void> {
    await db.place.deleteMany({ where: { id } });
  }

  async save(placeId: string, userId: string): Promise<void> {
    await this.prisma.placeSave.createMany({ data: [{ placeId, userId }], skipDuplicates: true });
  }

  async unsave(placeId: string, userId: string): Promise<void> {
    await this.prisma.placeSave.deleteMany({ where: { placeId, userId } });
  }

  async saveCount(placeId: string): Promise<number> {
    const row = await this.prisma.place.findUniqueOrThrow({
      where: { id: placeId },
      select: { saveCount: true },
    });
    return row.saveCount;
  }

  /** The user's saved places, most recently saved first (keyset on save time, placeId). */
  findSaved(userId: string, after: [Date, string] | null, limit: number) {
    return this.prisma.placeSave.findMany({
      where: {
        userId,
        ...(after
          ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], placeId: { lt: after[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { placeId: 'desc' }],
      take: limit + 1,
      select: { createdAt: true, placeId: true, place: { include: placeInclude(userId) } },
    });
  }

  /** Newest first (keyset on createdAt, id). */
  findReviewsPage(placeId: string, after: [Date, string] | null, limit: number) {
    return this.prisma.placeReview.findMany({
      where: {
        placeId,
        ...(after
          ? { OR: [{ createdAt: { lt: after[0] } }, { createdAt: after[0], id: { lt: after[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: reviewInclude,
    });
  }

  findReview(placeId: string, authorId: string, db: Db = this.prisma) {
    return db.placeReview.findUnique({
      where: { placeId_authorId: { placeId, authorId } },
      select: { id: true },
    });
  }

  upsertReview(
    db: Db,
    data: {
      placeId: string;
      authorId: string;
      rating: number;
      worthIt: boolean;
      text: string;
      visitedOn: Date | null;
      photos: string[];
    },
  ): Promise<PlaceReviewRecord> {
    const { placeId, authorId, ...fields } = data;
    return db.placeReview.upsert({
      where: { placeId_authorId: { placeId, authorId } },
      create: data,
      update: fields,
      include: reviewInclude,
    });
  }

  async deleteReview(placeId: string, authorId: string): Promise<boolean> {
    const result = await this.prisma.placeReview.deleteMany({ where: { placeId, authorId } });
    return result.count > 0;
  }

  count(): Promise<number> {
    return this.prisma.place.count();
  }
}
