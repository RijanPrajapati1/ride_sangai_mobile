'use client';

import { useCursorList } from '@/core/query/use-cursor-list';
import { auditLogRepository } from '../data/audit-log.repository';

export function useAuditLog() {
  return useCursorList(['audit-log'], auditLogRepository.list);
}
