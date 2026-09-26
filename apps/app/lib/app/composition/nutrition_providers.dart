import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

import 'runtime_providers.dart';

/// Canonical Nutrition Profile owner used by Product Onboarding completion.
final nutritionProfileRepositoryProvider =
    Provider<NutritionProfileRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseNutritionProfileRepository(client: supabaseClient);
  }
  return InMemoryNutritionProfileRepository();
});

/// Canonical Meal Categories owner for future Nutrition consumers.
final mealCategoriesRepositoryProvider =
    Provider<MealCategoriesRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseMealCategoriesRepository(client: supabaseClient);
  }
  return InMemoryMealCategoriesRepository();
});

/// Canonical Nutrition Profile read model for post-onboarding Settings.
///
/// A missing canonical row resolves to an all-null profile so first-time
/// editing works without a separate setup workflow.
final nutritionProfileDataProvider =
    FutureProvider<NutritionProfileData>((ref) async {
  final repository = ref.watch(nutritionProfileRepositoryProvider);
  return await repository.read() ?? const NutritionProfileData();
});

/// Canonical Nutrition Targets read model for post-onboarding Settings.
///
/// A missing canonical row resolves to an all-null target set so first-time
/// editing works without a separate setup workflow.
final nutritionTargetsDataProvider =
    FutureProvider<NutritionTargetsData>((ref) async {
  final repository = ref.watch(nutritionTargetsRepositoryProvider);
  return await repository.read() ?? const NutritionTargetsData();
});

/// Canonical Nutrition Targets owner used by Product Onboarding completion.
final nutritionTargetsRepositoryProvider =
    Provider<NutritionTargetsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseNutritionTargetsRepository(client: supabaseClient);
  }
  return InMemoryNutritionTargetsRepository();
});

/// Natural-language meal-text parsing capability (TNYX-225).
///
/// Unlike other Nutrition owners above, this capability has no safe
/// in-memory/offline fallback: parsing requires the protected
/// `nutrition-meal-text-parse` Edge Function, so it resolves to `null` when
/// no Supabase client is available rather than fabricating a fake parser.
/// TNYX-226 decides how/when the Add Food UI consumes this capability.
final mealTextParseRepositoryProvider =
    Provider<MealTextParseRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseMealTextParseRepository(client: supabaseClient);
  }
  return null;
});
