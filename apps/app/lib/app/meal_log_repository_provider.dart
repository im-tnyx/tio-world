import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

import 'network_providers.dart';

/// Canonical MealLog persistence owner selected at the app composition root.
///
/// Supabase-backed sessions get durable history. Non-Supabase local/test
/// harnesses get an explicitly non-durable in-memory owner.
final mealLogRepositoryProvider = Provider<MealLogRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final mealCategoriesRepository = ref.watch(mealCategoriesRepositoryProvider);
  if (supabaseClient != null) {
    return SupabaseMealLogRepository(
      client: supabaseClient,
      mealCategoriesRepository: mealCategoriesRepository,
    );
  }
  return InMemoryMealLogRepository(
    mealCategoriesRepository: mealCategoriesRepository,
  );
});
