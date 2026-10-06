import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/app/theme/app_theme.dart';
import 'package:ride_sangai/core/location/location_service.dart';
import 'package:ride_sangai/features/explore/presentation/providers/explore_providers.dart';
import 'package:ride_sangai/features/explore/presentation/screens/explore_screen.dart';
import 'package:ride_sangai/features/explore/presentation/screens/place_details_screen.dart';
import 'package:ride_sangai/features/explore/presentation/screens/saved_places_screen.dart';
import 'package:ride_sangai/features/explore/presentation/screens/share_place_screen.dart';

import 'explore_fakes.dart';

/// Renders the Explore screens with a fake repository (API-shaped places) and
/// the Kathmandu fallback location (no GPS in tests), checking they lay out
/// without errors in light and dark themes.
Widget _host(Widget child, {ThemeData? theme, FakePlaceRepository? repository}) => ProviderScope(
      overrides: [
        currentLocationProvider.overrideWith((ref) async => LocationService.fallback),
        placeRepositoryProvider.overrideWithValue(repository ?? FakePlaceRepository.seeded()),
      ],
      child: MaterialApp(theme: theme ?? AppTheme.light, home: child),
    );

void main() {
  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    testWidgets('Explore list shows nearby places (${entry.key})', (tester) async {
      await tester.pumpWidget(_host(const ExploreScreen(), theme: entry.value));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Taudaha Lake'), findsOneWidget);
      expect(find.textContaining('Showing places around Kathmandu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Category filter narrows the list', (tester) async {
    final repository = FakePlaceRepository.seeded();
    await tester.pumpWidget(_host(const ExploreScreen(), repository: repository));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Kakani Viewpoint'), findsOneWidget);
    // The first 'Lake' is the filter chip (the card badge comes later in the tree).
    await tester.tap(find.text('Lake').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Taudaha Lake'), findsOneWidget);
    expect(find.text('Kakani Viewpoint'), findsNothing);
    // The filter reaches the repository (and from there the API's `category`).
    expect(repository.queries.last.category?.name, 'lake');
    expect(repository.queries.last.from, LocationService.fallback.point);
  });

  testWidgets('Place details shows rating summary, tips and reviews', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const PlaceDetailsScreen(placeId: 'p3')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Sundarijal Waterfall'), findsOneWidget);
    expect(find.text('3.0'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('Local tip:'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Not worth it'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Not worth it'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Place details shows the API error message', (tester) async {
    await tester.pumpWidget(_host(const PlaceDetailsScreen(placeId: 'missing')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('This place no longer exists.'), findsOneWidget);
  });

  testWidgets('Saved places lists the rider\'s saves', (tester) async {
    await tester.pumpWidget(_host(const SavedPlacesScreen()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Sundarijal Waterfall'), findsOneWidget);
    expect(find.text('Kakani Viewpoint'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Share a place validates the form and the map pin', (tester) async {
    // Tall viewport so the whole form is built without scrolling over the map.
    tester.view.physicalSize = const Size(1080, 5600);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const SharePlaceScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Tap the map to drop a pin'), findsOneWidget);
    await tester.tap(find.text('Share place'));
    await tester.pump();
    expect(find.text('Tap the map (or use your location) to pin the place'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
