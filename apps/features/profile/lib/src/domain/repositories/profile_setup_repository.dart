import '../models/profile_setup_data.dart';

/// Canonical repository contract for persisting and retrieving user profile setup data.
abstract interface class ProfileSetupRepository {
  /// Persists or updates the complete user profile setup data.
  Future<void> saveProfileSetup(ProfileSetupData data);

  /// Retrieves the persisted profile setup data, or null if not yet saved.
  Future<ProfileSetupData?> getProfileSetup();
}
