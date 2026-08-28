import 'package:tio_feature_profile/profile.dart' as profile_owner;

import '../models/models.dart';

/// Maps completed Product Onboarding common-Profile answers to the narrow
/// canonical `user_profiles` owner contract.
///
/// This mapper intentionally has no access to Account, Goal or Body output
/// fields. Missing required semantic answers fail closed instead of being
/// replaced with fabricated defaults.
class UserProfileMapper {
  const UserProfileMapper();

  profile_owner.UserProfileData map(ProfileOnboardingDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(draft.name, 'name', 'must not be empty');
    }

    final gender = draft.gender;
    if (gender == null) {
      throw ArgumentError.notNull('gender');
    }

    final dateOfBirth = draft.dateOfBirth;
    if (dateOfBirth == null) {
      throw ArgumentError.notNull('dateOfBirth');
    }

    final heightCm = draft.heightCm;
    if (heightCm == null || !heightCm.isFinite || heightCm <= 0) {
      throw ArgumentError.value(
        heightCm,
        'heightCm',
        'must be finite and positive',
      );
    }

    final activityLevel = draft.activityLevel;
    if (activityLevel == null) {
      throw ArgumentError.notNull('activityLevel');
    }

    final normalizedOtherHealthCondition = draft.otherHealthCondition.trim();
    final otherSelected =
        draft.healthConditions.contains(ProfileHealthCondition.other);

    return profile_owner.UserProfileData(
      name: name,
      gender: switch (gender) {
        ProfileGender.male => profile_owner.ProfileGender.male,
        ProfileGender.female => profile_owner.ProfileGender.female,
        ProfileGender.other => profile_owner.ProfileGender.other,
      },
      dateOfBirth: DateTime(
        dateOfBirth.year,
        dateOfBirth.month,
        dateOfBirth.day,
      ),
      unitPreferences: draft.unitPreferences,
      heightCm: heightCm,
      activityLevel: switch (activityLevel) {
        ProfileActivityLevel.sedentary =>
          profile_owner.ProfileActivityLevel.sedentary,
        ProfileActivityLevel.light => profile_owner.ProfileActivityLevel.light,
        ProfileActivityLevel.active =>
          profile_owner.ProfileActivityLevel.active,
        ProfileActivityLevel.veryActive =>
          profile_owner.ProfileActivityLevel.veryActive,
        ProfileActivityLevel.dynamic =>
          profile_owner.ProfileActivityLevel.dynamic,
      },
      healthConditions: draft.healthConditions
          .map((condition) => switch (condition) {
                ProfileHealthCondition.none =>
                  profile_owner.ProfileHealthCondition.none,
                ProfileHealthCondition.diabetes =>
                  profile_owner.ProfileHealthCondition.diabetes,
                ProfileHealthCondition.hypertension =>
                  profile_owner.ProfileHealthCondition.hypertension,
                ProfileHealthCondition.lowBloodPressure =>
                  profile_owner.ProfileHealthCondition.lowBloodPressure,
                ProfileHealthCondition.other =>
                  profile_owner.ProfileHealthCondition.other,
              })
          .toSet(),
      otherHealthCondition:
          otherSelected && normalizedOtherHealthCondition.isNotEmpty
              ? normalizedOtherHealthCondition
              : null,
    );
  }
}
