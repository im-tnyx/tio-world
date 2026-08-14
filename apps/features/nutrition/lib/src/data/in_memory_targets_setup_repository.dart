import '../domain/models/targets_setup_data.dart';
import '../domain/repositories/targets_setup_repository.dart';

/// Thread-safe in-memory implementation of [TargetsSetupRepository].
class InMemoryTargetsSetupRepository implements TargetsSetupRepository {
  InMemoryTargetsSetupRepository({TargetsSetupData? initialData})
      : _data = initialData;

  TargetsSetupData? _data;

  @override
  Future<void> saveTargetsSetup(TargetsSetupData data) async {
    _data = data;
  }

  @override
  Future<TargetsSetupData?> getTargetsSetup() async {
    return _data;
  }
}
