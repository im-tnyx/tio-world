import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('TargetsFlowPlan', () {
    const plan = TargetsFlowPlan();

    test('defines 5 active ordered steps with Goal Pace removed', () {
      expect(plan.stepCount, 5);
      expect(TargetsFlowPlan.orderedSteps, const [
        TargetStepId.bridge,
        TargetStepId.stepTarget,
        TargetStepId.sleepTarget,
        TargetStepId.waterTarget,
        TargetStepId.nutritionTarget,
      ]);
      expect(plan.contains(TargetStepId.goalPace), isFalse);
    });

    test('retains legacy Goal Pace order only for resume interpretation', () {
      expect(TargetsFlowPlan.legacyOrderedSteps, const [
        TargetStepId.bridge,
        TargetStepId.stepTarget,
        TargetStepId.sleepTarget,
        TargetStepId.waterTarget,
        TargetStepId.goalPace,
        TargetStepId.nutritionTarget,
      ]);
    });

    test('identifies first and last active steps correctly', () {
      expect(plan.isFirst(TargetStepId.bridge), isTrue);
      expect(plan.isFirst(TargetStepId.stepTarget), isFalse);
      expect(plan.isLast(TargetStepId.nutritionTarget), isTrue);
      expect(plan.isLast(TargetStepId.goalPace), isFalse);
    });

    test('advances directly from Water Target to Nutrition Target', () {
      expect(plan.next(TargetStepId.bridge), TargetStepId.stepTarget);
      expect(plan.next(TargetStepId.stepTarget), TargetStepId.sleepTarget);
      expect(plan.next(TargetStepId.sleepTarget), TargetStepId.waterTarget);
      expect(plan.next(TargetStepId.waterTarget), TargetStepId.nutritionTarget);
      expect(plan.next(TargetStepId.nutritionTarget), isNull);
      expect(plan.next(TargetStepId.goalPace), isNull);
    });

    test('Back from Nutrition Target returns directly to Water Target', () {
      expect(plan.previous(TargetStepId.bridge), isNull);
      expect(plan.previous(TargetStepId.stepTarget), TargetStepId.bridge);
      expect(plan.previous(TargetStepId.sleepTarget), TargetStepId.stepTarget);
      expect(plan.previous(TargetStepId.waterTarget), TargetStepId.sleepTarget);
      expect(plan.previous(TargetStepId.nutritionTarget), TargetStepId.waterTarget);
      expect(plan.previous(TargetStepId.goalPace), isNull);
    });

    test('derives correct primary action labels for active steps', () {
      expect(plan.primaryActionLabel(TargetStepId.bridge), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.stepTarget), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.sleepTarget), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.waterTarget), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.nutritionTarget), 'Review');
    });
  });
}
