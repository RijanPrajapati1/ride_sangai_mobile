export const REQUEST_STATUSES = ['pending', 'approved', 'declined'] as const;
export type RideRequestStatus = (typeof REQUEST_STATUSES)[number];

/** A request to join a ride (`GET /superadmin/ride-requests`). */
export interface RideRequest {
  id: string;
  rideId: string;
  rideTitle: string;
  rideDate: string;
  userId: string;
  userName: string;
  userAvatarUrl: string;
  userBio: string;
  message: string | null;
  experienceLevel: string;
  requestedAt: string;
  status: RideRequestStatus;
  declineReason: string | null;
  decidedAt: string | null;
}
