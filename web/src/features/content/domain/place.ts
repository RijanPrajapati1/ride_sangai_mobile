/** A shared place (`GET /superadmin/places`). */
export interface Place {
  id: string;
  name: string;
  description: string;
  category: string;
  locationName: string;
  coverImageUrl: string | null;
  activities: string[];
  bestTime?: string | null;
  tips?: string | null;
  entryFee?: string | null;
  averageRating: number | null;
  reviewCount: number;
  saveCount: number;
  authorId: string;
  authorName: string;
  authorAvatarUrl: string;
  createdAt: string;
}

export const PLACE_CATEGORIES = [
  'viewpoint',
  'waterfall',
  'lake',
  'river',
  'trail',
  'heritage',
  'temple',
  'cafe',
  'food',
  'campsite',
  'village',
  'cave',
  'other',
] as const;
