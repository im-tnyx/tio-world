import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/profile/profile_completion.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('P1 presentation Supabase boundary', () {
    test('router and profile completion keep direct Supabase access out', () {
      final routerSource = File('lib/app/router.dart').readAsStringSync();
      final completionSource =
          File('lib/app/profile/profile_completion.dart').readAsStringSync();

      expect(routerSource, isNot(contains('supabaseClientProvider')));
      expect(routerSource, isNot(contains('.auth.currentUser')));
      expect(routerSource, contains('currentSessionState'));

      expect(completionSource, isNot(contains('supabaseClientProvider')));
      expect(completionSource, isNot(contains('.auth.currentUser')));
      expect(completionSource, isNot(contains(".from('users')")));
      expect(completionSource, isNot(contains('SupabaseUserProfileRepository')));
    });

    test('profile completion composes canonical Profile and AuthSession data',
        () async {
      final profile = ProfileSetupData(
        name: 'Ada Lovelace',
        username: 'ada',
        gender: ProfileGender.values.first,
        goals: <ProfileGoal>{},
        dateOfBirth: DateTime(1990, 1, 1),
        heightCm: 165,
        currentWeightKg: 60,
        activityLevel: ProfileActivityLevel.values.first,
        healthConditions: <ProfileHealthCondition>{},
        mobile: '+919876543210',
      );
      const session = AuthSession(
        userId: 'user-1',
        email: 'ada@example.com',
        phone: '+919876543210',
        loginCycleId: 'login-cycle-1',
      );

      final container = ProviderContainer(
        overrides: [
          profileDataProvider.overrideWith((ref) => Stream.value(profile)),
          authSessionStateProvider.overrideWith(
            (ref) => Stream.value(const AuthSessionAuthenticated(session)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileDataProvider.future);
      await container.read(authSessionStateProvider.future);
      container.invalidate(profileCompletionSummaryProvider);

      final summary = await container.read(profileCompletionSummaryProvider.future);
      expect(summary, isNotNull);
      expect(summary!.completedFields, contains(ProfileCompletionField.name));
      expect(summary.completedFields, contains(ProfileCompletionField.username));
      expect(summary.completedFields, contains(ProfileCompletionField.email));
      expect(summary.completedFields, contains(ProfileCompletionField.mobile));
      expect(summary.isComplete, isTrue);
    });

    test('reminder scope uses provider-neutral login-cycle identity', () async {
      const session = AuthSession(
        userId: 'user-2',
        loginCycleId: 'login-cycle-2',
      );
      final container = ProviderContainer(
        overrides: [
          authSessionStateProvider.overrideWith(
            (ref) => Stream.value(const AuthSessionAuthenticated(session)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionStateProvider.future);
      final scope = container.read(profileCompletionReminderScopeProvider);

      expect(scope, isNotNull);
      expect(scope!.userId, 'user-2');
      expect(scope.loginCycleId, 'login-cycle-2');
      expect(scope.storageValue, 'user-2|login-cycle-2');
    });
  });
}
