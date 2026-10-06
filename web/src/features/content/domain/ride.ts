export type ActivityCategory = 'cycling' | 'trekking' | 'hiking' | 'riding';
export type RideDifficulty = 'easy' | 'moderate' | 'hard';
export type RideWhen = 'all' | 'upcoming' | 'past';

/** A group ride (`GET /superadmin/rides`). */
export interface Ride {
  id: string;
  title: string;
  description: string;
  date: string;
  meetingPoint: string;
  rideType: string;
  category: ActivityCategory;
  difficulty: RideDifficulty;
  distanceKm: number;
  durationMinutes: number;
  organizerId: string;
  organizerName: string;
  organizerAvatarUrl: string;
  imageUrl: string;
  participantCount: number;
  maxParticipants: number;
  isFull: boolean;
  createdAt: string;
}
