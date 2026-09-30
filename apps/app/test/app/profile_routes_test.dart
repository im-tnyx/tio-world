import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/profile/profile_completion.dart';
import 'package:tio_app/app/routing/routes/profile_routes.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  testWidgets(
      'Profile route opens Profile Avatar and preserves profile composition',
      (tester) async {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.profile.path,
      routes: buildProfileRoutes(rootNavigatorKey: rootNavigatorKey),
    );
    addTearDown(router.dispose);

    final profile = ProfileSetupData(
      name: 'Rahul Sharma',
      username: 'rahul_fit',
      plan: 'plus',
      gender: ProfileGender.male,
      goals: const {ProfileGoal.buildMuscle},
      dateOfBirth: DateTime(2000, 1, 1),
      heightCm: 180,
      currentWeightKg: 75,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.none},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileDataProvider.overrideWith(
            (ref) => Stream<ProfileSetupData?>.value(profile),
          ),
          profileCompletionSummaryProvider.overrideWith(
            (ref) async => null,
          ),
          profileCompletionReminderScopeProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.byKey(const ValueKey('tio-avatar-plus-ring')), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.profile.path,
    );

    await tester.tap(find.byKey(const ValueKey('profile-avatar-entry')));
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPreviewPage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.profileAvatar.path,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.profile.path,
    );
  });
}
