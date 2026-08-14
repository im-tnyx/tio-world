import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/src/domain/domain.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;

void main() {
  const mapper = ProfileSetupMapper();

  group('ProfileSetupMapper', () {
    test('maps valid ProfileOnboardingDraft to canonical ProfileSetupData', () {
      final draft = ProfileOnboardingDraft(
        name: '  Tio User  ',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.loseWeight, ProfileGoal.keepFit},
        dateOfBirth: DateTime(1998, 4, 15),
        heightCm: 168.5,
        currentWeightKg: 64.0,
        targetWeightKg: 58.0,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.hypertension},
        otherHealthCondition: '  Occasional stress  ',
      );

      final result = mapper.map(draft);

      expect(result.name, 'Tio User');
      expect(result.gender, profile_owner.ProfileGender.female);
      expect(result.goals, {
        profile_owner.ProfileGoal.loseWeight,
        profile_owner.ProfileGoal.keepFit,
      });
      expect(result.dateOfBirth, DateTime(1998, 4, 15));
      expect(result.heightCm, 168.5);
      expect(result.currentWeightKg, 64.0);
      expect(result.targetWeightKg, 58.0);
      expect(result.activityLevel, profile_owner.ProfileActivityLevel.active);
      expect(result.healthConditions,
          {profile_owner.ProfileHealthCondition.hypertension});
      expect(result.otherHealthCondition, 'Occasional stress');
    });

    test('throws FormatException when name is blank', () {
      final draft = ProfileOnboardingDraft(
        name: '   ',
        gender: ProfileGender.male,
        goals: const {ProfileGoal.buildMuscle},
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: 180,
        currentWeightKg: 75,
        activityLevel: ProfileActivityLevel.sedentary,
        healthConditions: const {ProfileHealthCondition.none},
      );

      expect(() => mapper.map(draft), throwsA(isA<FormatException>()));
    });

    test('throws FormatException when gender is null', () {
      final draft = ProfileOnboardingDraft(
        name: 'User',
        gender: null,
        goals: const {ProfileGoal.buildMuscle},
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: 180,
        currentWeightKg: 75,
        activityLevel: ProfileActivityLevel.sedentary,
        healthConditions: const {ProfileHealthCondition.none},
      );

      expect(() => mapper.map(draft), throwsA(isA<FormatException>()));
    });

    test('throws FormatException when height or weight is non-positive', () {
      final draft = ProfileOnboardingDraft(
        name: 'User',
        gender: ProfileGender.other,
        goals: const {ProfileGoal.keepFit},
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: 0,
        currentWeightKg: 75,
        activityLevel: ProfileActivityLevel.sedentary,
        healthConditions: const {ProfileHealthCondition.none},
      );

      expect(() => mapper.map(draft), throwsA(isA<FormatException>()));
    });
  });
}
