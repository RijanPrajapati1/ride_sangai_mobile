import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yatrix/app/providers/app_providers.dart';
import 'package:yatrix/core/errors/app_exception.dart';
import 'package:yatrix/features/authentication/domain/entities/auth_user.dart';
import 'package:yatrix/features/authentication/domain/repositories/auth_repository.dart';
import 'package:yatrix/features/authentication/presentation/providers/auth_providers.dart';
import 'package:yatrix/features/profile/domain/entities/user_preferences.dart';
import 'package:yatrix/features/profile/domain/repositories/user_repository.dart';
import 'package:yatrix/features/profile/presentation/providers/profile_providers.dart';
import 'package:yatrix/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignedOutAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> getCurrentSession() async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Serves preferences; every change is rejected like the server would.
class FakeUserRepository implements UserRepository {
  final patches = <Map<String, bool?>>[];

  @override
  Future<UserPreferences> getPreferences() async => const UserPreferences();

  @override
  Future<UserPreferences> patchPreferences({
    bool? pushRideReminders,
    bool? pushMessages,
    bool? pushCommunityActivity,
    bool? darkModeEnabled,
    bool? publicProfile,
    bool? showRidingStats,
  }) async {
    patches.add({'pushMessages': pushMessages});
    throw const ValidationException('Preferences could not be saved.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('a failed toggle shows the server message', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final users = FakeUserRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(SignedOutAuthRepository()),
        userRepositoryProvider.overrideWithValue(users),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Messages'));
    await tester.pumpAndSettle();

    expect(users.patches, [
      {'pushMessages': false},
    ]);
    expect(find.text('Preferences could not be saved.'), findsOneWidget);
  });
}
