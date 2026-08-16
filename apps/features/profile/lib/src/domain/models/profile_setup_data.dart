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
    this.avatarFrame = 'none',
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
    this.mobile,
    this.isMobileVerified = false,
  });

  final String name;
  final String? username;
  final String? avatarUrl;
  final String avatarFrame;
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
  final String? mobile;
  final bool isMobileVerified;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileSetupData &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            username == other.username &&
            avatarUrl == other.avatarUrl &&
            avatarFrame == other.avatarFrame &&
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
            otherHealthCondition == other.otherHealthCondition &&
            mobile == other.mobile &&
            isMobileVerified == other.isMobileVerified;
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
        mobile,
        isMobileVerified,
      );

  @override
  String toString() {
    return 'ProfileSetupData(name: $name, username: $username, gender: $gender, mobile: $mobile, verified: $isMobileVerified)';
  }
}
