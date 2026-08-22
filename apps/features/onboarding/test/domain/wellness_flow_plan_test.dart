import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('WellnessFlowPlan', () {
    const plan = WellnessFlowPlan();

    test('owns the four active Wellness-facing target screens', () {
      expect(plan.stepCount, 4);
      expect(WellnessFlowPlan.orderedSteps, const [
        TargetStepId.bridge,
        TargetStepId.stepTarget,
        TargetStepId.sleepTarget,
        TargetStepId.waterTarget,
      ]);
      expect(plan.contains(TargetStepId.goalPace), isFalse);
      expect(plan.contains(TargetStepId.nutritionTarget), isFalse);
    });

    test('navigates Bridge to Water in exact order', () {
      expect(plan.next(TargetStepId.bridge), TargetStepId.stepTarget);
      expect(plan.next(TargetStepId.stepTarget), TargetStepId.sleepTarget);
      expect(plan.next(TargetStepId.sleepTarget), TargetStepId.waterTarget);
      expect(plan.next(TargetStepId.waterTarget), isNull);

      expect(plan.previous(TargetStepId.bridge), isNull);
      expect(plan.previous(TargetStepId.stepTarget), TargetStepId.bridge);
      expect(plan.previous(TargetStepId.sleepTarget), TargetStepId.stepTarget);
      expect(plan.previous(TargetStepId.waterTarget), TargetStepId.sleepTarget);
    });

    test('reconciles an invalid legacy child to the nearest Wellness child', () {
      const useCase = BuildWellnessFlowPlanUseCase();
      expect(
        useCase.reconcileCurrentStep(
          currentStepId: TargetStepId.nutritionTarget,
          previousPlan: WellnessFlowPlan(
            steps: TargetsFlowPlan.legacyOrderedSteps,
          ),
          nextPlan: plan,
        ),
        TargetStepId.waterTarget,
      );
    });
  });
}
