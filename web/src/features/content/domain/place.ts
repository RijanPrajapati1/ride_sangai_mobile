/** A shared place (`GET /superadmin/places`). */
export interface Place {
  id: string;
  name: string;
  description: string;
  category: string;
  locationName: string;
  coverImageUrl: string | null;
  activities: string[];
  averageRating: number | null;
  reviewCount: number;
  saveCount: number;
  authorId: string;
  authorName: string;
  authorAvatarUrl: string;
  createdAt: string;
}
