/** A moderation action (`GET /superadmin/audit-log`). */
export interface AuditEntry {
  id: string;
  actorId: string | null;
  actorName: string | null;
  action: string;
  targetType: string;
  targetId: string | null;
  details: unknown;
  createdAt: string;
}
