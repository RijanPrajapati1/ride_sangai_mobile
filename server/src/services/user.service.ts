import {
  RIDE_TYPE_CATEGORY,
  rideTypesFor,
  type ActivityCategory,
  type ExperienceLevel,
  type RideType,
  type UserRole,
} from '../constants/enums.js';
import type { UnitOfWork } from '../db/prisma.js';
import type { RealtimeHub } from '../realtime/hub.js';
import type { ProfileRecord, UserRepository } from '../repositories/user.repository.js';
import { badRequest, notFound } from '../utils/errors.js';
import { decodeCursor, decodeTimeCursor, pageLimit, toPage } from '../utils/pagination.js';
import type { PasswordHasher } from '../utils/password.js';
import { assertImageUrl, cleanList } from '../utils/validation.js';
import type { NotificationService } from './notification.service.js';
import type { TokenService } from './token.service.js';

export interface Viewer {
  id: string | null;
  role?: UserRole;
}

export interface ProfileUpdate {
  name?: string;
  avatarUrl?: string;
  bio?: string;
  location?: string;
  experienceLevel?: ExperienceLevel;
  preferredRideType?: RideType;
  cyclingInterests?: string[];
}

/** Mirrors the Dart `UserPreferences` entity. */
export interface Preferences {
  pushRideReminders: boolean;
  pushMessages: boolean;
  pushCommunityActivity: boolean;
  darkModeEnabled: boolean;
  publicProfile: boolean;
  showRidingStats: boolean;
}

export function toPreferences(row: Preferences): Preferences {
  return {
    pushRideReminders: row.pushRideReminders,
    pushMessages: row.pushMessages,
    pushCommunityActivity: row.pushCommunityActivity,
    darkModeEnabled: row.darkModeEnabled,
    publicProfile: row.publicProfile,
    showRidingStats: row.showRidingStats,
  };
}

/**
 * Maps a profile to the API shape (the Dart `UserProfile` entity), applying the
 * owner's privacy settings for everyone except the owner and admins:
 * publicProfile=false hides bio, location, interests and stats;
 * showRidingStats=false reports ride stats as 0.
 */
export function toUserProfile(row: ProfileRecord, viewer: Viewer) {
  const isMe = viewer.id === row.id;
  const privileged = isMe || viewer.role === 'admin';
  const isPrivate = !row.publicProfile;
  const hidePrivate = isPrivate && !privileged;
  const hideStats = (!row.showRidingStats || isPrivate) && !privileged;
  return {
    id: row.id,
    name: row.name,
    email: privileged ? row.email : null,
    avatarUrl: row.avatarUrl,
    bio: hidePrivate ? '' : row.bio,
    location: hidePrivate ? '' : row.location,
    experienceLevel: row.experienceLevel,
    preferredRideType: row.preferredRideType,
    cyclingInterests: hidePrivate ? [] : row.interests,
    totalRides: hideStats ? 0 : row.totalRides,
    completedRides: hideStats ? 0 : row.completedRides,
    followersCount: row.followersCount,
    followingCount: row.followingCount,
    isFollowing: row.isFollowing,
    isMe,
    isPrivate,
    statsHidden: !row.showRidingStats,
  };
}

export type UserProfileDto = ReturnType<typeof toUserProfile>;

const USER_NOT_FOUND = () => notFound('This rider could not be found.', 'USER_NOT_FOUND');

/** Profiles, preferences, follows, recommendations and account deletion. */
export class UserService {
  constructor(
    private readonly uow: UnitOfWork,
    readonly repo: UserRepository,
    private readonly notifications: NotificationService,
    private readonly passwords: PasswordHasher,
    private readonly tokens: TokenService,
    private readonly realtime: RealtimeHub,
  ) {}

  async getProfile(userId: string, viewer: Viewer): Promise<UserProfileDto> {
    const row = await this.repo.findProfile(userId, viewer.id);
    if (!row) throw USER_NOT_FOUND();
    return toUserProfile(row, viewer);
  }

  async updateProfile(userId: string, input: ProfileUpdate): Promise<UserProfileDto> {
    const avatarUrl = input.avatarUrl?.trim();
    if (avatarUrl !== undefined) assertImageUrl(avatarUrl, 'avatarUrl');
    await this.repo.update(userId, {
      ...(input.name !== undefined ? { name: input.name.trim() } : {}),
      ...(avatarUrl !== undefined ? { avatarUrl } : {}),
      ...(input.bio !== undefined ? { bio: input.bio.trim() } : {}),
      ...(input.location !== undefined ? { location: input.location.trim() } : {}),
      ...(input.experienceLevel !== undefined ? { experienceLevel: input.experienceLevel } : {}),
      ...(input.preferredRideType !== undefined ? { preferredRideType: input.preferredRideType } : {}),
      ...(input.cyclingInterests !== undefined ? { interests: cleanList(input.cyclingInterests) } : {}),
    });
    return this.getProfile(userId, { id: userId });
  }

  async deleteAccount(userId: string, password: string): Promise<void> {
    const user = await this.repo.findCredentials(userId);
    if (!user) throw USER_NOT_FOUND();
    if (!(await this.passwords.verify(user.passwordHash, password))) {
      throw badRequest('Your password is incorrect.', 'WRONG_PASSWORD');
    }
    await this.removeUser(userId);
  }

  /** Hard delete: everything the user owns cascades; counters are fixed by triggers. */
  async removeUser(userId: string): Promise<boolean> {
    const deleted = await this.repo.delete(userId);
    this.tokens.forgetUser(userId);
    this.realtime.disconnectUser(userId, 'account removed');
    return deleted;
  }

  async getPreferences(userId: string): Promise<Preferences> {
    return toPreferences(await this.repo.getOrCreatePreferences(userId));
  }

  async updatePreferences(userId: string, changes: Partial<Preferences>): Promise<Preferences> {
    return toPreferences(await this.repo.updatePreferences(userId, changes));
  }

  async follow(followerId: string, targetId: string) {
    if (followerId === targetId) throw badRequest('You cannot follow yourself.', 'CANNOT_FOLLOW_SELF');
    return this.uow.run(async (ctx) => {
      if (!(await this.repo.exists(targetId, ctx.db))) throw USER_NOT_FOUND();
      if (await this.repo.insertFollow(followerId, targetId, ctx.db)) {
        const actor = await this.repo.findCredentials(followerId, ctx.db);
        await this.notifications.notify(ctx, {
          recipientId: targetId,
          actorId: followerId,
          type: 'newFollower',
          title: 'New follower',
          body: `${actor?.name ?? 'Someone'} started following you.`,
          entityType: 'user',
          entityId: followerId,
          // follow → unfollow → follow does not stack notifications.
          collapseKey: `follow:${followerId}`,
        });
      }
      return { isFollowing: true, followersCount: await this.repo.followersCount(targetId, ctx.db) };
    });
  }

  async unfollow(followerId: string, targetId: string) {
    if (!(await this.repo.exists(targetId))) throw USER_NOT_FOUND();
    await this.repo.deleteFollow(followerId, targetId);
    return { isFollowing: false, followersCount: await this.repo.followersCount(targetId) };
  }

  /** Category defaults to the dashboard category of the viewer's preferred ride type. */
  async recommended(
    viewer: Viewer & { id: string },
    options: { category?: ActivityCategory; limit?: number },
  ) {
    let category = options.category;
    if (!category) {
      const me = await this.repo.findProfile(viewer.id, null);
      category = me ? RIDE_TYPE_CATEGORY[me.preferredRideType] : 'cycling';
    }
    const rows = await this.repo.recommended(
      viewer.id,
      rideTypesFor(category),
      Math.min(options.limit ?? 10, 50),
    );
    return rows.map((row) => toUserProfile(row, viewer));
  }

  async search(viewer: Viewer, query: { q?: string; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const after = decodeCursor(query.cursor, ['string', 'string']) as [string, string] | null;
    const rows = await this.repo.list({ viewerId: viewer.id, q: query.q, role: 'user', after, limit });
    return toPage(
      rows,
      limit,
      (row) => [row.name, row.id],
      (row) => toUserProfile(row, viewer),
    );
  }

  async followEdges(
    userId: string,
    direction: 'followers' | 'following',
    viewerId: string,
    query: { limit?: number; cursor?: string },
  ) {
    if (!(await this.repo.exists(userId))) throw USER_NOT_FOUND();
    const limit = pageLimit(query.limit);
    const after = decodeTimeCursor(query.cursor);
    const rows = await this.repo.followEdges(userId, direction, viewerId, after, limit);
    return toPage(rows, limit, (row) => [row.followedAt.toISOString(), row.id]);
  }
}
