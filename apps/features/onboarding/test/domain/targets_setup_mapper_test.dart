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
        targetWeightKg: 66,
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
      expect(result.heightCm, 175);
      expect(result.currentWeightKg, 70);
      expect(result.targetWeightKg, 66);
      expect(result.activityLevel, 'active');
      expect(result.recommendation, isNotNull);
      expect(result.recommendation?.caloriesKcal, greaterThan(0));
    });

    test('keeps uncollected optional profile metrics null', () {
      const targetsDraft = TargetsOnboardingDraft();
      final profileDraft = ProfileOnboardingDraft();

      final result = mapper.map(
        targetsDraft: targetsDraft,
        profileDraft: profileDraft,
      );

      expect(result.heightCm, isNull);
      expect(result.currentWeightKg, isNull);
      expect(result.targetWeightKg, isNull);
      expect(result.activityLevel, isNull);
    });

    test('safely clamps steps and water to bounds', () {
      const targetsDraft = TargetsOnboardingDraft(
        dailySteps: 500, // below 1000
        waterMl: 20000, // above 15000
      );

      final profileDraft = ProfileOnboardingDraft();

      final result = mapper.map(
        targetsDraft: targetsDraft,
        profileDraft: profileDraft,
      );

      expect(result.dailySteps, 1000);
      expect(result.waterMl, 15000);
    });
  });
}
