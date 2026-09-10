import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ride_sangai/app/app.dart';
import 'package:ride_sangai/app/providers/app_providers.dart';
import 'package:ride_sangai/core/constants/app_constants.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const BikerSyncApp(),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);

    // Flush the in-flight dummy auth/onboarding lookups (simulated network
    // delay) so no timers are left pending when the test tears down.
    await tester.pump(const Duration(seconds: 1));
  });
}
