import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('TargetsFlowPlan', () {
    const plan = TargetsFlowPlan();

    test('defines 6 ordered steps matching the specification', () {
      expect(plan.stepCount, 6);
      expect(TargetsFlowPlan.orderedSteps, [
        TargetStepId.bridge,
        TargetStepId.stepTarget,
        TargetStepId.sleepTarget,
        TargetStepId.waterTarget,
        TargetStepId.goalPace,
        TargetStepId.nutritionTarget,
      ]);
    });

    test('identifies first and last steps correctly', () {
      expect(plan.isFirst(TargetStepId.bridge), isTrue);
      expect(plan.isFirst(TargetStepId.stepTarget), isFalse);

      expect(plan.isLast(TargetStepId.nutritionTarget), isTrue);
      expect(plan.isLast(TargetStepId.goalPace), isFalse);
    });

    test('advances through next steps in order', () {
      expect(plan.next(TargetStepId.bridge), TargetStepId.stepTarget);
      expect(plan.next(TargetStepId.stepTarget), TargetStepId.sleepTarget);
      expect(plan.next(TargetStepId.sleepTarget), TargetStepId.waterTarget);
      expect(plan.next(TargetStepId.waterTarget), TargetStepId.goalPace);
      expect(plan.next(TargetStepId.goalPace), TargetStepId.nutritionTarget);
      expect(plan.next(TargetStepId.nutritionTarget), isNull);
    });

    test('retreats through previous steps in order', () {
      expect(plan.previous(TargetStepId.bridge), isNull);
      expect(plan.previous(TargetStepId.stepTarget), TargetStepId.bridge);
      expect(plan.previous(TargetStepId.sleepTarget), TargetStepId.stepTarget);
      expect(plan.previous(TargetStepId.waterTarget), TargetStepId.sleepTarget);
      expect(plan.previous(TargetStepId.goalPace), TargetStepId.waterTarget);
      expect(plan.previous(TargetStepId.nutritionTarget), TargetStepId.goalPace);
    });

    test('derives correct primary action labels', () {
      expect(plan.primaryActionLabel(TargetStepId.bridge), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.stepTarget), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.sleepTarget), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.waterTarget), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.goalPace), 'Continue');
      expect(plan.primaryActionLabel(TargetStepId.nutritionTarget), 'Review');
    });
  });
}
