import '../models/models.dart';

class ProfileStepValidator {
  const ProfileStepValidator({DateTime Function()? now}) : _now = now;

  static const minimumNameLength = 3;
  static const oldestBirthYear = 1950;
  static const minimumHeightCm = 100.0;
  static const maximumHeightCm = 250.0;
  static const minimumWeightKg = 30.0;
  static const maximumWeightKg = 200.0;

  /// Legacy ProfileGoal grouping retained only for compatibility callers while
  /// the runtime Goal screen moves to GoalIntentSelectionPolicy.
  static const primaryGoals = <ProfileGoal>{
    ProfileGoal.buildMuscle,
    ProfileGoal.loseWeight,
    ProfileGoal.keepFit,
  };

  final DateTime Function()? _now;

  Map<ProfileStepId, String> validate(
    ProfileOnboardingDraft draft, {
    GoalWeightDirection? goalWeightDirection,
  }) {
    final error = _validateCurrentStep(
      draft,
      goalWeightDirection: goalWeightDirection,
    );
    return error == null ? const {} : {draft.currentStepId: error};
  }

  bool isCurrentStepValid(
    ProfileOnboardingDraft draft, {
    GoalWeightDirection? goalWeightDirection,
  }) =>
      _validateCurrentStep(
        draft,
        goalWeightDirection: goalWeightDirection,
      ) ==
      null;

  String? _validateCurrentStep(
    ProfileOnboardingDraft draft, {
    GoalWeightDirection? goalWeightDirection,
  }) {
    return switch (draft.currentStepId) {
      ProfileStepId.name => draft.name.trim().length >= minimumNameLength
          ? null
          : 'Enter at least $minimumNameLength characters.',
      ProfileStepId.gender =>
        draft.gender == null ? 'Choose a gender option.' : null,
      // Goal is validated by GoalIntentSelectionPolicy in OnboardingController.
      ProfileStepId.goal => null,
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
      ProfileStepId.targetWeight => _validateTargetWeight(
          draft,
          goalWeightDirection,
        ),
      ProfileStepId.activity =>
        draft.activityLevel == null ? 'Choose an activity level.' : null,
      ProfileStepId.healthConditions => null,
    };
  }

  String? _validateTargetWeight(
    ProfileOnboardingDraft draft,
    GoalWeightDirection? direction,
  ) {
    final rangeError = _validateRange(
      draft.targetWeightKg,
      minimumWeightKg,
      maximumWeightKg,
      'target weight',
      'kg',
    );
    if (rangeError != null) return rangeError;

    final current = draft.currentWeightKg;
    final target = draft.targetWeightKg;
    if (current == null || target == null || direction == null) return null;

    return switch (direction) {
      GoalWeightDirection.loss => target < current
          ? null
          : 'Choose a target below your current weight for this goal.',
      GoalWeightDirection.gain => target > current
          ? null
          : 'Choose a target above your current weight for this goal.',
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
