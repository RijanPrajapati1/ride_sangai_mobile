interface MiniUser {
  id: string;
  name: string;
  email: string;
  avatarUrl: string;
}

/** A comment on any post (`GET /superadmin/comments`). */
export interface AdminComment {
  id: string;
  text: string;
  likeCount: number;
  createdAt: string;
  author: MiniUser;
  post: { id: string; text: string };
}

/** A review of any place (`GET /superadmin/reviews`). */
export interface AdminReview {
  id: string;
  rating: number;
  worthIt: boolean;
  text: string;
  photos: string[];
  createdAt: string;
  author: MiniUser;
  place: { id: string; name: string };
}
