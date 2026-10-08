import type { UserRole } from '../constants/enums.js';
import type { UnitOfWork } from '../db/prisma.js';
import type { TopUserMetric } from '../constants/enums.js';
import type { RealtimeHub } from '../realtime/hub.js';
import type { AdminRepository } from '../repositories/admin.repository.js';
import type { AuthRepository } from '../repositories/auth.repository.js';
import type { BannerRepository } from '../repositories/banner.repository.js';
import type { ProfileRecord } from '../repositories/user.repository.js';
import { audit } from '../utils/audit.js';
import { isUniqueViolation } from '../utils/db-errors.js';
import { conflict, forbidden, notFound } from '../utils/errors.js';
import { decodeCursor, decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';
import type { PasswordHasher } from '../utils/password.js';
import { normalizeEmail } from './auth.service.js';
import type { GroupService } from './group.service.js';
import { toBannerDto } from './home.service.js';
import type { NotificationService } from './notification.service.js';
import type { PlaceInput, PlaceService } from './place.service.js';
import type { PostService } from './post.service.js';
import type { Actor, RideInput, RideService } from './ride.service.js';
import type { TokenService } from './token.service.js';
import { toUserProfile, type ProfileUpdate, type UserService } from './user.service.js';

export interface AdminUserUpdate extends ProfileUpdate {
  email?: string;
}

/** The services an admin acts through; edits reuse their validation and notifications. */
export interface AdminDeps {
  auth: AuthRepository;
  passwords: PasswordHasher;
  tokens: TokenService;
  realtime: RealtimeHub;
  notifications: NotificationService;
  rides: RideService;
  posts: PostService;
  places: PlaceService;
  groups: GroupService;
}

const USER_NOT_FOUND = () => notFound('This rider could not be found.', 'USER_NOT_FOUND');

/** Recipients per transaction when sending an announcement. */
const ANNOUNCE_BATCH = 200;

/** Which fields an edit touched, for the audit log. */
const changedFields = (input: object) => Object.keys(input).sort().join(', ');

export interface BannerInput {
  category?: 'cycling' | 'trekking' | 'hiking' | 'riding' | null;
  title?: string;
  subtitle?: string;
  ctaLabel?: string;
  ctaUrl?: string | null;
  imageUrl?: string | null;
  icon?: string | null;
  theme?: string | null;
  sortOrder?: number;
  isActive?: boolean;
  startsAt?: string | null;
  endsAt?: string | null;
}

function bannerData(input: BannerInput) {
  const date = (value: string | null | undefined) =>
    value === undefined ? undefined : value === null ? null : new Date(value);
  return {
    ...(input.category !== undefined ? { category: input.category } : {}),
    ...(input.title !== undefined ? { title: input.title.trim() } : {}),
    ...(input.subtitle !== undefined ? { subtitle: input.subtitle.trim() } : {}),
    ...(input.ctaLabel !== undefined ? { ctaLabel: input.ctaLabel.trim() } : {}),
    ...(input.ctaUrl !== undefined ? { ctaUrl: input.ctaUrl } : {}),
    ...(input.imageUrl !== undefined ? { imageUrl: input.imageUrl } : {}),
    ...(input.icon !== undefined ? { icon: input.icon } : {}),
    ...(input.theme !== undefined ? { theme: input.theme } : {}),
    ...(input.sortOrder !== undefined ? { sortOrder: input.sortOrder } : {}),
    ...(input.isActive !== undefined ? { isActive: input.isActive } : {}),
    ...(input.startsAt !== undefined ? { startsAt: date(input.startsAt) } : {}),
    ...(input.endsAt !== undefined ? { endsAt: date(input.endsAt) } : {}),
  };
}

/**
 * Admin dashboard: stats, user management (edit, disable, sign out, reset
 * password, role, removal), editing and removing anyone's content, banners,
 * announcements and the moderation log. Every change is audited.
 */
export class AdminService {
  constructor(
    private readonly uow: UnitOfWork,
    private readonly repo: AdminRepository,
    private readonly users: UserService,
    private readonly banners: BannerRepository,
    private readonly deps: AdminDeps,
  ) {}

  stats() {
    return this.repo.stats();
  }

  async analytics(days = 30) {
    const now = new Date();
    const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
    const from = new Date(today - (days - 1) * 86_400_000);
    const [daily, activeUsers, breakdowns] = await Promise.all([
      this.repo.dailyActivity(from),
      this.repo.activeUsers(now),
      this.repo.breakdowns(),
    ]);
    const keys = [
      'signups',
      'rides',
      'joinRequests',
      'posts',
      'comments',
      'messages',
      'places',
      'feedback',
    ] as const;
    const totals = Object.fromEntries(
      keys.map((key) => [key, daily.reduce((sum, row) => sum + row[key], 0)]),
    ) as Record<(typeof keys)[number], number>;
    return {
      days,
      totals,
      daily: daily.map(({ day, ...counts }) => ({ date: day.toISOString().slice(0, 10), ...counts })),
      activeUsers,
      ...breakdowns,
    };
  }

  async topUsers(metric: TopUserMetric = 'followers', limit = 10) {
    const rows = await this.repo.topUsers(metric, limit);
    return {
      metric,
      items: rows.map((row, index) => ({
        rank: index + 1,
        id: row.id,
        name: row.name,
        email: row.email,
        avatarUrl: row.avatar_url,
        joinedAt: row.created_at,
        followers: row.followers_count,
        ridesOrganized: row.rides_organized,
        ridesJoined: row.rides_joined,
        posts: row.posts,
        likesReceived: row.likes_received,
        places: row.places,
      })),
    };
  }

  async listUsers(
    admin: Actor,
    query: {
      q?: string;
      role?: UserRole;
      status?: 'active' | 'disabled';
      limit?: number;
      cursor?: string;
    },
  ) {
    const limit = pageLimit(query.limit);
    const after = decodeCursor(query.cursor, ['string', 'string']) as [string, string] | null;
    const rows = await this.users.repo.list({
      viewerId: admin.id,
      ...(query.q ? { q: query.q } : {}),
      role: query.role ?? 'user',
      ...(query.status ? { status: query.status } : {}),
      includePrivate: true,
      after,
      limit,
    });
    return toPage(
      rows,
      limit,
      (row) => [row.name, row.id],
      (row) => this.toAdminUser(row, admin),
    );
  }

  private toAdminUser(row: ProfileRecord, admin: Actor) {
    return {
      ...toUserProfile(row, admin),
      role: row.role,
      createdAt: row.createdAt,
      lastLoginAt: row.lastLoginAt,
      disabledAt: row.disabledAt,
      disabledReason: row.disabledReason,
    };
  }

  /** Everything about one user: profile, status, activity and signed-in devices. */
  async getUser(admin: Actor, userId: string) {
    const row = await this.users.repo.findProfile(userId, admin.id);
    if (!row) throw USER_NOT_FOUND();
    const [activity, sessions] = await Promise.all([
      this.users.repo.activityCounts(userId),
      this.deps.auth.listActiveSessions(userId),
    ]);
    return { ...this.toAdminUser(row, admin), activity, sessions };
  }

  /** Edits any account's profile, including its sign-in email. */
  async updateUser(admin: Actor, userId: string, input: AdminUserUpdate) {
    const target = await this.users.repo.findCredentials(userId);
    if (!target) throw USER_NOT_FOUND();
    const { email: rawEmail, ...profile } = input;
    const email = rawEmail === undefined ? undefined : normalizeEmail(rawEmail);
    if (email !== undefined && email !== target.email) {
      try {
        await this.users.repo.update(userId, { email });
      } catch (err) {
        if (isUniqueViolation(err)) throw conflict('Another account already uses this email.', 'EMAIL_TAKEN');
        throw err;
      }
    }
    if (Object.keys(profile).length > 0) await this.users.updateProfile(userId, profile);
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'user.update',
      targetType: 'user',
      targetId: userId,
      details: { name: target.name, fields: changedFields(input) },
    });
    return this.getUser(admin, userId);
  }

  /**
   * Disables (suspends) or re-enables an account. Disabling signs it out on
   * every device at once; it cannot sign in again until re-enabled.
   */
  async setDisabled(admin: Actor, userId: string, disabled: boolean, reason?: string | null) {
    if (userId === admin.id) throw conflict('You cannot disable your own account.', 'CANNOT_DISABLE_SELF');
    const target = await this.users.repo.findCredentials(userId);
    if (!target) throw USER_NOT_FOUND();
    if (disabled && target.role === 'superadmin')
      throw forbidden('Demote this superadmin before disabling them.', 'CANNOT_DISABLE_SUPERADMIN');
    const cleanReason = reason?.trim() || null;
    await this.uow.run(async ({ db }) => {
      await this.users.repo.update(
        userId,
        disabled
          ? { disabledAt: target.disabledAt ?? new Date(), disabledReason: cleanReason }
          : { disabledAt: null, disabledReason: null },
        db,
      );
      if (disabled) await this.deps.auth.revokeUserSessions(userId, 'disabled_by_admin', {}, db);
      await audit(db, {
        actorId: admin.id,
        action: disabled ? 'user.disable' : 'user.enable',
        targetType: 'user',
        targetId: userId,
        details: { name: target.name, ...(disabled ? { reason: cleanReason } : {}) },
      });
    });
    if (disabled) this.endSessions(userId, 'account disabled');
    return this.getUser(admin, userId);
  }

  /** Signs a user out on every device (they can sign straight back in). */
  async signOutEverywhere(admin: Actor, userId: string) {
    if (userId === admin.id)
      throw conflict('Sign yourself out from the account menu instead.', 'CANNOT_SIGN_OUT_SELF');
    const target = await this.users.repo.findCredentials(userId);
    if (!target) throw USER_NOT_FOUND();
    await this.uow.run(async ({ db }) => {
      await this.deps.auth.revokeUserSessions(userId, 'signed_out_by_admin', {}, db);
      await audit(db, {
        actorId: admin.id,
        action: 'user.signOut',
        targetType: 'user',
        targetId: userId,
        details: { name: target.name },
      });
    });
    this.endSessions(userId, 'signed out by an admin');
    return this.getUser(admin, userId);
  }

  /** Sets a new password for someone locked out; signs them out everywhere. */
  async setPassword(admin: Actor, userId: string, newPassword: string) {
    if (userId === admin.id)
      throw conflict('Change your own password from your account settings.', 'CANNOT_RESET_OWN_PASSWORD');
    const target = await this.users.repo.findCredentials(userId);
    if (!target) throw USER_NOT_FOUND();
    const passwordHash = await this.deps.passwords.hash(newPassword);
    await this.uow.run(async ({ db }) => {
      await this.deps.auth.updatePasswordHash(userId, passwordHash, db);
      await this.deps.auth.revokeUserSessions(userId, 'password_set_by_admin', {}, db);
      await audit(db, {
        actorId: admin.id,
        action: 'user.setPassword',
        targetType: 'user',
        targetId: userId,
        details: { name: target.name },
      });
    });
    this.endSessions(userId, 'password changed by an admin');
  }

  private endSessions(userId: string, reason: string) {
    this.deps.tokens.forgetUser(userId);
    this.deps.realtime.disconnectUser(userId, reason);
  }

  // --- Anyone's content ------------------------------------------------------------

  async editRide(admin: Actor, rideId: string, input: Partial<RideInput>) {
    const ride = await this.deps.rides.update(admin, rideId, input);
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'ride.update',
      targetType: 'ride',
      targetId: rideId,
      details: { title: ride.title, fields: changedFields(input) },
    });
    return ride;
  }

  async editPost(admin: Actor, postId: string, input: { text?: string; imageUrl?: string | null }) {
    const post = await this.deps.posts.update(admin, postId, input);
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'post.update',
      targetType: 'post',
      targetId: postId,
      details: { text: post.text.slice(0, 120), fields: changedFields(input) },
    });
    return post;
  }

  async editPlace(admin: Actor, placeId: string, input: Partial<PlaceInput>) {
    const place = await this.deps.places.update(admin, placeId, input);
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'place.update',
      targetType: 'place',
      targetId: placeId,
      details: { name: place.name, fields: changedFields(input) },
    });
    return place;
  }

  async editGroup(
    admin: Actor,
    groupId: string,
    input: { name?: string; description?: string; coverImageUrl?: string | null },
  ) {
    const group = await this.deps.groups.update(admin, groupId, input);
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'group.update',
      targetType: 'group',
      targetId: groupId,
      details: { name: group.name, fields: changedFields(input) },
    });
    return group;
  }

  async comments(query: { q?: string; postId?: string; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.commentsPage(decodeTimeCursor(query.cursor), limit, {
      ...(query.q?.trim() ? { q: query.q.trim() } : {}),
      ...(query.postId ? { postId: query.postId } : {}),
    });
    return toPage(
      rows,
      limit,
      (row) => timeCursor(row.createdAt, row.id),
      (row) => ({
        id: row.id,
        text: row.text,
        likeCount: row.likeCount,
        createdAt: row.createdAt,
        author: row.author,
        post: { id: row.post.id, text: row.post.text.slice(0, 160) },
      }),
    );
  }

  async removeComment(admin: Actor, commentId: string): Promise<void> {
    await this.deps.posts.removeComment(admin, commentId);
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'comment.delete',
      targetType: 'comment',
      targetId: commentId,
    });
  }

  async reviews(query: { q?: string; placeId?: string; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.reviewsPage(decodeTimeCursor(query.cursor), limit, {
      ...(query.q?.trim() ? { q: query.q.trim() } : {}),
      ...(query.placeId ? { placeId: query.placeId } : {}),
    });
    return toPage(
      rows,
      limit,
      (row) => timeCursor(row.createdAt, row.id),
      (row) => ({
        id: row.id,
        rating: row.rating,
        worthIt: row.worthIt,
        text: row.text,
        photos: row.photos,
        createdAt: row.createdAt,
        author: row.author,
        place: row.place,
      }),
    );
  }

  async removeReview(admin: Actor, reviewId: string): Promise<void> {
    await this.uow.run(async ({ db }) => {
      const review = await this.repo.deleteReview(reviewId, db);
      if (!review) throw notFound('This review could not be found.', 'REVIEW_NOT_FOUND');
      await audit(db, {
        actorId: admin.id,
        action: 'review.delete',
        targetType: 'place',
        targetId: review.place.id,
        details: { place: review.place.name, rating: review.rating, text: review.text.slice(0, 120) },
      });
    });
  }

  // --- Announcements -----------------------------------------------------------------

  /** Sends an in-app notification (and a push, if configured) to every active rider. */
  async announce(admin: Actor, input: { title: string; message: string }) {
    const title = input.title.trim();
    const message = input.message.trim();
    const recipients = await this.repo.announcementRecipients();
    for (let i = 0; i < recipients.length; i += ANNOUNCE_BATCH) {
      const batch = recipients.slice(i, i + ANNOUNCE_BATCH);
      await this.uow.run((ctx) =>
        this.deps.notifications.notifyMany(
          ctx,
          batch.map((recipientId) => ({ recipientId, type: 'announcement' as const, title, body: message })),
        ),
      );
    }
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'announcement.send',
      targetType: 'announcement',
      details: { title, message, recipients: recipients.length },
    });
    return { recipients: recipients.length };
  }

  /** Announcements sent so far, newest first (read from the audit log). */
  async announcements(query: { limit?: number; cursor?: string }) {
    return this.auditLog({ ...query, action: 'announcement.send' });
  }

  async setRole(admin: Actor, userId: string, role: UserRole) {
    if (userId === admin.id) throw conflict('You cannot change your own role.', 'CANNOT_CHANGE_OWN_ROLE');
    if (!(await this.users.repo.exists(userId)))
      throw notFound('This rider could not be found.', 'USER_NOT_FOUND');
    await this.uow.run(async ({ db }) => {
      await this.users.repo.update(userId, { role }, db);
      await audit(db, {
        actorId: admin.id,
        action: 'user.setRole',
        targetType: 'user',
        targetId: userId,
        details: { role },
      });
    });
    return this.users.getProfile(userId, admin);
  }

  /** Removes a rider and everything they own. Admins must be demoted first. */
  async removeUser(admin: Actor, userId: string): Promise<void> {
    if (userId === admin.id) throw conflict('You cannot remove your own account here.', 'CANNOT_REMOVE_SELF');
    const target = await this.users.repo.findCredentials(userId);
    if (!target) throw notFound('This rider could not be found.', 'USER_NOT_FOUND');
    if (target.role === 'superadmin')
      throw forbidden('Demote this superadmin before removing them.', 'CANNOT_REMOVE_SUPERADMIN');
    await audit(this.uow.prisma, {
      actorId: admin.id,
      action: 'user.remove',
      targetType: 'user',
      targetId: userId,
      details: { name: target.name },
    });
    await this.users.removeUser(userId);
  }

  async auditLog(query: { limit?: number; cursor?: string; action?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.auditPage(decodeTimeCursor(query.cursor), limit, query.action);
    return toPage(
      rows,
      limit,
      (row) => timeCursor(row.createdAt, row.id),
      (row) => ({
        id: row.id,
        actorId: row.actorId,
        actorName: row.actor?.name ?? null,
        action: row.action,
        targetType: row.targetType,
        targetId: row.targetId,
        details: row.details,
        createdAt: row.createdAt,
      }),
    );
  }

  async listBanners() {
    return (await this.banners.all()).map(toBannerDto);
  }

  async createBanner(input: BannerInput & { title: string }) {
    return toBannerDto(await this.banners.create({ ...bannerData(input), title: input.title.trim() }));
  }

  async updateBanner(id: string, input: BannerInput) {
    if (!(await this.banners.findById(id)))
      throw notFound('This banner could not be found.', 'BANNER_NOT_FOUND');
    return toBannerDto(await this.banners.update(id, bannerData(input)));
  }

  async deleteBanner(id: string): Promise<void> {
    if (!(await this.banners.delete(id)))
      throw notFound('This banner could not be found.', 'BANNER_NOT_FOUND');
  }
}
