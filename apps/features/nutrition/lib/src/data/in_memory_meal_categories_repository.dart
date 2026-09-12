import 'dart:async';

import '../domain/models/meal_categories_config.dart';
import '../domain/models/meal_categories_transition_policy.dart';
import '../domain/repositories/meal_categories_repository.dart';

/// Deterministic non-durable Meal Categories owner for tests/local composition.
class InMemoryMealCategoriesRepository
    implements MealCategoriesRepository, MealCategoriesChangeSource {
  MealCategoriesConfig? _customizedConfig;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  bool get hasCustomization => _customizedConfig != null;
  MealCategoriesConfig? get customizedConfig => _customizedConfig;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<MealCategoriesConfig> read() async =>
      MealCategoriesConfig.resolve(_customizedConfig);

  @override
  Future<void> upsert(MealCategoriesConfig config) async {
    config.validate();
    final previous = _customizedConfig;
    if (previous != null) {
      MealCategoriesTransitionPolicy.validate(
        previous: previous,
        next: config,
      );
    }
    _customizedConfig = config;
    _changes.add(null);
  }
}
