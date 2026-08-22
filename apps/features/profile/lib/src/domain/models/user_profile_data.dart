import 'dart:collection';

import 'package:tio_core/core.dart';

import 'profile_activity_level.dart';
import 'profile_gender.dart';
import 'profile_health_condition.dart';

/// Canonical common personal Profile owned by `public.user_profiles`.
///
/// Account/contact, App Mode, Body, Wellness, Nutrition and Workout concepts
/// intentionally do not belong in this model.
final class UserProfileData {
  UserProfileData({
    required String name,
    required this.gender,
    required this.dateOfBirth,
    required this.unitPreferences,
    required double heightCm,
    required this.activityLevel,
    required Set<ProfileHealthCondition> healthConditions,
    String? otherHealthCondition,
  })  : name = _validateName(name),
        heightCm = _validateHeight(heightCm),
        healthConditions = _validateHealthConditions(healthConditions),
        otherHealthCondition = _normalizeOtherCondition(otherHealthCondition);

  final String name;
  final ProfileGender gender;
  final DateTime dateOfBirth;
  final MeasurementUnitPreferences unitPreferences;
  final double heightCm;
  final ProfileActivityLevel activityLevel;
  final Set<ProfileHealthCondition> healthConditions;
  final String? otherHealthCondition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileData &&
          name == other.name &&
          gender == other.gender &&
          dateOfBirth == other.dateOfBirth &&
          unitPreferences == other.unitPreferences &&
          heightCm == other.heightCm &&
          activityLevel == other.activityLevel &&
          healthConditions.length == other.healthConditions.length &&
          healthConditions.containsAll(other.healthConditions) &&
          otherHealthCondition == other.otherHealthCondition;

  @override
  int get hashCode => Object.hash(
        name,
        gender,
        dateOfBirth,
        unitPreferences,
        heightCm,
        activityLevel,
        Object.hashAllUnordered(healthConditions),
        otherHealthCondition,
      );
}

String _validateName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'name', 'must not be empty');
  }
  return normalized;
}

double _validateHeight(double value) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, 'heightCm', 'must be finite and positive');
  }
  return value;
}

Set<ProfileHealthCondition> _validateHealthConditions(
  Set<ProfileHealthCondition> value,
) {
  final copy = Set<ProfileHealthCondition>.of(value);
  if (copy.contains(ProfileHealthCondition.none) && copy.length > 1) {
    throw ArgumentError.value(
      value,
      'healthConditions',
      '`none` cannot be combined with another health condition',
    );
  }
  return UnmodifiableSetView(copy);
}

String? _normalizeOtherCondition(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
