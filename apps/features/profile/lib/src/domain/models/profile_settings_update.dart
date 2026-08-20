import 'profile_gender.dart';

/// Profile-owned values editable from Profile Settings.
///
/// Account-owned values such as username/mobile and unrelated onboarding or
/// nutrition fields intentionally do not belong to this mutation contract.
class ProfileSettingsUpdate {
  const ProfileSettingsUpdate({
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.heightCm,
    required this.currentWeightKg,
  });

  final String name;
  final ProfileGender gender;
  final DateTime dateOfBirth;
  final double heightCm;
  final double currentWeightKg;
}
