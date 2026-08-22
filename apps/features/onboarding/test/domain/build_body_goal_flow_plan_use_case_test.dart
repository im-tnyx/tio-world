import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('BuildBodyGoalFlowPlanUseCase', () {
    const builder = BuildBodyGoalFlowPlanUseCase();

    test('nutrition loss includes Target Weight and Goal Pace in Body Goal', () {
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
          ProfileStepId.goalPace,
        ],
      );
    });

    test('non-directional nutrition goal skips both weight follow-ups', () {
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

    test('training-only workout goal invents neither Target Weight nor Goal Pace', () {
      final plan = builder(
        mode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
      );

      expect(plan.contains(ProfileStepId.targetWeight), isFalse);
      expect(plan.contains(ProfileStepId.goalPace), isFalse);
    });

    test('hybrid supporting loss keeps both directional follow-ups', () {
      final plan = builder(
        mode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.loseWeight,
        ),
      );

      expect(plan.contains(ProfileStepId.targetWeight), isTrue);
      expect(plan.contains(ProfileStepId.goalPace), isTrue);
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
          currentStepId: ProfileStepId.goalPace,
          previousPlan: previous,
          nextPlan: next,
        ),
        ProfileStepId.goalPace,
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

    test('reconcile clamps removed Goal Pace through removed Target Weight', () {
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
          currentStepId: ProfileStepId.goalPace,
          previousPlan: previous,
          nextPlan: next,
        ),
        ProfileStepId.currentWeight,
      );
    });
  });
}
