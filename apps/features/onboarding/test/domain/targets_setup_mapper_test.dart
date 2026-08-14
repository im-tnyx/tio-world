import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/src/domain/domain.dart';

void main() {
  const mapper = TargetsSetupMapper();

  group('TargetsSetupMapper', () {
    test('maps valid TargetsOnboardingDraft and profile to TargetsSetupData', () {
      const targetsDraft = TargetsOnboardingDraft(
        dailySteps: 10000,
        sleepTargetMinutes: 480,
        sleepTimeMinutes: 1320,
        wakeTimeMinutes: 360,
        waterMl: 3000,
        goalPaceKgPerWeek: 0.5,
      );

      final profileDraft = ProfileOnboardingDraft(
        name: 'Tio User',
        gender: ProfileGender.male,
        goals: const {ProfileGoal.keepFit},
        dateOfBirth: DateTime(1996, 1, 1),
        heightCm: 175,
        currentWeightKg: 70,
        activityLevel: ProfileActivityLevel.active,
      );

      final result = mapper.map(
        targetsDraft: targetsDraft,
        profileDraft: profileDraft,
      );

      expect(result.dailySteps, 10000);
      expect(result.sleepTargetMinutes, 480);
      expect(result.waterMl, 3000);
      expect(result.goalPaceKgPerWeek, 0.5);
      expect(result.recommendation, isNotNull);
      expect(result.recommendation?.caloriesKcal, greaterThan(0));
    });

    test('throws FormatException when steps or water are out of bounds', () {
      const targetsDraft = TargetsOnboardingDraft(
        dailySteps: 1000, // min is 2000
      );

      final profileDraft = ProfileOnboardingDraft();

      expect(
        () => mapper.map(
          targetsDraft: targetsDraft,
          profileDraft: profileDraft,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
