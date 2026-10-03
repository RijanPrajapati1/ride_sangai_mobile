import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/app/theme/app_theme.dart';
import 'package:ride_sangai/core/location/location_service.dart';
import 'package:ride_sangai/features/explore/presentation/screens/explore_screen.dart';
import 'package:ride_sangai/features/explore/presentation/screens/place_details_screen.dart';
import 'package:ride_sangai/features/explore/presentation/screens/saved_places_screen.dart';
import 'package:ride_sangai/features/explore/presentation/screens/share_place_screen.dart';

/// Renders the Explore screens with the in-memory data source and the
/// Kathmandu fallback location (no GPS in tests), checking they lay out
/// without errors in light and dark themes.
Widget _host(Widget child, {ThemeData? theme}) => ProviderScope(
      overrides: [
        currentLocationProvider.overrideWith((ref) async => LocationService.fallback),
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
    await tester.pumpWidget(_host(const ExploreScreen()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // The first 'Lake' is the filter chip (the card badge comes later in the tree).
    await tester.tap(find.text('Lake').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Taudaha Lake'), findsOneWidget);
    expect(find.text('Kakani Viewpoint'), findsNothing);
  });

  testWidgets('Place details shows rating summary, tips and reviews', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const PlaceDetailsScreen(placeId: 'pl_003')));
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

  testWidgets('Saved places lists the demo rider\'s saves', (tester) async {
    await tester.pumpWidget(_host(const SavedPlacesScreen()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Champadevi Viewpoint'), findsOneWidget);
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
