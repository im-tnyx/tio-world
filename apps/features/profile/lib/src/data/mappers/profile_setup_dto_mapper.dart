import '../../domain/models/profile_activity_level.dart';
import '../../domain/models/profile_gender.dart';
import '../../domain/models/profile_goal.dart';
import '../../domain/models/profile_health_condition.dart';
import '../../domain/models/profile_setup_data.dart';

/// Maps domain [ProfileSetupData] into the verified Tnyx backend DTO schema.
class ProfileSetupDtoMapper {
  const ProfileSetupDtoMapper();

  Map<String, dynamic> toRequestPayload(ProfileSetupData data) {
    final payload = <String, dynamic>{
      'name': data.name.trim(),
      'gender': mapGender(data.gender),
      'goals': data.goals.map(mapGoal).toList(),
      'dob': formatDob(data.dateOfBirth),
      'height': data.heightCm,
      'currentWeight': data.currentWeightKg,
      'activityLevel': mapActivityLevel(data.activityLevel),
    };

    if (data.username != null && data.username!.trim().isNotEmpty) {
      payload['username'] = data.username!.trim();
    }

    if (data.healthConditions.isNotEmpty) {
      payload['healthConditions'] =
          data.healthConditions.map(mapHealthCondition).toList();
    }

    if (data.otherHealthCondition != null &&
        data.otherHealthCondition!.trim().isNotEmpty) {
      payload['otherHealthCondition'] = data.otherHealthCondition!.trim();
    }

    return payload;
  }

  static String mapGender(ProfileGender gender) => switch (gender) {
        ProfileGender.male => 'male',
        ProfileGender.female => 'female',
        ProfileGender.other => 'other',
      };

  static String mapGoal(ProfileGoal goal) => switch (goal) {
        ProfileGoal.buildMuscle => 'build_muscle',
        ProfileGoal.loseWeight => 'lose_weight',
        ProfileGoal.keepFit => 'keep_fit',
        ProfileGoal.boostStrength => 'boost_strength',
        ProfileGoal.manageStress => 'manage_stress',
      };

  static String mapActivityLevel(ProfileActivityLevel level) => switch (level) {
        ProfileActivityLevel.sedentary => 'sedentary',
        ProfileActivityLevel.light => 'light',
        ProfileActivityLevel.active => 'active',
        ProfileActivityLevel.veryActive => 'very_active',
        ProfileActivityLevel.dynamic => 'dynamic',
      };

  static String mapHealthCondition(ProfileHealthCondition condition) =>
      switch (condition) {
        ProfileHealthCondition.none => 'none',
        ProfileHealthCondition.diabetes => 'diabetes',
        ProfileHealthCondition.hypertension => 'hypertension',
        ProfileHealthCondition.lowBloodPressure => 'low_blood_pressure',
        ProfileHealthCondition.other => 'other',
      };

  static String formatDob(DateTime dob) {
    final year = dob.year.toString().padLeft(4, '0');
    final month = dob.month.toString().padLeft(2, '0');
    final day = dob.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
