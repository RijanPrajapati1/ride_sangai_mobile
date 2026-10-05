import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/app/app.dart';
import 'package:ride_sangai/app/providers/app_providers.dart';
import 'package:ride_sangai/core/constants/app_constants.dart';
import 'package:ride_sangai/core/errors/app_exception.dart';
import 'package:ride_sangai/features/authentication/domain/entities/auth_user.dart';
import 'package:ride_sangai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:ride_sangai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signed out, and every login attempt is rejected like the server would.
class RejectingAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> getCurrentSession() async => null;

  @override
  Future<AuthUser> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    throw const AuthException('Invalid email or password.', 'INVALID_CREDENTIALS');
  }

  @override
  Future<AuthUser> register({required String name, required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('a failed login keeps what the user typed', (tester) async {
    SharedPreferences.setMockInitialValues({AppConstants.onboardingCompleteKey: true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(RejectingAuthRepository()),
      ],
      child: const BikerSyncApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Log In'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'rider@example.com');
    await tester.enterText(fields.at(1), 'wrong-password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.text('rider@example.com'), findsOneWidget);
    expect(find.text('wrong-password'), findsOneWidget);
  });
}
