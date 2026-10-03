/** Great-circle helpers for "nearby" searches (no PostGIS needed). */

const EARTH_RADIUS_KM = 6371;
const KM_PER_DEGREE_LAT = 111.32;

const toRadians = (degrees: number) => (degrees * Math.PI) / 180;

/** Haversine distance in kilometres. */
export function distanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(a)));
}

/**
 * A lat/lng box that contains the circle; used to prefilter with the
 * (latitude, longitude) index before computing exact distances.
 */
export function boundingBox(lat: number, lng: number, radiusKm: number) {
  const dLat = radiusKm / KM_PER_DEGREE_LAT;
  const cosLat = Math.max(Math.cos(toRadians(lat)), 0.01);
  const dLng = Math.min(radiusKm / (KM_PER_DEGREE_LAT * cosLat), 180);
  return {
    minLat: Math.max(lat - dLat, -90),
    maxLat: Math.min(lat + dLat, 90),
    minLng: lng - dLng,
    maxLng: lng + dLng,
  };
}

/** Rounds to 0.1 km for display. */
export function roundKm(km: number): number {
  return Math.round(km * 10) / 10;
}
