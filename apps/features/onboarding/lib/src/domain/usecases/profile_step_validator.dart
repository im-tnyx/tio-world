import '../models/models.dart';

class ProfileStepValidator {
  const ProfileStepValidator({DateTime Function()? now}) : _now = now;

  static const minimumNameLength = 3;
  static const oldestBirthYear = 1950;
  static const minimumHeightCm = 100.0;
  static const maximumHeightCm = 250.0;
  static const minimumWeightKg = 30.0;
  static const maximumWeightKg = 200.0;

  static const primaryGoals = <ProfileGoal>{
    ProfileGoal.buildMuscle,
    ProfileGoal.loseWeight,
    ProfileGoal.keepFit,
  };

  final DateTime Function()? _now;

  Map<ProfileStepId, String> validate(ProfileOnboardingDraft draft) {
    final error = _validateCurrentStep(draft);
    return error == null ? const {} : {draft.currentStepId: error};
  }

  bool isCurrentStepValid(ProfileOnboardingDraft draft) =>
      _validateCurrentStep(draft) == null;

  String? _validateCurrentStep(ProfileOnboardingDraft draft) {
    return switch (draft.currentStepId) {
      ProfileStepId.name => draft.name.trim().length >= minimumNameLength
          ? null
          : 'Enter at least $minimumNameLength characters.',
      ProfileStepId.gender =>
        draft.gender == null ? 'Choose a gender option.' : null,
      ProfileStepId.goal => draft.goals.where(primaryGoals.contains).length == 1
          ? null
          : 'Choose one primary goal.',
      ProfileStepId.age => _validateDateOfBirth(draft.dateOfBirth),
      ProfileStepId.measurementUnits => null,
      ProfileStepId.height => _validateRange(
          draft.heightCm,
          minimumHeightCm,
          maximumHeightCm,
          'height',
          'cm',
        ),
      ProfileStepId.currentWeight => _validateRange(
          draft.currentWeightKg,
          minimumWeightKg,
          maximumWeightKg,
          'current weight',
          'kg',
        ),
      ProfileStepId.targetWeight => _validateRange(
          draft.targetWeightKg,
          minimumWeightKg,
          maximumWeightKg,
          'target weight',
          'kg',
        ),
      ProfileStepId.activity =>
        draft.activityLevel == null ? 'Choose an activity level.' : null,
      ProfileStepId.healthConditions => null,
    };
  }

  String? _validateDateOfBirth(DateTime? value) {
    if (value == null) return 'Choose your date of birth.';

    final current = (_now ?? DateTime.now)();
    final today = DateTime(current.year, current.month, current.day);
    final date = DateTime(value.year, value.month, value.day);
    final oldest = DateTime(oldestBirthYear);

    if (date.isBefore(oldest) || date.isAfter(today)) {
      return 'Choose a date from $oldestBirthYear through today.';
    }
    return null;
  }

  String? _validateRange(
    double? value,
    double minimum,
    double maximum,
    String field,
    String unit,
  ) {
    if (value == null || value < minimum || value > maximum) {
      return 'Choose a $field from ${minimum.toInt()} to '
          '${maximum.toInt()} $unit.';
    }
    return null;
  }
}
