import 'profile_setup_data.dart';

/// Small product-facing completion summary for the Profile surface.
///
/// The V1 score intentionally uses five explainable groups instead of counting
/// every persisted column independently. Avatar is not part of completion.
class ProfileCompletionSummary {
  const ProfileCompletionSummary({
    required this.completedGroups,
    this.totalGroups = 5,
  });

  factory ProfileCompletionSummary.fromProfile(ProfileSetupData data) {
    var completed = 0;

    if (data.name.trim().isNotEmpty) completed++;

    final username = data.username?.trim() ?? '';
    if (username.isNotEmpty) completed++;

    // Gender and dateOfBirth are required domain values once Profile data has
    // been hydrated, so together they satisfy the demographics group.
    completed++;

    if (data.heightCm > 0 && data.currentWeightKg > 0) completed++;

    final mobile = data.mobile?.trim() ?? '';
    if (mobile.isNotEmpty) completed++;

    return ProfileCompletionSummary(completedGroups: completed);
  }

  final int completedGroups;
  final int totalGroups;

  int get percentage => ((completedGroups * 100) / totalGroups).round();

  bool get isComplete => completedGroups >= totalGroups;
}
