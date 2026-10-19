import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';

import '../../network_providers.dart';

/// App-owned route and dependency wiring for the Settings Body & Weight editor.
///
/// The feature owns loading/error presentation; Progress owns Body domain and
/// persistence contracts. Keep one GoRouter authority in app/router.dart.
List<RouteBase> buildBodyWeightRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  return [
    GoRoute(
      path: AppRoutes.bodyWeightSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final bodyAsync = ref.watch(bodyStateDataProvider);
          final profileAsync = ref.watch(profileDataProvider);
          final weightUnit =
              profileAsync.valueOrNull?.unitPreferences.weightUnit ??
                  WeightUnit.kg;

          return BodyWeightSettingsDestination(
            bodyState: bodyAsync.valueOrNull,
            weightUnit: weightUnit,
            isLoading: bodyAsync.isLoading,
            hasError: bodyAsync.hasError,
            onRetry: () => ref.invalidate(bodyStateDataProvider),
            onRecordCurrentWeight: (weightKg) async {
              final repository = ref.read(bodyRepositoryProvider);
              await repository.recordCurrentWeight(
                BodyWeightRecord(
                  weightKg: weightKg,
                  measuredAt: DateTime.now(),
                  source: BodyWeightSources.bodyWeightSettings,
                ),
              );
              ref.invalidate(bodyStateDataProvider);
              ref.invalidate(profileDataProvider);
            },
            onSaveBodyGoal: (update) async {
              final repository = ref.read(bodyRepositoryProvider);
              await repository.setActiveBodyGoal(update);
              ref.invalidate(bodyStateDataProvider);
              ref.invalidate(profileDataProvider);
            },
          );
        },
      ),
    ),
  ];
}
