/** Platform totals from `GET /superadmin/stats`. */
export interface PlatformStats {
  riders: number;
  superadmins: number;
  rides: number;
  upcomingRides: number;
  pendingRequests: number;
  posts: number;
  comments: number;
  groups: number;
  places: number;
  newRidersLast7Days: number;
  /** Accounts a superadmin has disabled. */
  disabledUsers: number;
}
