import 'profile_activity_level.dart';
import 'profile_gender.dart';
import 'profile_goal.dart';
import 'profile_health_condition.dart';

/// Immutable domain model representing user profile data captured during setup/onboarding.
class ProfileSetupData {
  const ProfileSetupData({
    required this.name,
    this.username,
    this.avatarUrl,
    this.plan = 'free',
    required this.gender,
    required this.goals,
    required this.dateOfBirth,
    required this.heightCm,
    required this.currentWeightKg,
    this.targetWeightKg,
    required this.activityLevel,
    required this.healthConditions,
    this.otherHealthCondition,
  });

  final String name;
  final String? username;
  final String? avatarUrl;
  final String plan;
  final ProfileGender gender;
  final Set<ProfileGoal> goals;
  final DateTime dateOfBirth;
  final double heightCm;
  final double currentWeightKg;
  final double? targetWeightKg;
  final ProfileActivityLevel activityLevel;
  final Set<ProfileHealthCondition> healthConditions;
  final String? otherHealthCondition;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileSetupData &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            username == other.username &&
            avatarUrl == other.avatarUrl &&
            plan == other.plan &&
            gender == other.gender &&
            goals.length == other.goals.length &&
            goals.containsAll(other.goals) &&
            dateOfBirth == other.dateOfBirth &&
            heightCm == other.heightCm &&
            currentWeightKg == other.currentWeightKg &&
            targetWeightKg == other.targetWeightKg &&
            activityLevel == other.activityLevel &&
            healthConditions.length == other.healthConditions.length &&
            healthConditions.containsAll(other.healthConditions) &&
            otherHealthCondition == other.otherHealthCondition;
  }

  @override
  int get hashCode => Object.hash(
        name,
        username,
        avatarUrl,
        plan,
        gender,
        Object.hashAll(goals),
        dateOfBirth,
        heightCm,
        currentWeightKg,
        targetWeightKg,
        activityLevel,
        Object.hashAll(healthConditions),
        otherHealthCondition,
      );

  @override
  String toString() {
    // Redact sensitive details in default string representation
    return 'ProfileSetupData(name: $name, username: $username, gender: $gender, goals: $goals)';
  }
}
