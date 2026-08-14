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
    this.currentWeightKg,
    this.targetWeightKg,
    this.activityLevel,
    Set<ProfileHealthCondition> healthConditions = const {},
    this.otherHealthCondition = '',
    this.mobile = '',
    this.isMobileVerified = false,
  })  : goals = Set.unmodifiable(goals),
        healthConditions = Set.unmodifiable(healthConditions);

  final ProfileStepId currentStepId;
  final String name;
  final ProfileGender? gender;
  final Set<ProfileGoal> goals;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final ProfileActivityLevel? activityLevel;
  final Set<ProfileHealthCondition> healthConditions;
  final String otherHealthCondition;
  final String mobile;
  final bool isMobileVerified;

  ProfileOnboardingDraft copyWith({
    ProfileStepId? currentStepId,
    String? name,
    ProfileGender? gender,
    Set<ProfileGoal>? goals,
    DateTime? dateOfBirth,
    double? heightCm,
    bool clearHeightCm = false,
    double? currentWeightKg,
    bool clearCurrentWeightKg = false,
    double? targetWeightKg,
    bool clearTargetWeightKg = false,
    ProfileActivityLevel? activityLevel,
    Set<ProfileHealthCondition>? healthConditions,
    String? otherHealthCondition,
    String? mobile,
    bool? isMobileVerified,
  }) {
    return ProfileOnboardingDraft(
      currentStepId: currentStepId ?? this.currentStepId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      goals: goals ?? this.goals,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: clearHeightCm ? null : heightCm ?? this.heightCm,
      currentWeightKg:
          clearCurrentWeightKg ? null : currentWeightKg ?? this.currentWeightKg,
      targetWeightKg:
          clearTargetWeightKg ? null : targetWeightKg ?? this.targetWeightKg,
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
            currentWeightKg == other.currentWeightKg &&
            targetWeightKg == other.targetWeightKg &&
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
        currentWeightKg,
        targetWeightKg,
        activityLevel,
        Object.hashAllUnordered(healthConditions),
        otherHealthCondition,
        mobile,
        isMobileVerified,
      );
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.every(right.contains);
