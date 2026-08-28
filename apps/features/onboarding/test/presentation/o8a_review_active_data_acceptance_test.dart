import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O8A Review active-data mode matrix', () {
    testWidgets('Workout Review shows active Workout Plan data only',
        (tester) async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        currentStepId: OnboardingStepId.review,
        profile: _validProfile(),
        workout: _seededWorkout(),
        targets: const TargetsOnboardingDraft(
          dailySteps: 12345,
          waterMl: 3456,
          sleepTargetMinutes: 510,
        ),
      );

      await _pumpReview(tester, draft);

      expect(find.text('Workout Plan'), findsOneWidget);
      expect(find.text('Commercial gym'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('Daily Targets'), findsNothing);
      expect(find.text('Steps'), findsNothing);
      expect(find.text('Hydration'), findsNothing);
      expect(find.text('Sleep'), findsNothing);
      expect(find.text('Target calories'), findsNothing);
    });

    testWidgets('Nutrition Review hides preserved dormant Workout data',
        (tester) async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.review,
        profile: _validProfile(),
        workout: _seededWorkout(),
      );

      expect(draft.workout.gymAccess, WorkoutGymAccess.gym);
      expect(draft.workout.workoutDuration, WorkoutDuration.sixtyMinutes);

      await _pumpReview(tester, draft);

      expect(find.text('Workout Plan'), findsNothing);
      expect(find.text('Commercial gym'), findsNothing);
      expect(find.text('60 min'), findsNothing);
      expect(find.text('Daily Targets'), findsOneWidget);
    });

    testWidgets('Hybrid setupNow Review shows active Workout Plan data',
        (tester) async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.improveEndurance,
        ),
        currentStepId: OnboardingStepId.review,
        profile: _validProfile(),
        workout: _seededWorkout(),
      );

      await _pumpReview(tester, draft);

      expect(find.text('Workout Plan'), findsOneWidget);
      expect(find.text('Commercial gym'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('Daily Targets'), findsOneWidget);
    });

    testWidgets('Hybrid later Review hides preserved dormant Workout data',
        (tester) async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.improveEndurance,
        ),
        currentStepId: OnboardingStepId.review,
        profile: _validProfile(),
        workout: _seededWorkout(),
      );

      expect(draft.workout.gymAccess, WorkoutGymAccess.gym);
      expect(draft.workout.workoutDuration, WorkoutDuration.sixtyMinutes);

      await _pumpReview(tester, draft);

      expect(find.text('Workout Plan'), findsNothing);
      expect(find.text('Commercial gym'), findsNothing);
      expect(find.text('60 min'), findsNothing);
      expect(find.text('Daily Targets'), findsOneWidget);
    });
  });
}

Future<void> _pumpReview(WidgetTester tester, OnboardingDraft draft) async {
  final flowPlan = const BuildOnboardingFlowUseCase()(
    entryPath: OnboardingEntryPath.firstRun,
    mode: draft.selectedMode,
    workoutIntroChoice: draft.workoutIntroChoice,
  );
  final workoutFlowPlan = const BuildWorkoutFlowPlanUseCase()(
    gymAccess: draft.workout.gymAccess,
  );
  final state = OnboardingState(
    draft: draft,
    flowPlan: flowPlan,
    workoutFlowPlan: workoutFlowPlan,
    stepId: OnboardingStepId.review,
    completionEligibility: OnboardingCompletionEligibility.eligible,
    completedStepIds: draft.completedStepIds,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: TioTheme(
        child: Scaffold(
          body: SingleChildScrollView(
            child: ReviewSection(state: state),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    name: 'Tio User',
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _seededWorkout() {
  return const WorkoutOnboardingDraft(
    gymAccess: WorkoutGymAccess.gym,
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.fullBody,
    focusAreas: {WorkoutFocusArea.fullBody},
  );
}
