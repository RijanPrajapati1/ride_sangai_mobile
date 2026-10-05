export const FEEDBACK_STATUSES = ['open', 'inProgress', 'resolved'] as const;
export type FeedbackStatus = (typeof FEEDBACK_STATUSES)[number];

export const FEEDBACK_CATEGORIES = ['bug', 'idea', 'praise', 'other'] as const;
export type FeedbackCategory = (typeof FEEDBACK_CATEGORIES)[number];

export const STATUS_LABELS: Record<FeedbackStatus, string> = {
  open: 'Open',
  inProgress: 'In progress',
  resolved: 'Resolved',
};

export const CATEGORY_LABELS: Record<FeedbackCategory, string> = {
  bug: 'Bug',
  idea: 'Idea',
  praise: 'Praise',
  other: 'Other',
};

/** Feedback as the superadmin sees it (`GET /superadmin/feedback`). */
export interface FeedbackItem {
  id: string;
  category: FeedbackCategory;
  rating: number | null;
  message: string;
  status: FeedbackStatus;
  createdAt: string;
  platform: string | null;
  appVersion: string | null;
  adminNote: string;
  resolvedAt: string | null;
  updatedAt: string;
  user: { id: string; name: string; email: string; avatarUrl: string } | null;
}

export interface FeedbackFilters {
  status: FeedbackStatus;
  category: FeedbackCategory | 'all';
}

export interface FeedbackUpdate {
  status?: FeedbackStatus;
  adminNote?: string;
}
