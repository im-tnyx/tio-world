import 'nutrition_profile_repository.dart';
import 'nutrition_targets_repository.dart';

/// Compatibility composition contract for callers that still hold a legacy
/// Nutrition setup handle while canonical owner cutovers are in progress.
///
/// Implementations expose the real canonical repositories; callers must not
/// infer that the legacy mixed repository itself owns canonical persistence.
abstract interface class CanonicalNutritionOwnerRepositories {
  NutritionProfileRepository get nutritionProfileRepository;
  NutritionTargetsRepository get nutritionTargetsRepository;
}
