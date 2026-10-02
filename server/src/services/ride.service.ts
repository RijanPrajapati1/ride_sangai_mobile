import {
  RIDE_TYPE_CATEGORY,
  type ActivityCategory,
  type RideDifficulty,
  type RideJoinStatus,
  type RideRequestStatus,
  type RideType,
  type UserRole,
} from '../constants/enums.js';
import type { Prisma, TxContext, UnitOfWork } from '../db/prisma.js';
import type {
  MyRequestRecord,
  RideFilters,
  RideRecord,
  RideRepository,
  RideRequestRecord,
} from '../repositories/ride.repository.js';
import { audit } from '../utils/audit.js';
import { isCheckViolation } from '../utils/db-errors.js';
import { conflict, forbidden, notFound, unprocessable } from '../utils/errors.js';
import { decodeTimeCursor, pageLimit, timeCursor, toPage, type Page } from '../utils/pagination.js';
import { cleanList } from '../utils/sql.js';
import { assertImageUrl, blankToNull } from '../utils/validation.js';
import type { NotificationService } from './notification.service.js';

export interface Actor {
  id: string;
  role: UserRole;
  name: string;
}

export interface RideInput {
  title: string;
  description: string;
  date: string;
  meetingPoint: string;
  rideType: RideType;
  difficulty: RideDifficulty;
  distanceKm: number;
  durationMinutes: number;
  maxParticipants: number;
  requirements?: string[];
  imageUrl?: string | null;
}

export type MyRidesScope = 'upcoming' | 'organized' | 'joined' | 'past';

const MAX_DAYS_AHEAD = 730;

const RIDE_NOT_FOUND = () => notFound('This ride no longer exists.', 'RIDE_NOT_FOUND');
const REQUEST_NOT_FOUND = () => notFound('This request no longer exists.', 'REQUEST_NOT_FOUND');

/** Maps a ride to the API shape (the Dart `Ride` entity) for one viewer. */
export function toRideDto(ride: RideRecord, myRequest: MyRequestRecord | null | undefined, viewerId: string | null) {
  const joinStatus: RideJoinStatus =
    viewerId !== null && ride.organizerId === viewerId ? 'organizer' : (myRequest?.status ?? 'none');
  return {
    id: ride.id,
    title: ride.title,
    description: ride.description,
    date: ride.startsAt,
    meetingPoint: ride.meetingPoint,
    rideType: ride.rideType,
    category: ride.category,
    difficulty: ride.difficulty,
    distanceKm: ride.distanceKm,
    durationMinutes: ride.durationMinutes,
    organizerId: ride.organizer.id,
    organizerName: ride.organizer.name,
    organizerAvatarUrl: ride.organizer.avatarUrl,
    imageUrl: ride.imageUrl,
    participantCount: ride.participantCount,
    maxParticipants: ride.maxParticipants,
    isFull: ride.participantCount >= ride.maxParticipants,
    requirements: ride.requirements,
    participantAvatars: ride.requests.map((request) => request.user.avatarUrl),
    joinStatus,
    myRequest: myRequest
      ? { id: myRequest.id, status: myRequest.status, declineReason: myRequest.declineReason, requestedAt: myRequest.requestedAt }
      : null,
    createdAt: ride.createdAt,
  };
}

export type RideDto = ReturnType<typeof toRideDto>;

/** Maps a join request to the API shape (the Dart `RideRequest` entity). */
export function toRideRequestDto(request: RideRequestRecord) {
  return {
    id: request.id,
    rideId: request.rideId,
    rideTitle: request.ride.title,
    rideDate: request.ride.startsAt,
    userId: request.user.id,
    userName: request.user.name,
    userAvatarUrl: request.user.avatarUrl,
    userBio: request.message ?? request.user.bio,
    message: request.message,
    experienceLevel: request.user.experienceLevel,
    requestedAt: request.requestedAt,
    status: request.status,
    declineReason: request.declineReason,
    decidedAt: request.decidedAt,
  };
}

export type RideRequestDto = ReturnType<typeof toRideRequestDto>;

function parseStart(date: string): Date {
  const startsAt = new Date(date);
  if (startsAt.getTime() <= Date.now()) {
    throw unprocessable('The ride must start in the future.', 'RIDE_DATE_IN_PAST');
  }
  if (startsAt.getTime() > Date.now() + MAX_DAYS_AHEAD * 86_400_000) {
    throw unprocessable('Rides can be scheduled up to two years ahead.', 'RIDE_DATE_TOO_FAR');
  }
  return startsAt;
}

function describeChanges(changed: string[]): string {
  if (changed.length === 1) return changed[0]!;
  return `${changed.slice(0, -1).join(', ')} and ${changed[changed.length - 1]}`;
}

/** Rides, join requests and participants. */
export class RideService {
  constructor(
    private readonly uow: UnitOfWork,
    readonly repo: RideRepository,
    private readonly notifications: NotificationService,
  ) {}

  // --- Reading -----------------------------------------------------------------

  private async toPageDto(rows: RideRecord[], limit: number, viewerId: string | null): Promise<Page<RideDto>> {
    const page = toPage(rows, limit, (ride) => timeCursor(ride.startsAt, ride.id));
    const mine = await this.repo.myRequests(page.items.map((ride) => ride.id), viewerId);
    return { items: page.items.map((ride) => toRideDto(ride, mine.get(ride.id), viewerId)), nextCursor: page.nextCursor };
  }

  /** Discovery: upcoming rides, soonest first. */
  async discover(viewerId: string, query: RideFilters & { limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const where: Prisma.RideWhereInput = {
      AND: [{ startsAt: { gt: new Date() } }, this.repo.filterWhere(query)],
    };
    const rows = await this.repo.findPage(where, { direction: 'asc', after: decodeTimeCursor(query.cursor), limit });
    return this.toPageDto(rows, limit, viewerId);
  }

  /** The "My Rides" tabs. */
  async mine(viewerId: string, query: { scope?: MyRidesScope; category?: ActivityCategory; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const now = new Date();
    const scope = query.scope ?? 'upcoming';
    const active = { some: { userId: viewerId, status: { in: ['pending', 'approved'] as RideRequestStatus[] } } };
    const byScope: Record<MyRidesScope, { where: Prisma.RideWhereInput; direction: 'asc' | 'desc' }> = {
      upcoming: { where: { startsAt: { gt: now }, OR: [{ organizerId: viewerId }, { requests: active }] }, direction: 'asc' },
      organized: { where: { organizerId: viewerId }, direction: 'asc' },
      joined: { where: { startsAt: { gt: now }, requests: active }, direction: 'asc' },
      past: {
        where: { startsAt: { lte: now }, OR: [{ organizerId: viewerId }, { requests: { some: { userId: viewerId, status: 'approved' } } }] },
        direction: 'desc',
      },
    };
    const { where, direction } = byScope[scope];
    const rows = await this.repo.findPage(
      { AND: [where, query.category ? { category: query.category } : {}] },
      { direction, after: decodeTimeCursor(query.cursor), limit },
    );
    return this.toPageDto(rows, limit, viewerId);
  }

  /** Rides a rider organizes (all dates, oldest first) — the profile's "Rides Organized". */
  async byOrganizer(userId: string, viewerId: string, query: { limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findPage({ organizerId: userId }, { direction: 'asc', after: decodeTimeCursor(query.cursor), limit });
    return this.toPageDto(rows, limit, viewerId);
  }

  /** Admin list: every ride, newest start first. */
  async listAll(viewerId: string, query: RideFilters & { when?: 'upcoming' | 'past' | 'all'; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const now = new Date();
    const when = query.when === 'upcoming' ? { startsAt: { gt: now } } : query.when === 'past' ? { startsAt: { lte: now } } : {};
    const rows = await this.repo.findPage(
      { AND: [when, this.repo.filterWhere(query)] },
      { direction: 'desc', after: decodeTimeCursor(query.cursor), limit },
    );
    return this.toPageDto(rows, limit, viewerId);
  }

  async get(rideId: string, viewerId: string): Promise<RideDto> {
    const ride = await this.repo.findById(rideId);
    if (!ride) throw RIDE_NOT_FOUND();
    const mine = await this.repo.myRequests([ride.id], viewerId);
    return toRideDto(ride, mine.get(ride.id), viewerId);
  }

  async participants(rideId: string, query: { limit?: number; cursor?: string }) {
    if (!(await this.repo.findById(rideId))) throw RIDE_NOT_FOUND();
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findParticipantsPage(rideId, decodeTimeCursor(query.cursor), limit);
    return toPage(
      rows,
      limit,
      (row) => timeCursor(row.decidedAt ?? row.requestedAt, row.id),
      (row) => ({
        id: row.id,
        rideId: row.rideId,
        userId: row.user.id,
        name: row.user.name,
        avatarUrl: row.user.avatarUrl,
        joinedAt: row.decidedAt ?? row.requestedAt,
      }),
    );
  }

  // --- Organizer actions -------------------------------------------------------

  async create(organizer: Actor, input: RideInput): Promise<RideDto> {
    const imageUrl = input.imageUrl?.trim() ?? '';
    assertImageUrl(imageUrl, 'imageUrl');
    const ride = await this.repo.create({
      organizerId: organizer.id,
      title: input.title.trim(),
      description: input.description.trim(),
      rideType: input.rideType,
      category: RIDE_TYPE_CATEGORY[input.rideType],
      difficulty: input.difficulty,
      startsAt: parseStart(input.date),
      meetingPoint: input.meetingPoint.trim(),
      distanceKm: input.distanceKm,
      durationMinutes: input.durationMinutes,
      maxParticipants: input.maxParticipants,
      requirements: cleanList(input.requirements),
      imageUrl,
    });
    return toRideDto(ride, null, organizer.id);
  }

  private assertCanManage(ride: { organizerId: string }, actor: Actor): void {
    if (ride.organizerId !== actor.id && actor.role !== 'admin') {
      throw forbidden('Only the organizer can manage this ride.', 'NOT_RIDE_ORGANIZER');
    }
  }

  /** Organizer (or admin) edit. Riders and pending requesters are told what changed. */
  async update(actor: Actor, rideId: string, input: Partial<RideInput>): Promise<RideDto> {
    const ride = await this.uow.run(async (ctx) => {
      await this.repo.lockRide(ctx.db, rideId);
      const current = await this.repo.findById(rideId, ctx.db);
      if (!current) throw RIDE_NOT_FOUND();
      this.assertCanManage(current, actor);
      if (current.startsAt <= new Date() && actor.role !== 'admin') {
        throw conflict('This ride has already started and can no longer be edited.', 'RIDE_ALREADY_STARTED');
      }

      const data: Prisma.RideUpdateInput = {};
      const changed: string[] = [];
      const set = <K extends keyof Prisma.RideUpdateInput>(key: K, value: Prisma.RideUpdateInput[K], label: string, same: boolean) => {
        if (same) return;
        data[key] = value;
        changed.push(label);
      };
      if (input.title !== undefined) set('title', input.title.trim(), 'title', input.title.trim() === current.title);
      if (input.description !== undefined)
        set('description', input.description.trim(), 'description', input.description.trim() === current.description);
      if (input.date !== undefined) {
        const startsAt = parseStart(input.date);
        set('startsAt', startsAt, 'start time', startsAt.getTime() === current.startsAt.getTime());
      }
      if (input.meetingPoint !== undefined)
        set('meetingPoint', input.meetingPoint.trim(), 'meeting point', input.meetingPoint.trim() === current.meetingPoint);
      if (input.rideType !== undefined) {
        set('rideType', input.rideType, 'ride type', input.rideType === current.rideType);
        data.category = RIDE_TYPE_CATEGORY[input.rideType];
      }
      if (input.difficulty !== undefined) set('difficulty', input.difficulty, 'difficulty', input.difficulty === current.difficulty);
      if (input.distanceKm !== undefined) set('distanceKm', input.distanceKm, 'distance', input.distanceKm === current.distanceKm);
      if (input.durationMinutes !== undefined)
        set('durationMinutes', input.durationMinutes, 'duration', input.durationMinutes === current.durationMinutes);
      if (input.maxParticipants !== undefined) {
        if (input.maxParticipants < current.participantCount) {
          throw unprocessable(
            `${current.participantCount} riders are already going; the limit cannot be lower than that.`,
            'MAX_BELOW_PARTICIPANTS',
          );
        }
        set('maxParticipants', input.maxParticipants, 'group size', input.maxParticipants === current.maxParticipants);
      }
      if (input.requirements !== undefined) {
        const requirements = cleanList(input.requirements);
        set('requirements', requirements, 'requirements', requirements.join('\n') === current.requirements.join('\n'));
      }
      if (input.imageUrl !== undefined) {
        const imageUrl = input.imageUrl?.trim() ?? '';
        assertImageUrl(imageUrl, 'imageUrl');
        set('imageUrl', imageUrl, 'cover photo', imageUrl === current.imageUrl);
      }
      if (changed.length === 0) return current;

      const updated = await this.repo.update(rideId, data, ctx.db);
      const audience = await this.repo.audience(rideId, ctx.db);
      await this.notifications.notifyMany(
        ctx,
        audience.map((recipientId) => ({
          recipientId,
          actorId: actor.id,
          type: 'rideUpdated' as const,
          title: 'Ride updated',
          body: `The ${describeChanges(changed)} for ${updated.title} ${changed.length === 1 ? 'has' : 'have'} changed.`,
          entityType: 'ride' as const,
          entityId: rideId,
          collapseKey: `rideUpdated:${rideId}`,
        })),
      );
      return updated;
    });
    const mine = await this.repo.myRequests([ride.id], actor.id);
    return toRideDto(ride, mine.get(ride.id), actor.id);
  }

  /** Organizer cancels, or an admin removes, a ride. Riders and requesters are notified. */
  async remove(actor: Actor, rideId: string): Promise<void> {
    await this.uow.run(async (ctx) => {
      const ride = await this.repo.findById(rideId, ctx.db);
      if (!ride) throw RIDE_NOT_FOUND();
      this.assertCanManage(ride, actor);
      const byModerator = ride.organizerId !== actor.id;
      const audience = await this.repo.audience(rideId, ctx.db);
      const recipients = byModerator ? [...audience, ride.organizerId] : audience;
      await this.notifications.notifyMany(
        ctx,
        recipients.map((recipientId) => ({
          recipientId,
          actorId: byModerator ? null : actor.id,
          type: 'rideUpdated' as const,
          title: 'Ride cancelled',
          body: byModerator ? `${ride.title} was removed by a moderator.` : `${ride.title} was cancelled by the organizer.`,
          entityType: 'ride' as const,
          entityId: rideId,
        })),
      );
      if (byModerator) {
        await audit(ctx.db, { actorId: actor.id, action: 'ride.delete', targetType: 'ride', targetId: rideId, details: { title: ride.title } });
      }
      await this.repo.delete(rideId, ctx.db);
    });
  }

  // --- Join flow ---------------------------------------------------------------

  /** Ask to join a ride. A declined rider may ask again (the request goes back to pending). */
  async requestToJoin(rider: Actor, rideId: string, message?: string): Promise<RideRequestDto> {
    const note = blankToNull(message);
    return this.uow.run(async (ctx) => {
      const ride = await this.repo.findById(rideId, ctx.db);
      if (!ride) throw RIDE_NOT_FOUND();
      if (ride.organizerId === rider.id) throw conflict('You are organizing this ride.', 'CANNOT_JOIN_OWN_RIDE');
      if (ride.startsAt <= new Date()) throw conflict('This ride has already started.', 'RIDE_ALREADY_STARTED');
      if (ride.participantCount >= ride.maxParticipants) throw conflict('This ride is full.', 'RIDE_FULL');

      const existing = await this.repo.findRequestFor(rideId, rider.id, ctx.db);
      if (existing && existing.status !== 'declined') {
        throw conflict(
          existing.status === 'approved' ? 'You are already going on this ride.' : 'You have already asked to join this ride.',
          'ALREADY_REQUESTED',
        );
      }
      const request = existing
        ? await this.repo.resubmitRequest(ctx.db, existing.id, note)
        : await this.repo.createRequest(ctx.db, { rideId, userId: rider.id, message: note });

      await this.notifications.notify(ctx, {
        recipientId: ride.organizerId,
        actorId: rider.id,
        type: 'newRideRequest',
        title: 'New join request',
        body: `${rider.name} wants to join ${ride.title}.`,
        entityType: 'ride',
        entityId: rideId,
        collapseKey: `joinRequest:${request.id}`,
      });
      return toRideRequestDto(request);
    });
  }

  /** Withdraw a pending request, or leave a ride you were approved for. */
  async leave(rider: Actor, rideId: string): Promise<void> {
    await this.uow.run(async (ctx) => {
      const ride = await this.repo.findById(rideId, ctx.db);
      if (!ride) throw RIDE_NOT_FOUND();
      if (ride.organizerId === rider.id) {
        throw conflict('Organizers cannot leave their own ride. Cancel the ride instead.', 'ORGANIZER_CANNOT_LEAVE');
      }
      const existing = await this.repo.findRequestFor(rideId, rider.id, ctx.db);
      if (!existing || existing.status === 'declined') {
        throw notFound('You have not asked to join this ride.', 'NO_ACTIVE_REQUEST');
      }
      await this.repo.deleteRequest(ctx.db, existing.id);
    });
  }

  // --- Organizer request inbox --------------------------------------------------

  async requestsForRide(actor: Actor, rideId: string, query: { status?: RideRequestStatus; limit?: number; cursor?: string }) {
    const ride = await this.repo.findById(rideId);
    if (!ride) throw RIDE_NOT_FOUND();
    this.assertCanManage(ride, actor);
    return this.requestPage({ rideId, ...(query.status ? { status: query.status } : {}) }, query);
  }

  /** Requests across every ride the organizer runs. */
  async inbox(organizerId: string, query: { status?: RideRequestStatus; limit?: number; cursor?: string }) {
    return this.requestPage({ ride: { organizerId }, ...(query.status ? { status: query.status } : {}) }, query);
  }

  /** Admin: every request. */
  async allRequests(query: { status?: RideRequestStatus; limit?: number; cursor?: string }) {
    return this.requestPage(query.status ? { status: query.status } : {}, query);
  }

  private async requestPage(where: Prisma.RideRequestWhereInput, query: { limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findRequestsPage(where, decodeTimeCursor(query.cursor), limit);
    return toPage(rows, limit, (row) => timeCursor(row.requestedAt, row.id), toRideRequestDto);
  }

  async approve(actor: Actor, requestId: string): Promise<RideRequestDto> {
    return this.decide(actor, requestId, 'approved', null);
  }

  async decline(actor: Actor, requestId: string, reason?: string | null): Promise<RideRequestDto> {
    return this.decide(actor, requestId, 'declined', blankToNull(reason));
  }

  private async decide(actor: Actor, requestId: string, status: 'approved' | 'declined', reason: string | null) {
    try {
      return await this.uow.run(async (ctx: TxContext) => {
        await this.repo.lockRequestAndRide(ctx.db, requestId);
        const request = await this.repo.findRequest(requestId, ctx.db);
        if (!request) throw REQUEST_NOT_FOUND();
        this.assertCanManage(request.ride, actor);
        if (request.status !== 'pending') {
          throw conflict(`This request was already ${request.status}.`, 'REQUEST_NOT_PENDING');
        }
        if (request.ride.startsAt <= new Date()) throw conflict('This ride has already started.', 'RIDE_ALREADY_STARTED');
        if (status === 'approved') {
          const ride = await this.repo.findById(request.rideId, ctx.db);
          if (ride && ride.participantCount >= ride.maxParticipants) throw conflict('This ride is full.', 'RIDE_FULL');
        }

        const decided = await this.repo.decideRequest(ctx.db, requestId, { status, deciderId: actor.id, declineReason: reason });
        const title = decided.ride.title;
        await this.notifications.notify(ctx, {
          recipientId: decided.userId,
          actorId: actor.id,
          type: status === 'approved' ? 'requestApproved' : 'requestDeclined',
          title: status === 'approved' ? 'Request approved' : 'Request declined',
          body:
            status === 'approved'
              ? `${actor.name} approved your request to join ${title}.`
              : `Your request to join ${title} was declined${reason ? ` — ${reason}` : '.'}`,
          entityType: 'ride',
          entityId: decided.rideId,
        });
        if (actor.role === 'admin' && request.ride.organizerId !== actor.id) {
          await audit(ctx.db, { actorId: actor.id, action: `rideRequest.${status}`, targetType: 'rideRequest', targetId: requestId });
        }
        return toRideRequestDto(decided);
      });
    } catch (err) {
      // The capacity CHECK constraint is the last line of defence against overfilling.
      if (isCheckViolation(err)) throw conflict('This ride is full.', 'RIDE_FULL');
      throw err;
    }
  }

  /** Organizer badge: pending requests on upcoming rides. */
  pendingCountFor(organizerId: string): Promise<number> {
    return this.repo.countPendingForOrganizer(organizerId);
  }
}
