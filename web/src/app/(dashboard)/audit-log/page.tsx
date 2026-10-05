import type { Metadata } from 'next';
import { AuditLogScreen } from '@/features/audit-log';

export const metadata: Metadata = { title: 'Audit log' };

export default function Page() {
  return <AuditLogScreen />;
}
