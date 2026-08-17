import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('InMemoryProfileSetupRepository', () {
    test('round trips profile setup data with explicit mixed units', () async {
      final repository = InMemoryProfileSetupRepository();
      expect(await repository.getProfileSetup(), isNull);

      final data = ProfileSetupData(
        name: 'Tio User',
        gender: ProfileGender.male,
        goals: const {ProfileGoal.buildMuscle, ProfileGoal.keepFit},
        dateOfBirth: DateTime(1995, 5, 20),
        heightCm: 178.5,
        currentWeightKg: 75.0,
        targetWeightKg: 80.0,
        unitPreferences: const MeasurementUnitPreferences(
          weightUnit: WeightUnit.lb,
          heightUnit: HeightUnit.ftIn,
          distanceUnit: DistanceUnit.km,
          volumeUnit: VolumeUnit.flOz,
        ),
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      );

      await repository.saveProfileSetup(data);
      final retrieved = await repository.getProfileSetup();

      expect(retrieved, equals(data));
      expect(retrieved?.name, 'Tio User');
      expect(retrieved?.gender, ProfileGender.male);
      expect(
        retrieved?.unitPreferences,
        const MeasurementUnitPreferences(
          weightUnit: WeightUnit.lb,
          heightUnit: HeightUnit.ftIn,
          distanceUnit: DistanceUnit.km,
          volumeUnit: VolumeUnit.flOz,
        ),
      );
      expect(retrieved?.hasExplicitUnitPreferences, isTrue);
    });

    test('legacy caller gets metric display defaults without owning unit writes', () {
      final data = ProfileSetupData(
        name: 'Legacy User',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.keepFit},
        dateOfBirth: DateTime(1998, 1, 1),
        heightCm: 160.0,
        currentWeightKg: 60.0,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      );

      expect(data.unitPreferences, MeasurementUnitPreferences.metric);
      expect(data.hasExplicitUnitPreferences, isFalse);
    });

    test('field-specific unit update preserves canonical profile values', () async {
      final repository = InMemoryProfileSetupRepository();
      final initial = ProfileSetupData(
        name: 'Stable Values',
        username: 'stable',
        gender: ProfileGender.other,
        goals: const {ProfileGoal.keepFit},
        dateOfBirth: DateTime(1990, 2, 3),
        heightCm: 182.88,
        currentWeightKg: 81.6466266,
        targetWeightKg: 78.0,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
        mobile: '+919876543210',
        isMobileVerified: true,
      );
      await repository.saveProfileSetup(initial);

      await repository.updateMeasurementUnitPreferences(
        MeasurementUnitPreferences.imperial,
      );

      final updated = await repository.getProfileSetup();
      expect(updated?.unitPreferences, MeasurementUnitPreferences.imperial);
      expect(updated?.heightCm, 182.88);
      expect(updated?.currentWeightKg, 81.6466266);
      expect(updated?.targetWeightKg, 78.0);
      expect(updated?.mobile, '+919876543210');
      expect(updated?.isMobileVerified, isTrue);
      expect(updated?.username, 'stable');
    });

    test('overwrites previous profile on subsequent save', () async {
      final repository = InMemoryProfileSetupRepository();

      final first = ProfileSetupData(
        name: 'First User',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.loseWeight},
        dateOfBirth: DateTime(1998, 1, 1),
        heightCm: 160.0,
        currentWeightKg: 65.0,
        activityLevel: ProfileActivityLevel.sedentary,
        healthConditions: const {ProfileHealthCondition.none},
      );

      final second = ProfileSetupData(
        name: 'Updated User',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.keepFit},
        dateOfBirth: DateTime(1998, 1, 1),
        heightCm: 160.0,
        currentWeightKg: 60.0,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      );

      await repository.saveProfileSetup(first);
      await repository.saveProfileSetup(second);

      final retrieved = await repository.getProfileSetup();
      expect(retrieved, equals(second));
      expect(retrieved?.name, 'Updated User');
      expect(retrieved?.currentWeightKg, 60.0);
    });
  });
}
