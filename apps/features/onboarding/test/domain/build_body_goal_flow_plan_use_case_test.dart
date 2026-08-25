import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('BuildBodyGoalFlowPlanUseCase', () {
    const builder = BuildBodyGoalFlowPlanUseCase();

    test('nutrition loss includes Target Weight and Goal Pace after Current Weight and Goal', () {
      final plan = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
      );

      expect(
        plan.steps,
        const [
          ProfileStepId.currentWeight,
          ProfileStepId.goal,
          ProfileStepId.targetWeight,
          ProfileStepId.goalPace,
        ],
      );
    });

    test('Maintain Weight skips both weight follow-ups', () {
      final plan = builder(
        mode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
      );

      expect(
        plan.steps,
        const [ProfileStepId.currentWeight, ProfileStepId.goal],
      );
    });

    test('training-only workout goal collects Target Weight and Goal Pace', () {
      final plan = builder(
        mode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
      );

      expect(
        plan.steps,
        const [
          ProfileStepId.currentWeight,
          ProfileStepId.goal,
          ProfileStepId.targetWeight,
          ProfileStepId.goalPace,
        ],
      );
    });

    test('Maintain plus training remains non-directional without schema change', () {
      final plan = builder(
        mode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
          supportingGoal: GoalIntent.buildMuscle,
        ),
      );

      expect(plan.contains(ProfileStepId.targetWeight), isFalse);
      expect(plan.contains(ProfileStepId.goalPace), isFalse);
    });

    test('hybrid explicit loss with two training goals keeps both follow-ups', () {
      final plan = builder(
        mode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.getStronger,
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

    test('reconcile clamps removed Target Weight to Goal', () {
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
        ProfileStepId.goal,
      );
    });

    test('reconcile clamps removed Goal Pace through removed Target Weight to Goal', () {
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
        ProfileStepId.goal,
      );
    });
  });
}
