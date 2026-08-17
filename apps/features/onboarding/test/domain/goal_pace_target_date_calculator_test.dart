import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('GoalPaceTargetDateCalculator', () {
    final fixedNow = DateTime(2026, 8, 14);

    test('calculates deterministic date for weight loss', () {
      // 80kg -> 75kg = 5kg diff. Pace 0.5 kg/week => 10 weeks = 70 days.
      final targetDate = GoalPaceTargetDateCalculator.calculateTargetDate(
        currentWeightKg: 80.0,
        targetWeightKg: 75.0,
        paceKgPerWeek: 0.5,
        now: fixedNow,
      );

      expect(targetDate, equals(DateTime(2026, 8, 14).add(const Duration(days: 70))));
      expect(targetDate.month, equals(10));
      expect(targetDate.day, equals(23));
    });

    test('calculates deterministic date for weight gain', () {
      // 60kg -> 63kg = 3kg diff. Pace 0.5 kg/week => 6 weeks = 42 days.
      final days = GoalPaceTargetDateCalculator.calculateDaysNeeded(
        currentWeightKg: 60.0,
        targetWeightKg: 63.0,
        paceKgPerWeek: 0.5,
      );
      expect(days, equals(42));

      final targetDate = GoalPaceTargetDateCalculator.calculateTargetDate(
        currentWeightKg: 60.0,
        targetWeightKg: 63.0,
        paceKgPerWeek: 0.5,
        now: fixedNow,
      );
      expect(targetDate, equals(fixedNow.add(const Duration(days: 42))));
    });

    test('returns now when currentWeight equals targetWeight (maintenance)', () {
      final targetDate = GoalPaceTargetDateCalculator.calculateTargetDate(
        currentWeightKg: 70.0,
        targetWeightKg: 70.0,
        paceKgPerWeek: 0.5,
        now: fixedNow,
      );
      expect(targetDate, equals(DateTime(2026, 8, 14)));

      final days = GoalPaceTargetDateCalculator.calculateDaysNeeded(
        currentWeightKg: 70.0,
        targetWeightKg: 70.0,
        paceKgPerWeek: 0.5,
      );
      expect(days, equals(0));
    });

    test('returns now when pace is zero or negative', () {
      final targetDate = GoalPaceTargetDateCalculator.calculateTargetDate(
        currentWeightKg: 80.0,
        targetWeightKg: 70.0,
        paceKgPerWeek: 0.0,
        now: fixedNow,
      );
      expect(targetDate, equals(DateTime(2026, 8, 14)));
    });

    test('returns now when weights are null', () {
      final targetDate = GoalPaceTargetDateCalculator.calculateTargetDate(
        currentWeightKg: null,
        targetWeightKg: 70.0,
        paceKgPerWeek: 0.5,
        now: fixedNow,
      );
      expect(targetDate, equals(DateTime(2026, 8, 14)));
    });
  });
}
