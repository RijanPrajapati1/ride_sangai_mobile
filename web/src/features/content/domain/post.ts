/** A community post (`GET /superadmin/posts`). */
export interface Post {
  id: string;
  userId: string;
  userName: string;
  userAvatarUrl: string;
  time: string;
  text: string;
  imageUrl: string | null;
  likeCount: number;
  commentCount: number;
}
