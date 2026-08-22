import '../domain/models/targets_setup_data.dart';
import '../domain/repositories/canonical_nutrition_owner_repositories.dart';
import '../domain/repositories/nutrition_profile_repository.dart';
import '../domain/repositories/nutrition_targets_repository.dart';
import '../domain/repositories/targets_setup_repository.dart';
import 'in_memory_nutrition_profile_repository.dart';
import 'in_memory_nutrition_targets_repository.dart';

/// Thread-safe in-memory implementation of [TargetsSetupRepository].
///
/// The legacy setup value remains separate from the canonical Nutrition owner
/// stores. Product Onboarding O5D reaches those stores through
/// [CanonicalNutritionOwnerRepositories] and never calls [saveTargetsSetup].
class InMemoryTargetsSetupRepository
    implements TargetsSetupRepository, CanonicalNutritionOwnerRepositories {
  InMemoryTargetsSetupRepository({TargetsSetupData? initialData})
      : _data = initialData;

  TargetsSetupData? _data;
  final InMemoryNutritionProfileRepository _nutritionProfileRepository =
      InMemoryNutritionProfileRepository();
  final InMemoryNutritionTargetsRepository _nutritionTargetsRepository =
      InMemoryNutritionTargetsRepository();

  @override
  NutritionProfileRepository get nutritionProfileRepository =>
      _nutritionProfileRepository;

  @override
  NutritionTargetsRepository get nutritionTargetsRepository =>
      _nutritionTargetsRepository;

  @override
  Future<void> saveTargetsSetup(TargetsSetupData data) async {
    _data = data;
  }

  @override
  Future<TargetsSetupData?> getTargetsSetup() async {
    return _data;
  }
}
