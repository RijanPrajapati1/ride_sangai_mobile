import type { FastifyInstance } from 'fastify';

function startsIn(startsAt: Date): string {
  const minutes = Math.max(1, Math.round((startsAt.getTime() - Date.now()) / 60_000));
  if (minutes < 90) return `${minutes} minute${minutes === 1 ? '' : 's'}`;
  const hours = Math.round(minutes / 60);
  return `${hours} hour${hours === 1 ? '' : 's'}`;
}

/**
 * Sends one "starting soon" reminder per ride to the organizer and approved
 * riders. Rides are claimed atomically (UPDATE … FOR UPDATE SKIP LOCKED), so
 * running on several instances never double-sends.
 */
export async function sendRideReminders(app: FastifyInstance, leadMinutes: number): Promise<number> {
  const { uow, ride, notification } = app.services;
  return uow.run(async (ctx) => {
    const due = await ride.repo.claimDueReminders(ctx.db, leadMinutes);
    for (const r of due) {
      const riders = await ride.repo.approvedRiderIds(r.id, ctx.db);
      const recipients = [r.organizer_id, ...riders.map((row) => row.userId)];
      await notification.notifyMany(
        ctx,
        recipients.map((recipientId) => ({
          recipientId,
          type: 'rideReminder' as const,
          title: 'Ride starting soon',
          body: `${r.title} starts in ${startsIn(r.starts_at)}. Don't forget your helmet!`,
          entityType: 'ride' as const,
          entityId: r.id,
        })),
      );
    }
    return due.length;
  });
}
