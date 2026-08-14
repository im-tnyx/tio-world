import '../models/targets_setup_data.dart';

/// Canonical repository contract for persisting and retrieving daily targets and nutritional setup data.
abstract interface class TargetsSetupRepository {
  /// Persists or updates the user daily targets and nutritional setup data.
  Future<void> saveTargetsSetup(TargetsSetupData data);

  /// Retrieves the persisted targets setup data, or null if not yet saved.
  Future<TargetsSetupData?> getTargetsSetup();
}
