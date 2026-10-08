import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/geo.dart';

/// Where the rider is, and whether that came from the device or a fallback.
class UserLocation {
  final GeoPoint point;
  final String label;
  final bool isApproximate;

  const UserLocation({required this.point, required this.label, required this.isApproximate});
}

/// Device location with a graceful fallback: if location services are off or
/// permission is denied, Explore still works around central Kathmandu.
class LocationService {
  static const fallback = UserLocation(
    point: GeoPoint(27.7154, 85.3123),
    label: 'Kathmandu',
    isApproximate: true,
  );

  Future<UserLocation> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallback;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return fallback;
      }
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        // No fresh fix in time (indoors, weak GPS): the phone's last known
        // position is still far better than the city-centre fallback.
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return fallback;
      return UserLocation(
        point: GeoPoint(position.latitude, position.longitude),
        label: 'Your location',
        isApproximate: false,
      );
    } catch (_) {
      // Unsupported platform, timeout or plugin error: fall back quietly.
      return fallback;
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

/// The rider's current location, resolved once and refreshed on demand
/// (`ref.invalidate(currentLocationProvider)`).
final currentLocationProvider = FutureProvider<UserLocation>((ref) {
  return ref.watch(locationServiceProvider).current();
});
