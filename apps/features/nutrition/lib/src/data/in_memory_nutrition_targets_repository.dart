import 'dart:async';

import '../domain/models/nutrition_targets_data.dart';
import '../domain/repositories/nutrition_targets_repository.dart';

/// Deterministic non-durable canonical Nutrition Targets owner for tests/local
/// composition.
class InMemoryNutritionTargetsRepository
    implements NutritionTargetsRepository, NutritionTargetsChangeSource {
  NutritionTargetsData? _data;
  var _revision = 0;
  final StreamController<int> _changes = StreamController<int>.broadcast();

  NutritionTargetsData? get data => _data;

  @override
  Stream<int> get changes => _changes.stream;

  @override
  Future<NutritionTargetsData?> read() async => _data;

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    targets.validate();
    _data = targets;
    _changes.add(++_revision);
  }
}
