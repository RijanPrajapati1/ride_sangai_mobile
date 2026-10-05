import type { ActivityCategory, PlaceCategory } from '../constants/enums.js';
import type { UnitOfWork } from '../db/prisma.js';
import type {
  PlaceFilters,
  PlaceRecord,
  PlaceRepository,
  PlaceReviewRecord,
} from '../repositories/place.repository.js';
import { audit } from '../utils/audit.js';
import { badRequest, conflict, forbidden, notFound } from '../utils/errors.js';
import { distanceKm, roundKm } from '../utils/geo.js';
import { decodeCursor, decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';
import { assertImageUrl, blankToNull, cleanList } from '../utils/validation.js';
import type { NotificationService } from './notification.service.js';
import type { Actor } from './ride.service.js';

const PLACE_NOT_FOUND = () => notFound('This place could not be found.', 'PLACE_NOT_FOUND');

export interface Point {
  lat: number;
  lng: number;
}

export interface PlaceInput {
  name: string;
  description: string;
  category: PlaceCategory;
  latitude: number;
  longitude: number;
  locationName: string;
  photos?: string[];
  activities?: ActivityCategory[];
  bestTime?: string | null;
  tips?: string | null;
  entryFee?: string | null;
}

export interface ReviewInput {
  rating: number;
  worthIt: boolean;
  text?: string;
  visitedOn?: string | null;
  photos?: string[];
}

/** Maps a place to the API shape for one viewer (distance only when the viewer's location is known). */
export function toPlaceDto(
  place: PlaceRecord,
  viewerId: string | null,
  from: Point | null,
  knownDistance?: number,
) {
  const myReview = Array.isArray(place.reviews) ? place.reviews[0] : undefined;
  const distance =
    knownDistance ?? (from ? distanceKm(from.lat, from.lng, place.latitude, place.longitude) : null);
  return {
    id: place.id,
    name: place.name,
    description: place.description,
    category: place.category,
    latitude: place.latitude,
    longitude: place.longitude,
    locationName: place.locationName,
    photos: place.photos,
    coverImageUrl: place.photos[0] ?? null,
    activities: place.activities,
    bestTime: place.bestTime,
    tips: place.tips,
    entryFee: place.entryFee,
    averageRating: place.reviewCount > 0 ? Math.round(place.ratingAvg * 10) / 10 : null,
    reviewCount: place.reviewCount,
    worthItPercent: place.reviewCount > 0 ? Math.round((place.worthItCount / place.reviewCount) * 100) : null,
    saveCount: place.saveCount,
    distanceKm: distance === null ? null : roundKm(distance),
    authorId: place.author.id,
    authorName: place.author.name,
    authorAvatarUrl: place.author.avatarUrl,
    isMine: viewerId === place.author.id,
    isSaved: Array.isArray(place.saves) && place.saves.length > 0,
    myReview: myReview ? { id: myReview.id, rating: myReview.rating, worthIt: myReview.worthIt } : null,
    createdAt: place.createdAt,
  };
}

export type PlaceDto = ReturnType<typeof toPlaceDto>;

export function toPlaceReviewDto(review: PlaceReviewRecord, viewerId: string | null) {
  return {
    id: review.id,
    placeId: review.placeId,
    userId: review.author.id,
    userName: review.author.name,
    userAvatarUrl: review.author.avatarUrl,
    rating: review.rating,
    worthIt: review.worthIt,
    text: review.text,
    visitedOn: review.visitedOn ? review.visitedOn.toISOString().slice(0, 10) : null,
    photos: review.photos,
    createdAt: review.createdAt,
    updatedAt: review.updatedAt,
    isMine: viewerId === review.author.id,
  };
}

function cleanPhotos(photos: readonly string[] | undefined, max: number): string[] {
  const list = cleanList(photos ? [...photos] : []);
  if (list.length > max) throw badRequest(`Add at most ${max} photos.`, 'TOO_MANY_PHOTOS');
  list.forEach((url) => assertImageUrl(url, 'photos'));
  return list;
}

/** Explore: places shared by locals, with reviews and saves. */
export class PlaceService {
  constructor(
    private readonly uow: UnitOfWork,
    readonly repo: PlaceRepository,
    private readonly notifications: NotificationService,
  ) {}

  /** Places around a point, nearest first. */
  async nearby(
    viewerId: string,
    query: PlaceFilters & { lat: number; lng: number; radiusKm?: number; limit?: number; cursor?: string },
  ) {
    const limit = pageLimit(query.limit);
    const radiusKm = query.radiusKm ?? 25;
    const parts = decodeCursor(query.cursor, ['number', 'string']);
    const rows = await this.repo.nearby({
      lat: query.lat,
      lng: query.lng,
      radiusKm,
      filters: query,
      after: parts ? [parts[0] as number, parts[1] as string] : null,
      limit,
    });
    const page = toPage(rows, limit, (row) => [row.distance_km, row.id]);
    const places = await this.repo.findByIds(
      page.items.map((row) => row.id),
      viewerId,
    );
    const distances = new Map(page.items.map((row) => [row.id, row.distance_km]));
    return {
      items: places.map((place) => toPlaceDto(place, viewerId, null, distances.get(place.id))),
      nextCursor: page.nextCursor,
    };
  }

  /** Browse: best rated (`top`) or `newest`; distance is filled in when lat/lng are given. */
  async list(
    viewerId: string,
    query: PlaceFilters & {
      sort?: 'top' | 'newest';
      lat?: number;
      lng?: number;
      authorId?: string;
      limit?: number;
      cursor?: string;
    },
  ) {
    const sort = query.sort ?? 'top';
    const limit = pageLimit(query.limit);
    let after: { ratingAvg?: number; reviewCount?: number; createdAt?: Date; id: string } | null = null;
    if (sort === 'top') {
      const parts = decodeCursor(query.cursor, ['number', 'number', 'string']);
      if (parts)
        after = { ratingAvg: parts[0] as number, reviewCount: parts[1] as number, id: parts[2] as string };
    } else {
      const parts = decodeTimeCursor(query.cursor);
      if (parts) after = { createdAt: parts[0], id: parts[1] };
    }
    const rows = await this.repo.findPage({
      sort,
      filters: query,
      ...(query.authorId ? { authorId: query.authorId } : {}),
      after,
      limit,
      viewerId,
    });
    const from =
      query.lat !== undefined && query.lng !== undefined ? { lat: query.lat, lng: query.lng } : null;
    return toPage(
      rows,
      limit,
      (place) =>
        sort === 'top'
          ? [place.ratingAvg, place.reviewCount, place.id]
          : timeCursor(place.createdAt, place.id),
      (place) => toPlaceDto(place, viewerId, from),
    );
  }

  async get(placeId: string, viewerId: string, from: Point | null) {
    const place = await this.repo.findById(placeId, viewerId);
    if (!place) throw PLACE_NOT_FOUND();
    return toPlaceDto(place, viewerId, from);
  }

  async create(author: Actor, input: PlaceInput) {
    const place = await this.repo.create({
      authorId: author.id,
      name: input.name.trim(),
      description: input.description.trim(),
      category: input.category,
      latitude: input.latitude,
      longitude: input.longitude,
      locationName: input.locationName.trim(),
      photos: cleanPhotos(input.photos, 10),
      activities: [...new Set(input.activities ?? [])],
      bestTime: blankToNull(input.bestTime),
      tips: blankToNull(input.tips),
      entryFee: blankToNull(input.entryFee),
    });
    return toPlaceDto(place, author.id, null);
  }

  private async assertCanManage(placeId: string, actor: Actor) {
    const place = await this.repo.findOwner(placeId);
    if (!place) throw PLACE_NOT_FOUND();
    if (place.authorId !== actor.id && actor.role !== 'superadmin') {
      throw forbidden('Only the person who shared this place can change it.', 'NOT_PLACE_AUTHOR');
    }
    return place;
  }

  async update(actor: Actor, placeId: string, input: Partial<PlaceInput>) {
    await this.assertCanManage(placeId, actor);
    const place = await this.repo.update(
      placeId,
      {
        ...(input.name !== undefined ? { name: input.name.trim() } : {}),
        ...(input.description !== undefined ? { description: input.description.trim() } : {}),
        ...(input.category !== undefined ? { category: input.category } : {}),
        ...(input.latitude !== undefined ? { latitude: input.latitude } : {}),
        ...(input.longitude !== undefined ? { longitude: input.longitude } : {}),
        ...(input.locationName !== undefined ? { locationName: input.locationName.trim() } : {}),
        ...(input.photos !== undefined ? { photos: cleanPhotos(input.photos, 10) } : {}),
        ...(input.activities !== undefined ? { activities: [...new Set(input.activities)] } : {}),
        ...(input.bestTime !== undefined ? { bestTime: blankToNull(input.bestTime) } : {}),
        ...(input.tips !== undefined ? { tips: blankToNull(input.tips) } : {}),
        ...(input.entryFee !== undefined ? { entryFee: blankToNull(input.entryFee) } : {}),
      },
      actor.id,
    );
    return toPlaceDto(place, actor.id, null);
  }

  /** The author, or an admin moderating. Reviews and saves go with it. */
  async remove(actor: Actor, placeId: string): Promise<void> {
    const place = await this.assertCanManage(placeId, actor);
    await this.uow.run(async ({ db }) => {
      if (place.authorId !== actor.id) {
        await audit(db, {
          actorId: actor.id,
          action: 'place.delete',
          targetType: 'place',
          targetId: placeId,
          details: { name: place.name },
        });
      }
      await this.repo.delete(placeId, db);
    });
  }

  async save(viewerId: string, placeId: string) {
    if (!(await this.repo.findOwner(placeId))) throw PLACE_NOT_FOUND();
    await this.repo.save(placeId, viewerId);
    return { isSaved: true, saveCount: await this.repo.saveCount(placeId) };
  }

  async unsave(viewerId: string, placeId: string) {
    if (!(await this.repo.findOwner(placeId))) throw PLACE_NOT_FOUND();
    await this.repo.unsave(placeId, viewerId);
    return { isSaved: false, saveCount: await this.repo.saveCount(placeId) };
  }

  async saved(viewerId: string, query: { lat?: number; lng?: number; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findSaved(viewerId, decodeTimeCursor(query.cursor), limit);
    const from =
      query.lat !== undefined && query.lng !== undefined ? { lat: query.lat, lng: query.lng } : null;
    return toPage(
      rows,
      limit,
      (row) => timeCursor(row.createdAt, row.placeId),
      (row) => toPlaceDto(row.place, viewerId, from),
    );
  }

  async reviews(placeId: string, viewerId: string, query: { limit?: number; cursor?: string }) {
    if (!(await this.repo.findOwner(placeId))) throw PLACE_NOT_FOUND();
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findReviewsPage(placeId, decodeTimeCursor(query.cursor), limit);
    return toPage(
      rows,
      limit,
      (row) => timeCursor(row.createdAt, row.id),
      (row) => toPlaceReviewDto(row, viewerId),
    );
  }

  /** Creates or replaces the viewer's review. Returns whether it was new. */
  async review(reviewer: Actor, placeId: string, input: ReviewInput) {
    const visitedOn = input.visitedOn ? new Date(`${input.visitedOn}T00:00:00Z`) : null;
    if (visitedOn && visitedOn.getTime() > Date.now() + 86_400_000) {
      throw badRequest('The visit date cannot be in the future.', 'VISIT_DATE_IN_FUTURE');
    }
    return this.uow.run(async (ctx) => {
      const place = await this.repo.findOwner(placeId, ctx.db);
      if (!place) throw PLACE_NOT_FOUND();
      if (place.authorId === reviewer.id)
        throw conflict('You shared this place, so you cannot review it.', 'CANNOT_REVIEW_OWN_PLACE');
      const existed = (await this.repo.findReview(placeId, reviewer.id, ctx.db)) !== null;
      const review = await this.repo.upsertReview(ctx.db, {
        placeId,
        authorId: reviewer.id,
        rating: input.rating,
        worthIt: input.worthIt,
        text: input.text?.trim() ?? '',
        visitedOn,
        photos: cleanPhotos(input.photos, 5),
      });
      await this.notifications.notify(ctx, {
        recipientId: place.authorId,
        actorId: reviewer.id,
        type: 'placeReview',
        title: 'New review',
        body: `${reviewer.name} rated ${place.name} ${input.rating}★${input.worthIt ? ' — worth the trip!' : '.'}`,
        entityType: 'place',
        entityId: placeId,
        collapseKey: `placeReview:${placeId}:${reviewer.id}`,
      });
      return { review: toPlaceReviewDto(review, reviewer.id), created: !existed };
    });
  }

  async removeReview(reviewerId: string, placeId: string): Promise<void> {
    if (!(await this.repo.findOwner(placeId))) throw PLACE_NOT_FOUND();
    if (!(await this.repo.deleteReview(placeId, reviewerId))) {
      throw notFound('You have not reviewed this place.', 'REVIEW_NOT_FOUND');
    }
  }
}
