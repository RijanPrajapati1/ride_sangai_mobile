import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/geo.dart';

/// Turns a map point into a short human area name ("Kirtipur, Kathmandu")
/// using OpenStreetMap's Nominatim (no API key needed).
class ReverseGeocoder {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'User-Agent': 'yatrix.mobile.com'},
    ),
  );

  /// Returns null when nothing sensible could be resolved (offline, ocean…).
  Future<String?> areaName(GeoPoint point) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': point.latitude,
          'lon': point.longitude,
          'zoom': 14,
          'addressdetails': 1,
        },
      );
      final data = response.data;
      if (data == null) return null;
      final address = (data['address'] as Map?)?.cast<String, dynamic>() ?? const {};
      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      final local = pick(['neighbourhood', 'suburb', 'village', 'hamlet', 'quarter', 'town', 'municipality']);
      final city = pick(['city', 'city_district', 'county', 'state_district', 'state']);
      final parts = <String>[
        ?local,
        if (city != null && city != local) city,
      ];
      if (parts.isNotEmpty) return parts.join(', ');
      final display = data['display_name'];
      if (display is String && display.isNotEmpty) return display.split(',').take(2).map((s) => s.trim()).join(', ');
      return null;
    } catch (_) {
      return null;
    }
  }
}

final reverseGeocoderProvider = Provider<ReverseGeocoder>((ref) => ReverseGeocoder());
