import '../models/user_profile_data.dart';

/// Backend-neutral durable owner contract for common personal Profile data.
///
/// Implementations must not persist Account/contact, App Mode, Body, Wellness,
/// Nutrition or Workout concepts through this boundary.
abstract interface class UserProfileRepository {
  /// Returns the authenticated user's canonical common Profile, or null when no
  /// canonical `user_profiles` row exists yet.
  Future<UserProfileData?> read();

  /// Creates or replaces the authenticated user's canonical common Profile.
  Future<void> upsert(UserProfileData profile);
}
