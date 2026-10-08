/** A sent announcement, as recorded in the audit log (`GET /superadmin/announcements`). */
export interface Announcement {
  id: string;
  actorName: string | null;
  details: { title?: string; message?: string; recipients?: number };
  createdAt: string;
}

export interface AnnouncementInput {
  title: string;
  message: string;
}
