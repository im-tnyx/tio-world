import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('TargetsFlowPlan', () {
    const plan = TargetsFlowPlan();

    test('defines Nutrition Target as the only active Targets child', () {
      expect(plan.stepCount, 1);
      expect(
        TargetsFlowPlan.orderedSteps,
        const [TargetStepId.nutritionTarget],
      );
      expect(plan.contains(TargetStepId.bridge), isFalse);
      expect(plan.contains(TargetStepId.stepTarget), isFalse);
      expect(plan.contains(TargetStepId.sleepTarget), isFalse);
      expect(plan.contains(TargetStepId.waterTarget), isFalse);
      expect(plan.contains(TargetStepId.goalPace), isFalse);
    });

    test('retains the full legacy order only for resume interpretation', () {
      expect(TargetsFlowPlan.legacyOrderedSteps, const [
        TargetStepId.bridge,
        TargetStepId.stepTarget,
        TargetStepId.sleepTarget,
        TargetStepId.waterTarget,
        TargetStepId.goalPace,
        TargetStepId.nutritionTarget,
      ]);
    });

    test('Nutrition Target is both first and last active child', () {
      expect(plan.isFirst(TargetStepId.nutritionTarget), isTrue);
      expect(plan.isLast(TargetStepId.nutritionTarget), isTrue);
      expect(plan.isFirst(TargetStepId.bridge), isFalse);
      expect(plan.isLast(TargetStepId.waterTarget), isFalse);
    });

    test('active Targets has no nested next or previous child', () {
      expect(plan.next(TargetStepId.nutritionTarget), isNull);
      expect(plan.previous(TargetStepId.nutritionTarget), isNull);
      expect(plan.next(TargetStepId.waterTarget), isNull);
      expect(plan.previous(TargetStepId.bridge), isNull);
    });

    test('Nutrition Target action advances to Review', () {
      expect(plan.primaryActionLabel(TargetStepId.nutritionTarget), 'Review');
    });
  });
}
