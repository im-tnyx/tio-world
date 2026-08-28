import '../domain/wellness_targets.dart';

/// Deterministic non-durable Wellness owner for tests/local composition.
class InMemoryWellnessTargetsRepository implements WellnessTargetsRepository {
  WellnessTargetsData? _data;

  WellnessTargetsData? get data => _data;

  @override
  Future<WellnessTargetsData?> read() async => _data;

  @override
  Future<void> upsert(WellnessTargetsData targets) async {
    targets.validate();
    _data = targets;
  }
}
