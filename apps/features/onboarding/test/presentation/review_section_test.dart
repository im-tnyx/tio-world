import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('review section renders real summary data and blockers',
      (tester) async {
    final draft = OnboardingDraft(
      selectedMode: AppMode.hybrid,
      currentStepId: OnboardingStepId.review,
      workoutIntroChoice: WorkoutIntroChoice.later,
      profile: _validProfile(),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.later,
    );
    final state = OnboardingState(
      draft: draft,
      flowPlan: flowPlan,
      workoutFlowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
          WorkoutStepId.healthConcerns,
          WorkoutStepId.specialEvent,
        ],
      ),
      stepId: OnboardingStepId.review,
      completionEligibility: const OnboardingCompletionValidator().evaluate(
        draft: draft,
        flowPlan: flowPlan,
      ),
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

    expect(find.byType(ReviewSection), findsOneWidget);
    expect(find.text('Review setup'), findsOneWidget);
    expect(find.text('App Mode'), findsOneWidget);
    expect(find.text('Hybrid'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Tio User'), findsOneWidget);
    expect(find.text('Keep fit'), findsOneWidget);
    expect(find.text('Dynamic'), findsOneWidget);
    expect(find.text('Health detail provided'), findsOneWidget);
    expect(find.text('Daily Targets'), findsOneWidget);
    expect(find.text('10000 steps/day'), findsOneWidget);
    expect(find.text('2500 ml/day'), findsOneWidget);
    expect(find.textContaining('Only real onboarding data is summarized here'),
        findsOneWidget);
    expect(
      find.textContaining('Finish stays disabled until durable owner persistence'),
      findsOneWidget,
    );
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Workout setup'), findsWidgets);
    expect(find.text('Nutrition setup'), findsNothing);
    expect(find.text('Nutrition preferences'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('review section rejects non-review steps', (tester) async {
    final state = OnboardingState(
      draft: OnboardingDraft(selectedMode: AppMode.workout),
      flowPlan: const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        workoutIntroChoice: null,
      ),
      workoutFlowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
          WorkoutStepId.healthConcerns,
          WorkoutStepId.specialEvent,
        ],
      ),
      stepId: OnboardingStepId.mode,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TioTheme(
          child: Scaffold(
            body: ReviewSection(state: state),
          ),
        ),
      ),
    );
    await tester.pump();

    final exception = tester.takeException();
    expect(exception, isA<StateError>());
    expect(
      exception.toString(),
      contains('ReviewSection can only render the review step.'),
    );
  });
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    currentStepId: ProfileStepId.healthConditions,
    name: 'Tio User',
    gender: ProfileGender.other,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 68,
    activityLevel: ProfileActivityLevel.dynamic,
    healthConditions: const {ProfileHealthCondition.other},
    otherHealthCondition: 'Asthma note',
  );
}
