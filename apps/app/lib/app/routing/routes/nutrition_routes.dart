import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

import '../../composition/nutrition_providers.dart';
import '../../network_providers.dart' show profileDataProvider;

typedef NutritionLoadFailureBuilder = Widget Function({
  required String title,
  required VoidCallback onRetry,
});

List<RouteBase> buildNutritionRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required NutritionLoadFailureBuilder loadFailureBuilder,
}) {
  return [
    GoRoute(
      path: AppRoutes.nutritionSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => NutritionSettingsPage(
        onNutritionProfilePressed: () =>
            context.push(AppRoutes.nutritionProfileSettings.path),
        onNutritionTargetsPressed: () =>
            context.push(AppRoutes.nutritionTargetsSettings.path),
        onMealDiarySettingsPressed: () =>
            context.push(AppRoutes.mealDiarySettings.path),
      ),
    ),
    GoRoute(
      path: AppRoutes.nutritionProfileSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final profileAsync = ref.watch(nutritionProfileDataProvider);

          if (profileAsync.isLoading && !profileAsync.hasValue) {
            return const Scaffold(
              body: SafeArea(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (profileAsync.hasError && !profileAsync.hasValue) {
            return loadFailureBuilder(
              title: 'Could not load Nutrition Profile',
              onRetry: () => ref.invalidate(nutritionProfileDataProvider),
            );
          }

          return NutritionProfileSettingsPage(
            profile: profileAsync.valueOrNull ?? const NutritionProfileData(),
            onSave: (profile) async {
              final repository = ref.read(nutritionProfileRepositoryProvider);
              await repository.upsert(profile);
              ref.invalidate(nutritionProfileDataProvider);
            },
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.nutritionTargetsSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final targetsAsync = ref.watch(nutritionTargetsDataProvider);

          if (targetsAsync.isLoading && !targetsAsync.hasValue) {
            return const Scaffold(
              body: SafeArea(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (targetsAsync.hasError && !targetsAsync.hasValue) {
            return loadFailureBuilder(
              title: 'Could not load Nutrition Targets',
              onRetry: () => ref.invalidate(nutritionTargetsDataProvider),
            );
          }

          return NutritionTargetsSettingsPage(
            targets: targetsAsync.valueOrNull ?? const NutritionTargetsData(),
            onEditMacros: () =>
                context.push(AppRoutes.nutritionMacrosSettings.path),
            onEditAdditionalGoals: () =>
                context.push(AppRoutes.nutritionAdditionalGoalsSettings.path),
            onSave: (targets) async {
              final repository = ref.read(nutritionTargetsRepositoryProvider);
              await repository.upsert(targets);
              ref.invalidate(nutritionTargetsDataProvider);
            },
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.nutritionMacrosSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final targetsAsync = ref.watch(nutritionTargetsDataProvider);

          if (targetsAsync.isLoading && !targetsAsync.hasValue) {
            return const Scaffold(
              body: SafeArea(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (targetsAsync.hasError && !targetsAsync.hasValue) {
            return loadFailureBuilder(
              title: 'Could not load Macronutrients',
              onRetry: () => ref.invalidate(nutritionTargetsDataProvider),
            );
          }

          return NutritionMacrosSettingsPage(
            targets: targetsAsync.valueOrNull ?? const NutritionTargetsData(),
            onSave: (targets) async {
              final repository = ref.read(nutritionTargetsRepositoryProvider);
              await repository.upsert(targets);
              ref.invalidate(nutritionTargetsDataProvider);
            },
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.nutritionAdditionalGoalsSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final targetsAsync = ref.watch(nutritionTargetsDataProvider);

          if (targetsAsync.isLoading && !targetsAsync.hasValue) {
            return const Scaffold(
              body: SafeArea(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (targetsAsync.hasError && !targetsAsync.hasValue) {
            return loadFailureBuilder(
              title: 'Could not load Additional Nutrition',
              onRetry: () => ref.invalidate(nutritionTargetsDataProvider),
            );
          }

          final targets =
              targetsAsync.valueOrNull ?? const NutritionTargetsData();

          // Date of birth is read, never stored. It is required by Sodium,
          // Calcium, Phosphorus and Vitamin D, while Saturated Fat, Trans
          // Fat and Added Sugar can still derive from Calories alone. A
          // profile load failure is not interchangeable with a successfully
          // loaded profile that has no date of birth: valueOrNull alone
          // would misrepresent a transient network error as eligibility.
          final profileAsync = ref.watch(profileDataProvider);

          if (profileAsync.isLoading && !profileAsync.hasValue) {
            return const Scaffold(
              body: SafeArea(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (profileAsync.hasError && !profileAsync.hasValue) {
            return loadFailureBuilder(
              title: 'Could not load your profile',
              onRetry: () => ref.invalidate(profileDataProvider),
            );
          }

          final profile = profileAsync.valueOrNull;

          // Read-only surface: no save callback, because nothing on this
          // screen writes.
          return AdditionalNutrientGoalsPage(
            caloriesKcal: targets.caloriesKcal,
            dateOfBirth: profile?.dateOfBirth,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.mealDiarySettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => MealDiarySettingsPage(
        onMealCategoriesPressed: () =>
            context.push(AppRoutes.mealCategoriesSettings.path),
      ),
    ),
    GoRoute(
      path: AppRoutes.archivedMealCategoriesSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) => ArchivedMealCategoriesPage(
          repository: ref.watch(mealCategoriesRepositoryProvider),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.mealCategoriesSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      // Composition supplies the repository and the page owns its
      // controller's lifecycle; the feature never reaches for Supabase.
      builder: (context, state) => Consumer(
        builder: (context, ref, _) => MealCategoriesDestinationPage(
          repository: ref.watch(mealCategoriesRepositoryProvider),
          onArchivedPressed: () => context.push(
            AppRoutes.archivedMealCategoriesSettings.path,
          ),
        ),
      ),
    ),
  ];
}
