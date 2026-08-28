import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/profile.dart';

ProfileSetupData _profile({
  ProfileGender gender = ProfileGender.male,
  DateTime? dateOfBirth,
  double heightCm = 180,
  double currentWeightKg = 75,
}) {
  return ProfileSetupData(
    name: 'Rahul',
    gender: gender,
    goals: const {ProfileGoal.buildMuscle},
    dateOfBirth: dateOfBirth ?? DateTime(2000, 1, 1),
    heightCm: heightCm,
    currentWeightKg: currentWeightKg,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

void main() {
  const calculator = CalculateProfileHealthMetrics();

  group('CalculateProfileHealthMetrics', () {
    test('age changes only when the birthday is reached', () {
      final profile = _profile(dateOfBirth: DateTime(2000, 8, 25));

      expect(
        calculator.call(profile, now: DateTime(2026, 8, 24)).ageYears,
        25,
      );
      expect(
        calculator.call(profile, now: DateTime(2026, 8, 25)).ageYears,
        26,
      );
    });

    test('BMI keeps the existing one-decimal display precision', () {
      final metrics = calculator.call(
        _profile(),
        now: DateTime(2026, 8, 25),
      );

      expect(metrics.bmi, 23.1);
    });

    test('BMR preserves male female and other gender adjustments', () {
      final now = DateTime(2026, 8, 25);

      expect(
        calculator.call(_profile(gender: ProfileGender.male), now: now).bmrKcal,
        1750,
      );
      expect(
        calculator
            .call(_profile(gender: ProfileGender.female), now: now)
            .bmrKcal,
        1584,
      );
      expect(
        calculator
            .call(_profile(gender: ProfileGender.other), now: now)
            .bmrKcal,
        1667,
      );
    });

    test('non-positive dimensions keep BMI and BMR unavailable', () {
      final zeroWeight = calculator.call(
        _profile(currentWeightKg: 0),
        now: DateTime(2026, 8, 25),
      );
      final zeroHeight = calculator.call(
        _profile(heightCm: 0),
        now: DateTime(2026, 8, 25),
      );

      expect(zeroWeight.ageYears, 26);
      expect(zeroWeight.bmi, isNull);
      expect(zeroWeight.bmrKcal, isNull);
      expect(zeroHeight.ageYears, 26);
      expect(zeroHeight.bmi, isNull);
      expect(zeroHeight.bmrKcal, isNull);
    });
  });
}
