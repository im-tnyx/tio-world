import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

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
  ];
}
