import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('InMemoryProfileSetupRepository', () {
    test('round trips profile setup data', () async {
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
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      );

      await repository.saveProfileSetup(data);
      final retrieved = await repository.getProfileSetup();

      expect(retrieved, equals(data));
      expect(retrieved?.name, 'Tio User');
      expect(retrieved?.gender, ProfileGender.male);
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
