import type { FeedbackCategory, FeedbackStatus } from '../constants/enums.js';
import type { UnitOfWork } from '../db/prisma.js';
import type { FeedbackRecord, FeedbackRepository } from '../repositories/feedback.repository.js';
import { audit } from '../utils/audit.js';
import { notFound } from '../utils/errors.js';
import { decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';
import type { Actor } from './ride.service.js';

export function toFeedback(row: FeedbackRecord) {
  return {
    id: row.id,
    category: row.category,
    rating: row.rating,
    message: row.message,
    status: row.status,
    createdAt: row.createdAt,
  };
}

export function toAdminFeedback(row: FeedbackRecord) {
  return {
    ...toFeedback(row),
    platform: row.platform,
    appVersion: row.appVersion,
    adminNote: row.adminNote,
    resolvedAt: row.resolvedAt,
    updatedAt: row.updatedAt,
    user: row.user,
  };
}

/** Feedback riders send from the app, and its triage in the superadmin dashboard. */
export class FeedbackService {
  constructor(
    private readonly uow: UnitOfWork,
    private readonly repo: FeedbackRepository,
  ) {}

  async send(
    userId: string,
    input: { category?: FeedbackCategory; message: string; rating?: number; platform?: string; appVersion?: string },
  ) {
    const row = await this.repo.create({
      userId,
      category: input.category ?? 'other',
      message: input.message.trim(),
      rating: input.rating ?? null,
      platform: input.platform?.trim() || null,
      appVersion: input.appVersion?.trim() || null,
    });
    return toFeedback(row);
  }

  async list(query: { status?: FeedbackStatus; category?: FeedbackCategory; limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.page(
      { ...(query.status ? { status: query.status } : {}), ...(query.category ? { category: query.category } : {}) },
      decodeTimeCursor(query.cursor),
      limit,
    );
    return toPage(rows, limit, (row) => timeCursor(row.createdAt, row.id), toAdminFeedback);
  }

  async update(admin: Actor, id: string, input: { status?: FeedbackStatus; adminNote?: string }) {
    const existing = await this.repo.findById(id);
    if (!existing) throw notFound('This feedback could not be found.', 'FEEDBACK_NOT_FOUND');
    const resolvedAt =
      input.status === undefined || input.status === existing.status
        ? undefined
        : input.status === 'resolved'
          ? new Date()
          : null;
    return this.uow.run(async ({ db }) => {
      await audit(db, {
        actorId: admin.id,
        action: 'feedback.update',
        targetType: 'feedback',
        targetId: id,
        details: { ...(input.status ? { status: input.status } : {}), noteChanged: input.adminNote !== undefined },
      });
      const row = await this.repo.update(id, {
        ...(input.status !== undefined ? { status: input.status } : {}),
        ...(input.adminNote !== undefined ? { adminNote: input.adminNote.trim() } : {}),
        ...(resolvedAt !== undefined ? { resolvedAt } : {}),
      });
      return toAdminFeedback(row);
    });
  }
}
