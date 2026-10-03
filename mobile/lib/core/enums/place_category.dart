import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Kinds of places riders share in Explore. Values match the API's
/// `category` strings, so `PlaceCategory.values.byName(json['category'])` works.
enum PlaceCategory { viewpoint, waterfall, lake, river, trail, heritage, temple, cafe, food, campsite, village, cave, other }

extension PlaceCategoryX on PlaceCategory {
  String get label => switch (this) {
        PlaceCategory.viewpoint => 'Viewpoint',
        PlaceCategory.waterfall => 'Waterfall',
        PlaceCategory.lake => 'Lake',
        PlaceCategory.river => 'River',
        PlaceCategory.trail => 'Trail',
        PlaceCategory.heritage => 'Heritage',
        PlaceCategory.temple => 'Temple',
        PlaceCategory.cafe => 'Café',
        PlaceCategory.food => 'Local food',
        PlaceCategory.campsite => 'Campsite',
        PlaceCategory.village => 'Village',
        PlaceCategory.cave => 'Cave',
        PlaceCategory.other => 'Other',
      };

  IconData get icon => switch (this) {
        PlaceCategory.viewpoint => Icons.landscape_outlined,
        PlaceCategory.waterfall => Icons.water_outlined,
        PlaceCategory.lake => Icons.water,
        PlaceCategory.river => Icons.waves_outlined,
        PlaceCategory.trail => Icons.hiking,
        PlaceCategory.heritage => Icons.account_balance_outlined,
        PlaceCategory.temple => Icons.temple_buddhist_outlined,
        PlaceCategory.cafe => Icons.local_cafe_outlined,
        PlaceCategory.food => Icons.restaurant_outlined,
        PlaceCategory.campsite => Icons.cabin_outlined,
        PlaceCategory.village => Icons.holiday_village_outlined,
        PlaceCategory.cave => Icons.dark_mode_outlined,
        PlaceCategory.other => Icons.place_outlined,
      };

  Color get color => switch (this) {
        PlaceCategory.viewpoint || PlaceCategory.trail => AppColors.primary,
        PlaceCategory.waterfall || PlaceCategory.lake || PlaceCategory.river => AppColors.info,
        PlaceCategory.heritage || PlaceCategory.temple || PlaceCategory.village => AppColors.secondary,
        PlaceCategory.cafe || PlaceCategory.food => AppColors.warning,
        PlaceCategory.campsite || PlaceCategory.cave || PlaceCategory.other => AppColors.success,
      };
}
