import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
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
        unitPreferences: const MeasurementUnitPreferences(
          weightUnit: WeightUnit.lb,
          heightUnit: HeightUnit.ftIn,
          distanceUnit: DistanceUnit.km,
          volumeUnit: VolumeUnit.flOz,
        ),
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
      expect(
        result.unitPreferences,
        const MeasurementUnitPreferences(
          weightUnit: WeightUnit.lb,
          heightUnit: HeightUnit.ftIn,
          distanceUnit: DistanceUnit.km,
          volumeUnit: VolumeUnit.flOz,
        ),
      );
      expect(result.activityLevel, profile_owner.ProfileActivityLevel.active);
      expect(
        result.healthConditions,
        {profile_owner.ProfileHealthCondition.hypertension},
      );
      expect(result.otherHealthCondition, 'Occasional stress');
    });

    test('maps default fallback values when fields are blank or null', () {
      final draft = ProfileOnboardingDraft(
        name: '   ',
        gender: null,
        goals: const {},
        dateOfBirth: null,
        heightCm: 0,
        currentWeightKg: 0,
        activityLevel: null,
        healthConditions: const {},
      );

      final result = mapper.map(draft);

      expect(result.name, 'User');
      expect(result.gender, profile_owner.ProfileGender.male);
      expect(result.heightCm, 170.0);
      expect(result.currentWeightKg, 70.0);
      expect(result.unitPreferences, MeasurementUnitPreferences.metric);
      expect(result.activityLevel, profile_owner.ProfileActivityLevel.active);
      expect(
        result.healthConditions,
        {profile_owner.ProfileHealthCondition.none},
      );
    });
  });
}
