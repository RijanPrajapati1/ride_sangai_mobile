import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/place.dart';

LatLng toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);

/// OpenStreetMap view (no API key needed) with place pins and the rider's position.
class PlaceMap extends StatelessWidget {
  final List<Place> places;
  final GeoPoint center;
  final double zoom;
  final GeoPoint? userLocation;

  /// Extra pin, e.g. the spot being chosen when sharing a place.
  final GeoPoint? pickedPoint;
  final bool interactive;
  final ValueChanged<Place>? onPlaceTap;
  final ValueChanged<GeoPoint>? onMapTap;
  final MapController? controller;

  const PlaceMap({
    super.key,
    this.places = const [],
    required this.center,
    this.zoom = 11,
    this.userLocation,
    this.pickedPoint,
    this.interactive = true,
    this.onPlaceTap,
    this.onMapTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: toLatLng(center),
        initialZoom: zoom,
        minZoom: 4,
        maxZoom: 18,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
        onTap: onMapTap == null ? null : (_, latLng) => onMapTap!(GeoPoint(latLng.latitude, latLng.longitude)),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'yatrix.mobile.com',
        ),
        MarkerLayer(
          markers: [
            if (userLocation != null)
              Marker(
                point: toLatLng(userLocation!),
                width: _UserDot.size,
                height: _UserDot.size,
                child: const _UserDot(),
              ),
            for (final place in places)
              Marker(
                point: toLatLng(place.point),
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onPlaceTap == null ? null : () => onPlaceTap!(place),
                  child: _Pin(color: place.category.color, icon: place.category.icon),
                ),
              ),
            if (pickedPoint != null)
              Marker(
                point: toLatLng(pickedPoint!),
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const _Pin(color: AppColors.mapPin),
              ),
          ],
        ),
        // Required OpenStreetMap credit; collapses to an info button so it fits small previews.
        if (interactive)
          const RichAttributionWidget(
            showFlutterMapAttribution: false,
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          )
        else
          const Align(
            alignment: Alignment.bottomRight,
            child: ColoredBox(
              color: Color(0xB3FFFFFF),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text('© OpenStreetMap', style: TextStyle(fontSize: 9, color: Colors.black87)),
              ),
            ),
          ),
      ],
    );
  }
}

/// The rider's position, Google Maps style: a blue dot with a white ring
/// inside a soft blue halo.
class _UserDot extends StatelessWidget {
  static const double size = 56;

  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mapUserDot.withValues(alpha: 0.16),
            border: Border.all(color: AppColors.mapUserDot.withValues(alpha: 0.3)),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.mapUserDot,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}

/// A map pin. With an [icon] it marks a place of that category; without one
/// it is a plain dropped pin (dark dot in the head), like Google Maps.
class _Pin extends StatelessWidget {
  final Color color;
  final IconData? icon;

  const _Pin({required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(
          Icons.location_on,
          size: 40,
          color: color,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        ),
        Positioned(
          top: icon == null ? 10 : 6,
          child: icon == null
              ? Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Color.lerp(color, Colors.black, 0.45),
                    shape: BoxShape.circle,
                  ),
                )
              : Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(icon, size: 12, color: color),
                ),
        ),
      ],
    );
  }
}

/// Rounded, non-interactive map preview with a single pin.
class PlaceMapPreview extends StatelessWidget {
  final Place place;
  final GeoPoint? userLocation;
  final VoidCallback? onTap;

  const PlaceMapPreview({super.key, required this.place, this.userLocation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: SizedBox(
        height: 170,
        child: Stack(
          children: [
            PlaceMap(places: [place], center: place.point, zoom: 13, interactive: false, userLocation: userLocation),
            if (onTap != null) Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: onTap))),
          ],
        ),
      ),
    );
  }
}
