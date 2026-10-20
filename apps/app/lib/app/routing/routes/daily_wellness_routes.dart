import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_settings/settings.dart';

import '../../network_providers.dart';

/// App-owned route registration and provider composition for Daily Wellness.
///
/// Settings owns the route presentation; Progress retains canonical Wellness
/// persistence. Hydration preference identity/lifetime stays Settings-owned.
List<RouteBase> buildDailyWellnessRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  return [
    GoRoute(
      path: AppRoutes.dailyWellnessSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final wellnessAsync = ref.watch(wellnessTargetsDataProvider);
          final hydrationAsync = ref.watch(hydrationPreferencesDataProvider);
          final hydrationRepository =
              ref.watch(hydrationPreferencesRepositoryProvider);
          final hydrationSession =
              ref.watch(authSessionStateProvider).valueOrNull;
          final hydrationUserId = hydrationSession is AuthSessionAuthenticated
              ? hydrationSession.session.userId
              : null;
          final profileAsync = ref.watch(profileDataProvider);
          final volumeUnit =
              profileAsync.valueOrNull?.unitPreferences.volumeUnit ??
                  VolumeUnit.ml;

          return DailyWellnessSettingsDestination(
            hydrationUserId: hydrationUserId,
            initialTargets: wellnessAsync.valueOrNull,
            volumeUnit: volumeUnit,
            hydrationPreferences: hydrationAsync.valueOrNull,
            wellnessLoading: wellnessAsync.isLoading,
            wellnessLoadFailed: wellnessAsync.hasError,
            hydrationLoading: hydrationAsync.isLoading,
            hydrationLoadFailed: hydrationAsync.hasError,
            onRetryWellness: () => ref.invalidate(wellnessTargetsDataProvider),
            onRetryHydration: () =>
                ref.invalidate(hydrationPreferencesDataProvider),
            onSaveHydration: (preferences) async {
              await hydrationRepository.write(preferences);
              ref.invalidate(hydrationPreferencesDataProvider);
            },
            onSave: (targets) async {
              final repository = ref.read(wellnessTargetsRepositoryProvider);
              await repository.upsert(targets);
              ref.invalidate(wellnessTargetsDataProvider);
            },
          );
        },
      ),
    ),
  ];
}
