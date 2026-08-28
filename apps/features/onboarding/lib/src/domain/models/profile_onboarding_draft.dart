import 'package:tio_core/core.dart';

import 'goal_weight_direction.dart';
import 'profile_step_id.dart';

enum ProfileGender { male, female, other }

enum ProfileGoal {
  buildMuscle,
  loseWeight,
  keepFit,
  boostStrength,
  manageStress,
}

enum ProfileActivityLevel { sedentary, light, active, veryActive, dynamic }

enum ProfileHealthCondition {
  none,
  diabetes,
  hypertension,
  lowBloodPressure,
  other,
}

class ProfileOnboardingDraft {
  ProfileOnboardingDraft({
    this.currentStepId = ProfileStepId.name,
    this.name = '',
    this.gender,
    Set<ProfileGoal> goals = const {},
    this.dateOfBirth,
    this.heightCm,
    UnitPreferences? unitPreferences,
    String? heightUnit,
    this.currentWeightKg,
    String? weightUnit,
    this.targetWeightKg,
    this.targetWeightDirection,
    this.activityLevel,
    Set<ProfileHealthCondition> healthConditions = const {},
    this.otherHealthCondition = '',
    this.mobile = '',
    this.isMobileVerified = false,
  })  : unitPreferences = _resolveUnitPreferences(
          base: unitPreferences ?? UnitPreferences.metric,
          legacyHeightUnit: heightUnit,
          legacyWeightUnit: weightUnit,
        ),
        goals = Set.unmodifiable(goals),
        healthConditions = Set.unmodifiable(healthConditions);

  final ProfileStepId currentStepId;
  final String name;
  final ProfileGender? gender;
  final Set<ProfileGoal> goals;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final UnitPreferences unitPreferences;
  final double? currentWeightKg;
  final double? targetWeightKg;

  /// Direction that semantically owns [targetWeightKg].
  ///
  /// This is onboarding-draft compatibility metadata. It is derived only from
  /// explicit Goal intent, never from current/target weight deltas or BMI.
  final GoalWeightDirection? targetWeightDirection;

  final ProfileActivityLevel? activityLevel;
  final Set<ProfileHealthCondition> healthConditions;
  final String otherHealthCondition;
  final String mobile;
  final bool isMobileVerified;

  /// Compatibility presentation aliases while screens migrate to typed units.
  String get heightUnit =>
      unitPreferences.heightUnit == HeightUnit.ftIn ? 'ft' : 'cm';
  String get weightUnit =>
      unitPreferences.weightUnit == WeightUnit.lb ? 'lbs' : 'kg';

  ProfileOnboardingDraft copyWith({
    ProfileStepId? currentStepId,
    String? name,
    ProfileGender? gender,
    Set<ProfileGoal>? goals,
    DateTime? dateOfBirth,
    double? heightCm,
    UnitPreferences? unitPreferences,
    String? heightUnit,
    bool clearHeightCm = false,
    double? currentWeightKg,
    String? weightUnit,
    bool clearCurrentWeightKg = false,
    double? targetWeightKg,
    bool clearTargetWeightKg = false,
    GoalWeightDirection? targetWeightDirection,
    bool clearTargetWeightDirection = false,
    ProfileActivityLevel? activityLevel,
    Set<ProfileHealthCondition>? healthConditions,
    String? otherHealthCondition,
    String? mobile,
    bool? isMobileVerified,
  }) {
    final clearTarget = clearTargetWeightKg;
    return ProfileOnboardingDraft(
      currentStepId: currentStepId ?? this.currentStepId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      goals: goals ?? this.goals,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: clearHeightCm ? null : heightCm ?? this.heightCm,
      unitPreferences: unitPreferences ?? this.unitPreferences,
      heightUnit: heightUnit,
      currentWeightKg:
          clearCurrentWeightKg ? null : currentWeightKg ?? this.currentWeightKg,
      weightUnit: weightUnit,
      targetWeightKg: clearTarget ? null : targetWeightKg ?? this.targetWeightKg,
      targetWeightDirection: clearTarget || clearTargetWeightDirection
          ? null
          : targetWeightDirection ?? this.targetWeightDirection,
      activityLevel: activityLevel ?? this.activityLevel,
      healthConditions: healthConditions ?? this.healthConditions,
      otherHealthCondition: otherHealthCondition ?? this.otherHealthCondition,
      mobile: mobile ?? this.mobile,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileOnboardingDraft &&
            currentStepId == other.currentStepId &&
            name == other.name &&
            gender == other.gender &&
            _sameSet(goals, other.goals) &&
            dateOfBirth == other.dateOfBirth &&
            heightCm == other.heightCm &&
            unitPreferences == other.unitPreferences &&
            currentWeightKg == other.currentWeightKg &&
            targetWeightKg == other.targetWeightKg &&
            targetWeightDirection == other.targetWeightDirection &&
            activityLevel == other.activityLevel &&
            _sameSet(healthConditions, other.healthConditions) &&
            otherHealthCondition == other.otherHealthCondition &&
            mobile == other.mobile &&
            isMobileVerified == other.isMobileVerified;
  }

  @override
  int get hashCode => Object.hash(
        currentStepId,
        name,
        gender,
        Object.hashAllUnordered(goals),
        dateOfBirth,
        heightCm,
        unitPreferences,
        currentWeightKg,
        targetWeightKg,
        targetWeightDirection,
        activityLevel,
        Object.hashAllUnordered(healthConditions),
        otherHealthCondition,
        mobile,
        isMobileVerified,
      );
}

UnitPreferences _resolveUnitPreferences({
  required UnitPreferences base,
  String? legacyHeightUnit,
  String? legacyWeightUnit,
}) {
  final height = switch (legacyHeightUnit) {
    'ft' || 'in' || 'ft_in' => HeightUnit.ftIn,
    'cm' => HeightUnit.cm,
    _ => null,
  };
  final weight = switch (legacyWeightUnit) {
    'lb' || 'lbs' => WeightUnit.lb,
    'kg' => WeightUnit.kg,
    _ => null,
  };
  return base.copyWith(heightUnit: height, weightUnit: weight);
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.every(right.contains);
