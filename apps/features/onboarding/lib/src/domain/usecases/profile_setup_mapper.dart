import 'package:tio_feature_profile/profile.dart' as profile_owner;

import '../models/models.dart';

/// Pure mapper from onboarding [ProfileOnboardingDraft] to canonical [profile_owner.ProfileSetupData].
class ProfileSetupMapper {
  const ProfileSetupMapper();

  profile_owner.ProfileSetupData map(ProfileOnboardingDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty) {
      throw const FormatException('Profile setup requires a non-empty name.');
    }

    final gender = draft.gender;
    if (gender == null) {
      throw const FormatException('Profile setup requires a selected gender.');
    }

    if (draft.goals.isEmpty) {
      throw const FormatException('Profile setup requires at least one selected goal.');
    }

    final dob = draft.dateOfBirth;
    if (dob == null) {
      throw const FormatException('Profile setup requires a valid date of birth.');
    }

    final height = draft.heightCm;
    if (height == null || height <= 0) {
      throw const FormatException('Profile setup requires a valid height in cm.');
    }

    final currentWeight = draft.currentWeightKg;
    if (currentWeight == null || currentWeight <= 0) {
      throw const FormatException('Profile setup requires a valid current weight in kg.');
    }

    final activity = draft.activityLevel;
    if (activity == null) {
      throw const FormatException('Profile setup requires a selected activity level.');
    }

    if (draft.healthConditions.isEmpty) {
      throw const FormatException(
          'Profile setup requires at least one health condition selection.');
    }

    return profile_owner.ProfileSetupData(
      name: name,
      gender: switch (gender) {
        ProfileGender.male => profile_owner.ProfileGender.male,
        ProfileGender.female => profile_owner.ProfileGender.female,
        ProfileGender.other => profile_owner.ProfileGender.other,
      },
      goals: draft.goals
          .map((goal) => switch (goal) {
                ProfileGoal.buildMuscle => profile_owner.ProfileGoal.buildMuscle,
                ProfileGoal.loseWeight => profile_owner.ProfileGoal.loseWeight,
                ProfileGoal.keepFit => profile_owner.ProfileGoal.keepFit,
                ProfileGoal.boostStrength =>
                  profile_owner.ProfileGoal.boostStrength,
                ProfileGoal.manageStress =>
                  profile_owner.ProfileGoal.manageStress,
              })
          .toSet(),
      dateOfBirth: dob,
      heightCm: height,
      currentWeightKg: currentWeight,
      targetWeightKg: draft.targetWeightKg,
      activityLevel: switch (activity) {
        ProfileActivityLevel.sedentary =>
          profile_owner.ProfileActivityLevel.sedentary,
        ProfileActivityLevel.light => profile_owner.ProfileActivityLevel.light,
        ProfileActivityLevel.active => profile_owner.ProfileActivityLevel.active,
        ProfileActivityLevel.veryActive =>
          profile_owner.ProfileActivityLevel.veryActive,
        ProfileActivityLevel.dynamic =>
          profile_owner.ProfileActivityLevel.dynamic,
      },
      healthConditions: draft.healthConditions
          .map((cond) => switch (cond) {
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
      otherHealthCondition: draft.otherHealthCondition.trim().isEmpty
          ? null
          : draft.otherHealthCondition.trim(),
    );
  }
}
