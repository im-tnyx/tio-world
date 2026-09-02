import 'package:tio_shared/shared.dart';

import '../domain/models/nutrition_targets_data.dart';
import '../domain/models/additional_nutrient_goal.dart';
import '../domain/repositories/nutrition_targets_repository.dart';
import 'additional_nutrient_goals_v1_codec.dart';

/// Deterministic non-durable canonical Nutrition Targets owner for tests/local
/// composition.
class InMemoryNutritionTargetsRepository implements NutritionTargetsRepository {
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
  Future<void> updateAdditionalNutrientGoal(
    NutrientId nutrientId,
    AdditionalNutrientGoal? goal,
  ) async {
    // The same invariant the real adapter enforces. Without it this owner has
    // the opposite failure mode — `withGoal` follows `goal.nutrientId`, so a
    // mismatched delta would write the *other* nutrient here while production
    // wrote the wrong value under this one. Divergent behaviour on the same
    // bad call is worse than either outcome alone.
    AdditionalNutrientGoalsV1Codec.requireGoalIdentity(nutrientId, goal);
    goal?.validate();
    final current = _data ?? const NutritionTargetsData();
    final existing = current.additionalNutrientGoals;
    // Mirrors the real adapter: only this nutrient's key changes.
    _data = current.withAdditionalNutrientGoals(
      goal == null ? existing.without(nutrientId) : existing.withGoal(goal),
    );
  }
}
