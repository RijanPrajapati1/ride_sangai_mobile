import type { ActivityCategory, ExperienceLevel, RideDifficulty, RideType } from './enums.js';

/** Display labels, mirroring the Dart enum extensions, served by GET /meta. */
export const CATEGORY_LABELS: Record<ActivityCategory, { label: string; activityNoun: string; activitySingular: string; tagline: string }> = {
  cycling: { label: 'Cycling', activityNoun: 'Rides', activitySingular: 'Ride', tagline: 'Discover and join group bike rides near you.' },
  trekking: { label: 'Trekking', activityNoun: 'Treks', activitySingular: 'Trek', tagline: 'Multi-day trekking adventures with a local crew.' },
  hiking: { label: 'Hiking', activityNoun: 'Hikes', activitySingular: 'Hike', tagline: 'Day hikes and trail meetups in your area.' },
  riding: { label: 'Riding', activityNoun: 'Rides', activitySingular: 'Ride', tagline: 'Motorbike meetups and group rides.' },
};

export const RIDE_TYPE_LABELS: Record<RideType, string> = {
  road: 'Road',
  mountain: 'Mountain',
  gravel: 'Gravel',
  touring: 'Touring',
  social: 'Social',
  hillClimb: 'Hill Climb',
  nightRide: 'Night Ride',
  multiDayTrek: 'Multi-day Trek',
  dayTrek: 'Day Trek',
  summitTrek: 'Summit Trek',
  dayHike: 'Day Hike',
  natureWalk: 'Nature Walk',
  familyHike: 'Family Hike',
  touringRide: 'Touring',
  offRoadRide: 'Off-road',
  trackDay: 'Track Day',
};

export const DIFFICULTY_LABELS: Record<RideDifficulty, string> = { easy: 'Easy', moderate: 'Moderate', hard: 'Hard' };

export const EXPERIENCE_LABELS: Record<ExperienceLevel, string> = {
  beginner: 'Beginner',
  intermediate: 'Intermediate',
  advanced: 'Advanced',
  pro: 'Pro',
};
