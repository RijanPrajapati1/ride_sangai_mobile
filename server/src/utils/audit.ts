import type { Db } from '../db/prisma.js';

/** Records a moderation action (who did what to which item) in the admin audit log. */
export async function audit(
  db: Db,
  entry: { actorId: string; action: string; targetType: string; targetId?: string | null; details?: Record<string, string | number | boolean | null> },
): Promise<void> {
  await db.adminAuditLog.create({
    data: {
      actorId: entry.actorId,
      action: entry.action,
      targetType: entry.targetType,
      targetId: entry.targetId ?? null,
      details: entry.details ?? {},
    },
    select: { id: true },
  });
}
