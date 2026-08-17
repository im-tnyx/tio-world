import 'package:tio_feature_profile/profile.dart' as profile_owner;

import '../models/models.dart';

/// Pure mapper from onboarding [ProfileOnboardingDraft] to canonical [profile_owner.ProfileSetupData].
class ProfileSetupMapper {
  const ProfileSetupMapper();

  profile_owner.ProfileSetupData map(ProfileOnboardingDraft draft) {
    final name = draft.name.trim().isEmpty ? 'User' : draft.name.trim();
    final gender = draft.gender ?? ProfileGender.male;
    final goals = draft.goals.isEmpty ? const {ProfileGoal.keepFit} : draft.goals;
    final dob = draft.dateOfBirth ?? DateTime(2000, 1, 1);
    final height = (draft.heightCm != null && draft.heightCm! > 0)
        ? draft.heightCm!
        : 170.0;
    final currentWeight =
        (draft.currentWeightKg != null && draft.currentWeightKg! > 0)
            ? draft.currentWeightKg!
            : 70.0;
    final activity = draft.activityLevel ?? ProfileActivityLevel.active;
    final rawHealth = draft.healthConditions.isEmpty
        ? const {ProfileHealthCondition.none}
        : draft.healthConditions;

    return profile_owner.ProfileSetupData(
      name: name,
      gender: switch (gender) {
        ProfileGender.male => profile_owner.ProfileGender.male,
        ProfileGender.female => profile_owner.ProfileGender.female,
        ProfileGender.other => profile_owner.ProfileGender.other,
      },
      goals: goals
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
      unitPreferences: draft.unitPreferences,
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
      healthConditions: rawHealth
          .where((cond) =>
              cond != ProfileHealthCondition.other ||
              draft.otherHealthCondition.trim().isNotEmpty)
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
      // Mobile is intentionally not mapped. It belongs to Account Setup and an
      // old/resumed onboarding draft must never overwrite the durable account
      // mobile or its verification evidence.
    );
  }
}
