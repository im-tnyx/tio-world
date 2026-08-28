import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('review section renders active unified goals and weight intent',
      (tester) async {
    final draft = OnboardingDraft(
      selectedMode: AppMode.hybrid,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.improveEndurance,
      ),
      currentStepId: OnboardingStepId.review,
      workoutIntroChoice: WorkoutIntroChoice.later,
      profile: _validProfile(),
      targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
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
    expect(find.text('Review your plan'), findsOneWidget);
    expect(find.text('Profile & Goals'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Tio User'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Lose weight, Improve endurance'), findsOneWidget);
    expect(find.text('Keep fit'), findsNothing);
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('1 Jan 2000'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('171 cm'), findsOneWidget);
    expect(find.text('Weight plan'), findsOneWidget);
    expect(find.text('70.0 kg ➔ 68.0 kg'), findsOneWidget);
    expect(find.text('Goal pace'), findsOneWidget);
    expect(find.text('0.5 kg / week'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Highly dynamic'), findsOneWidget);
    expect(find.text('Health info'), findsOneWidget);
    expect(find.text('Asthma note'), findsOneWidget);
    expect(find.text('Daily Targets'), findsOneWidget);
    expect(find.text('10000 steps/day'), findsOneWidget);
    expect(find.text('2500 ml/day'), findsOneWidget);
    expect(find.text('8h 00m / night'), findsOneWidget);
    expect(find.text('Setup Incomplete'), findsOneWidget);
    expect(
      find.textContaining(
          'Finish stays disabled until durable owner persistence'),
      findsOneWidget,
    );
    expect(find.text('Workout Plan'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('review hides dormant target and skipped default goal pace',
      (tester) async {
    final draft = OnboardingDraft(
      selectedMode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile(),
      targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.nutrition,
      workoutIntroChoice: null,
    );
    final state = OnboardingState(
      draft: draft,
      flowPlan: flowPlan,
      workoutFlowPlan: const WorkoutFlowPlan(steps: []),
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

    expect(find.text('Maintain weight'), findsOneWidget);
    expect(find.text('Keep fit'), findsNothing);
    expect(find.text('70.0 kg'), findsOneWidget);
    expect(find.text('70.0 kg ➔ 68.0 kg'), findsNothing);
    expect(find.text('Goal pace'), findsNothing);
    expect(find.text('0.5 kg / week'), findsNothing);
  });

  testWidgets(
      'review displays Health info: Other when only Other is selected with blank detail',
      (tester) async {
    final draft = OnboardingDraft(
      selectedMode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile().copyWith(
        gender: ProfileGender.female,
        healthConditions: const {ProfileHealthCondition.other},
        otherHealthCondition: '   ',
      ),
      targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.nutrition,
      workoutIntroChoice: null,
    );
    final state = OnboardingState(
      draft: draft,
      flowPlan: flowPlan,
      workoutFlowPlan: const WorkoutFlowPlan(steps: []),
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

    expect(find.text('Review your plan'), findsOneWidget);
    expect(find.text('Health info'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('other'), findsNothing);
  });

  testWidgets(
      'review displays entered custom health condition text when Other is non-empty',
      (tester) async {
    final draft = OnboardingDraft(
      selectedMode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile().copyWith(
        healthConditions: const {ProfileHealthCondition.other},
        otherHealthCondition: '  Asthma  ',
      ),
      targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.nutrition,
      workoutIntroChoice: null,
    );
    final state = OnboardingState(
      draft: draft,
      flowPlan: flowPlan,
      workoutFlowPlan: const WorkoutFlowPlan(steps: []),
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

    expect(find.text('Health info'), findsOneWidget);
    expect(find.text('Asthma'), findsOneWidget);
    expect(find.text('other'), findsNothing);
  });

  testWidgets(
      'review displays both valid condition and Other when Other detail is blank',
      (tester) async {
    final draft = OnboardingDraft(
      selectedMode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile().copyWith(
        healthConditions: const {
          ProfileHealthCondition.diabetes,
          ProfileHealthCondition.other,
        },
        otherHealthCondition: '',
      ),
      targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.nutrition,
      workoutIntroChoice: null,
    );
    final state = OnboardingState(
      draft: draft,
      flowPlan: flowPlan,
      workoutFlowPlan: const WorkoutFlowPlan(steps: []),
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

    expect(find.text('Health info'), findsOneWidget);
    expect(find.text('Diabetes, Other'), findsOneWidget);
    expect(find.text('other'), findsNothing);
  });

  testWidgets(
      'review displays valid condition and described Other when detail is entered',
      (tester) async {
    final draft = OnboardingDraft(
      selectedMode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile().copyWith(
        healthConditions: const {
          ProfileHealthCondition.diabetes,
          ProfileHealthCondition.other,
        },
        otherHealthCondition: 'Asthma',
      ),
      targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.nutrition,
      workoutIntroChoice: null,
    );
    final state = OnboardingState(
      draft: draft,
      flowPlan: flowPlan,
      workoutFlowPlan: const WorkoutFlowPlan(steps: []),
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

    expect(find.text('Health info'), findsOneWidget);
    expect(find.text('Diabetes, Asthma'), findsOneWidget);
    expect(find.text('other'), findsNothing);
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
    targetWeightDirection: GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.dynamic,
    healthConditions: const {ProfileHealthCondition.other},
    otherHealthCondition: 'Asthma note',
  );
}
