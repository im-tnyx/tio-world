import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('BuildBodyGoalFlowPlanUseCase', () {
    const builder = BuildBodyGoalFlowPlanUseCase();

    test('nutrition loss includes Goal, Current Weight, and Target Weight', () {
      final plan = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
      );

      expect(
        plan.steps,
        const [
          ProfileStepId.goal,
          ProfileStepId.currentWeight,
          ProfileStepId.targetWeight,
        ],
      );
    });

    test('non-directional nutrition goal skips Target Weight', () {
      final plan = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
      );

      expect(
        plan.steps,
        const [
          ProfileStepId.goal,
          ProfileStepId.currentWeight,
        ],
      );
    });

    test('training-only workout goal does not invent Target Weight', () {
      final plan = builder(
        mode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
      );

      expect(plan.contains(ProfileStepId.targetWeight), isFalse);
    });

    test('hybrid supporting loss keeps directional Target Weight', () {
      final plan = builder(
        mode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.loseWeight,
        ),
      );

      expect(plan.contains(ProfileStepId.targetWeight), isTrue);
    });

    test('reconcile preserves an eligible current child', () {
      final previous = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
      );
      final next = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.gainWeight,
        ),
      );

      expect(
        builder.reconcileCurrentStep(
          currentStepId: ProfileStepId.currentWeight,
          previousPlan: previous,
          nextPlan: next,
        ),
        ProfileStepId.currentWeight,
      );
    });

    test('reconcile clamps removed Target Weight to Current Weight', () {
      final previous = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
      );
      final next = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
      );

      expect(
        builder.reconcileCurrentStep(
          currentStepId: ProfileStepId.targetWeight,
          previousPlan: previous,
          nextPlan: next,
        ),
        ProfileStepId.currentWeight,
      );
    });
  });
}
