import '../models/profile_settings_update.dart';

/// Narrow persistence owner for fields editable from Profile Settings.
abstract interface class ProfileSettingsRepository {
  /// Updates only Profile Settings-owned fields for the current account.
  ///
  /// Implementations must preserve username, mobile/verification, goals,
  /// target weight, activity, health conditions, avatar, plan, units, and
  /// completion state.
  Future<void> updateProfileSettings(ProfileSettingsUpdate update);
}
