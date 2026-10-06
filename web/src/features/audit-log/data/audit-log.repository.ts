import { apiRequest } from '@/core/http/api-client';
import type { Page } from '@/core/http/page';
import type { AuditEntry } from '../domain/audit-entry';

export const auditLogRepository = {
  list: (cursor: string | null) =>
    apiRequest<Page<AuditEntry>>('superadmin/audit-log', { query: { cursor, limit: 30 } }),
};
