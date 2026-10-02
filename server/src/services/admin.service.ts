import type { UserRole } from '../constants/enums.js';
import type { UnitOfWork } from '../db/prisma.js';
import type { AdminRepository } from '../repositories/admin.repository.js';
import type { BannerRepository } from '../repositories/banner.repository.js';
import { audit } from '../utils/audit.js';
import { conflict, forbidden, notFound } from '../utils/errors.js';
import { decodeCursor, decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';
import { toBannerDto } from './home.service.js';
import type { Actor } from './ride.service.js';
import { toUserProfile, type UserService } from './user.service.js';

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
  const date = (value: string | null | undefined) => (value === undefined ? undefined : value === null ? null : new Date(value));
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

/** Admin dashboard: stats, rider management, banners and the moderation log. */
export class AdminService {
  constructor(
    private readonly uow: UnitOfWork,
    private readonly repo: AdminRepository,
    private readonly users: UserService,
    private readonly banners: BannerRepository,
  ) {}

  stats() {
    return this.repo.stats();
  }

  async listUsers(admin: Actor, query: { q?: string; role?: UserRole; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const after = decodeCursor(query.cursor, ['string', 'string']) as [string, string] | null;
    const rows = await this.users.repo.list({
      viewerId: admin.id,
      ...(query.q ? { q: query.q } : {}),
      role: query.role ?? 'user',
      includePrivate: true,
      after,
      limit,
    });
    return toPage(
      rows,
      limit,
      (row) => [row.name, row.id],
      (row) => ({ ...toUserProfile(row, admin), role: row.role, createdAt: row.createdAt, lastLoginAt: row.lastLoginAt }),
    );
  }

  async setRole(admin: Actor, userId: string, role: UserRole) {
    if (userId === admin.id) throw conflict('You cannot change your own role.', 'CANNOT_CHANGE_OWN_ROLE');
    if (!(await this.users.repo.exists(userId))) throw notFound('This rider could not be found.', 'USER_NOT_FOUND');
    await this.uow.run(async ({ db }) => {
      await this.users.repo.update(userId, { role }, db);
      await audit(db, { actorId: admin.id, action: 'user.setRole', targetType: 'user', targetId: userId, details: { role } });
    });
    return this.users.getProfile(userId, admin);
  }

  /** Removes a rider and everything they own. Admins must be demoted first. */
  async removeUser(admin: Actor, userId: string): Promise<void> {
    if (userId === admin.id) throw conflict('You cannot remove your own account here.', 'CANNOT_REMOVE_SELF');
    const target = await this.users.repo.findCredentials(userId);
    if (!target) throw notFound('This rider could not be found.', 'USER_NOT_FOUND');
    if (target.role === 'admin') throw forbidden('Demote this admin before removing them.', 'CANNOT_REMOVE_ADMIN');
    await audit(this.uow.prisma, { actorId: admin.id, action: 'user.remove', targetType: 'user', targetId: userId, details: { name: target.name } });
    await this.users.removeUser(userId);
  }

  async auditLog(query: { limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.auditPage(decodeTimeCursor(query.cursor), limit);
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
    if (!(await this.banners.findById(id))) throw notFound('This banner could not be found.', 'BANNER_NOT_FOUND');
    return toBannerDto(await this.banners.update(id, bannerData(input)));
  }

  async deleteBanner(id: string): Promise<void> {
    if (!(await this.banners.delete(id))) throw notFound('This banner could not be found.', 'BANNER_NOT_FOUND');
  }
}
