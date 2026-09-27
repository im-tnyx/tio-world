import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

import '../../composition/nutrition_providers.dart';

List<RouteBase> buildNutritionRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
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
