import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_app/app/meal_log_repository_provider.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  test('no Supabase client selects non-durable MealLog fallback', () {
    final container = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(mealLogRepositoryProvider),
      isA<InMemoryMealLogRepository>(),
    );
  });

  test('Supabase client selects canonical MealLog adapter', () {
    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(mealLogRepositoryProvider),
      isA<SupabaseMealLogRepository>(),
    );
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}
