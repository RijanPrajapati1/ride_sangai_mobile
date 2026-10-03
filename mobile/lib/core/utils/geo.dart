import 'dart:math' as math;

/// A latitude/longitude pair.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) => other is GeoPoint && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Great-circle (haversine) distance in kilometres.
double distanceKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
}

/// "850 m", "4.2 km", "38 km".
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}
