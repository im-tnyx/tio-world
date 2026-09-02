import '../domain/models/nutrition_targets_data.dart';
import '../domain/models/additional_nutrient_goal.dart';
import '../domain/repositories/nutrition_targets_repository.dart';

/// Deterministic non-durable canonical Nutrition Targets owner for tests/local
/// composition.
class InMemoryNutritionTargetsRepository
    implements NutritionTargetsRepository {
  NutritionTargetsData? _data;

  NutritionTargetsData? get data => _data;

  @override
  Future<NutritionTargetsData?> read() async => _data;

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    targets.validate();
    _data = targets;
  }

  @override
  Future<void> updateAdditionalNutrientGoals(
    AdditionalNutrientGoalSet goals,
  ) async {
    goals.validate();
    _data = (_data ?? const NutritionTargetsData())
        .withAdditionalNutrientGoals(goals);
  }
}
