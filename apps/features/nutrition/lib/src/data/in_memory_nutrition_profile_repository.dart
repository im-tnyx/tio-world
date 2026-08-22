import '../domain/models/nutrition_profile_data.dart';
import '../domain/repositories/nutrition_profile_repository.dart';

/// Deterministic non-durable canonical Nutrition Profile owner for tests/local
/// composition.
class InMemoryNutritionProfileRepository
    implements NutritionProfileRepository {
  NutritionProfileData? _data;

  NutritionProfileData? get data => _data;

  @override
  Future<NutritionProfileData?> read() async => _data;

  @override
  Future<void> upsert(NutritionProfileData profile) async {
    _data = profile;
  }
}
