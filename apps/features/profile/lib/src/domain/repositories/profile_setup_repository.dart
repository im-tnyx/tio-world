import 'dart:async';

import 'package:tio_core/core.dart';

import '../models/profile_setup_data.dart';

/// Canonical repository contract for persisting and retrieving user profile setup data.
abstract interface class ProfileSetupRepository {
  /// Persists or updates the complete user profile setup data.
  Future<void> saveProfileSetup(ProfileSetupData data);

  /// Updates only account-owned measurement-unit preferences.
  ///
  /// Implementations must not reconstruct or overwrite unrelated profile,
  /// avatar, mobile, verification, or onboarding fields.
  Future<void> updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  );

  /// Retrieves the persisted profile setup data, or null if not yet saved.
  Future<ProfileSetupData?> getProfileSetup();

  /// Watches for real-time changes to the profile setup data.
  Stream<ProfileSetupData?> watchProfileSetup();

  /// Uploads avatar image file bytes and returns the public or persistent URL.
  Future<String> uploadAvatarImage({required String fileName, required List<int> bytes});

  /// Clears the user's avatar_url in the database.
  Future<void> deleteAvatarImage();

  /// Updates the user's avatar frame setting (e.g. 'none', 'plusRing', 'proHexagon').
  Future<void> updateAvatarFrame(String frame);
}
