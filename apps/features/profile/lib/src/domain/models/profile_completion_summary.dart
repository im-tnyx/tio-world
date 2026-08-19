import 'profile_setup_data.dart';

enum ProfileCompletionField {
  name,
  username,
  email,
  mobile,
  gender,
  dateOfBirth,
}

/// Product-facing completion summary for the Profile reminder surface.
///
/// V1 intentionally scores personal profile identity only. Fitness, health,
/// onboarding, plan, avatar, and derived metrics do not participate.
class ProfileCompletionSummary {
  const ProfileCompletionSummary({
    required this.completedFields,
    required this.missingFields,
  });

  factory ProfileCompletionSummary.fromProfile(
    ProfileSetupData data, {
    required String? email,
  }) {
    final completed = <ProfileCompletionField>{};

    if (data.name.trim().isNotEmpty) {
      completed.add(ProfileCompletionField.name);
    }

    final username = data.username?.trim() ?? '';
    if (username.isNotEmpty) {
      completed.add(ProfileCompletionField.username);
    }

    if ((email ?? '').trim().isNotEmpty) {
      completed.add(ProfileCompletionField.email);
    }

    final mobile = data.mobile?.trim() ?? '';
    if (mobile.isNotEmpty) {
      completed.add(ProfileCompletionField.mobile);
    }

    if (data.hasPersistedGender) {
      completed.add(ProfileCompletionField.gender);
    }

    if (data.hasPersistedDateOfBirth) {
      completed.add(ProfileCompletionField.dateOfBirth);
    }

    final missing = ProfileCompletionField.values.toSet()..removeAll(completed);

    return ProfileCompletionSummary(
      completedFields: Set.unmodifiable(completed),
      missingFields: Set.unmodifiable(missing),
    );
  }

  final Set<ProfileCompletionField> completedFields;
  final Set<ProfileCompletionField> missingFields;

  int get totalFields => ProfileCompletionField.values.length;

  int get percentage => ((completedFields.length * 100) / totalFields).round();

  bool get isComplete => missingFields.isEmpty;

  bool get hasAccountOwnedMissingField => missingFields.any(
        (field) => switch (field) {
          ProfileCompletionField.username ||
          ProfileCompletionField.email ||
          ProfileCompletionField.mobile => true,
          _ => false,
        },
      );
}
