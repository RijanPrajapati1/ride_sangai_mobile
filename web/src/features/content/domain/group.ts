/** A rider group (`GET /superadmin/groups`). */
export interface Group {
  id: string;
  name: string;
  description: string;
  coverImageUrl: string | null;
  memberCount: number;
  organizerId: string;
  organizerName: string;
  lastMessageAt: string | null;
  createdAt: string;
}
