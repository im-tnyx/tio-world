import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('keeps parent regions fixed while Profile child content changes',
      (tester) async {
    await _pumpFlow(
      tester,
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(name: 'Tio User'),
      ),
      stepBuilder: _buildProfileAwarePlaceholder,
    );

    expect(find.text('Set up Tio'), findsNothing);
    expect(find.byType(OnboardingTopBar), findsOneWidget);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);
    expect(find.text('Profile name'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Set up Tio'), findsNothing);
    expect(find.byType(OnboardingTopBar), findsOneWidget);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);
    expect(find.text('Profile gender'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OnboardingBottomBar),
        matching: find.text('Back'),
      ),
      findsNothing,
    );
  });

  testWidgets('parent rebuild keeps the active nested step and controller',
      (tester) async {
    late StateSetter rebuildParent;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return OnboardingFlowPage(
                seed: OnboardingControllerSeed(
                  entryPath: OnboardingEntryPath.firstRun,
                  draft: OnboardingDraft(
                    selectedMode: AppMode.workout,
                    currentStepId: OnboardingStepId.profileBasics,
                    profile: ProfileOnboardingDraft(name: 'Tio User'),
                  ),
                ),
                onFinishRequested: (_) async {},
                stepBuilder: _buildProfileAwarePlaceholder,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Profile gender'), findsOneWidget);

    rebuildParent(() {});
    await tester.pump();

    expect(find.text('Profile gender'), findsOneWidget);
  });

  testWidgets('seeded Product Onboarding starts at Profile with progress',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpFlow(tester);

      expect(find.text('Child profileBasics'), findsOneWidget);
      expect(find.byType(OnboardingTopBar), findsOneWidget);
      expect(find.byType(OnboardingProgressIndicator), findsOneWidget);
      expect(
        find.bySemanticsLabel('Step 1 of 21, About you'),
        findsOneWidget,
      );
      expect(find.byType(AppModeScreen), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('real workout intro continues to Wellness when deferred',
      (tester) async {
    await _pumpFlow(
      tester,
      draft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        currentStepId: OnboardingStepId.workoutIntro,
        profile: _validProfile(),
      ),
      useDefaultRenderer: true,
    );

    expect(find.byType(WorkoutIntroSection), findsOneWidget);
    expect(find.byType(WorkoutIntroScreen), findsOneWidget);
    expect(find.text('Create your workout plan?'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);

    await tester.tap(find.byKey(const ValueKey('workout-intro-later')));
    await tester.pumpAndSettle();
    expect(
      find.text('Next, Tio will continue directly to nutrition setup.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutIntroSection), findsNothing);
    expect(find.byType(WellnessSection), findsOneWidget);
    expect(find.byType(BridgeScreen), findsOneWidget);
    expect(find.byType(NutritionGoalsSection), findsNothing);
    expect(find.byType(TargetsSection), findsNothing);
    expect(find.byType(NutritionTargetScreen), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutIntroScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workout-intro-later')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('default renderer uses Nutrition Goals in nutrition mode',
      (tester) async {
    await _pumpFlow(
      tester,
      draft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.nutritionGoals,
        profile: _validProfile(),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.nutritionTarget,
        ),
      ),
      useDefaultRenderer: true,
    );

    expect(find.byType(OnboardingSectionRenderer), findsOneWidget);
    expect(find.byType(NutritionGoalsSection), findsOneWidget);
    expect(find.byType(TargetsSection), findsNothing);
    expect(find.byType(WellnessSection), findsNothing);
    expect(find.byType(BridgeScreen), findsNothing);
    expect(find.byType(NutritionTargetScreen), findsOneWidget);
  });

  testWidgets('system back uses the same nested Profile previous transition',
      (tester) async {
    await _pumpFlow(
      tester,
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.gender,
          name: 'Tio User',
        ),
      ),
      stepBuilder: _buildProfileAwarePlaceholder,
    );
    expect(find.text('Profile gender'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Profile name'), findsOneWidget);
  });

  testWidgets('visible top-bar Back uses the nested Profile transition',
      (tester) async {
    await _pumpFlow(
      tester,
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.gender,
          name: 'Tio User',
        ),
      ),
      stepBuilder: _buildProfileAwarePlaceholder,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Profile name'), findsOneWidget);
  });

  testWidgets('busy completion blocks visible and system Back', (tester) async {
    final completion = Completer<void>();
    var exits = 0;
    await _pumpFlow(
      tester,
      onExitRequested: () async => exits++,
      onFinishRequested: (_) => completion.future,
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.review,
        profile: _validProfile(),
        workout: _validWorkout(),
        completedStepIds: const {
          OnboardingStepId.profileBasics,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
          OnboardingStepId.healthConnections,
        },
      ),
      controllerFactory: (seed) => OnboardingController(
        entryPath: seed.entryPath,
        initialDraft: seed.draft,
        completionValidator: const _AlwaysEligibleValidator(),
      ),
    );

    await tester.tap(find.text('Finish'));
    await tester.pump();

    expect(find.text('Finishing'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byType(OnboardingTopBar),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Child review'), findsOneWidget);
    expect(find.text('Finishing'), findsOneWidget);
    expect(exits, 0);

    completion.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('root system back requires confirmation before explicit exit',
      (tester) async {
    var exits = 0;
    await _pumpFlow(
      tester,
      onExitRequested: () async => exits++,
    );

    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TioConfirmationCard), findsOneWidget);
    expect(exits, 0);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(exits, 1);
  });

  testWidgets('reduced motion removes child transition duration',
      (tester) async {
    await _pumpFlow(
      tester,
      config: const TioThemeConfig(reducedMotion: true),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byType(OnboardingContentHost),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(switcher.duration, Duration.zero);

    final progressAnimation = tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: find.byType(OnboardingProgressIndicator),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    );
    expect(progressAnimation.duration, Duration.zero);
  });

  testWidgets('content transition matches the Android fade-through timing',
      (tester) async {
    await _pumpFlow(tester);

    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byType(OnboardingContentHost),
        matching: find.byType(AnimatedSwitcher),
      ),
    );

    expect(
      switcher.duration,
      const Duration(milliseconds: TioMotion.fadeThroughEnterMs),
    );
    expect(
      switcher.reverseDuration,
      const Duration(milliseconds: TioMotion.fadeThroughExitMs),
    );

    final transition = switcher.transitionBuilder(
      const SizedBox.shrink(),
      const AlwaysStoppedAnimation<double>(1),
    );
    expect(transition, isA<DualTransitionBuilder>());
    expect(
      find.descendant(
        of: find.byType(OnboardingContentHost),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('compact width and large text keep bottom actions reachable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpFlow(
      tester,
      textScaler: const TextScaler.linear(1.8),
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.gender,
          name: 'Tio User',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);
  });

  testWidgets('keyboard inset keeps the bottom action above the keyboard',
      (tester) async {
    addTearDown(tester.view.resetViewInsets);

    await _pumpFlow(
      tester,
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
      ),
      useDefaultRenderer: true,
    );

    final titleTopBefore =
        tester.getTopLeft(find.text('What should Tio call you?')).dy;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();

    final logicalHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final keyboardInset = 280 / tester.view.devicePixelRatio;
    final keyboardTop = logicalHeight - keyboardInset;
    final buttonBottom = tester.getBottomRight(find.byType(FilledButton)).dy;

    expect(buttonBottom, lessThanOrEqualTo(keyboardTop));
    expect(
      tester.getTopLeft(find.text('What should Tio call you?')).dy,
      titleTopBefore,
    );
  });

  testWidgets('progress animates smoothly across Profile to Body Goal',
      (tester) async {
    await _pumpFlow(
      tester,
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(),
      ),
    );

    double progressValue() => tester
        .widget<LinearProgressIndicator>(
          find.descendant(
            of: find.byType(OnboardingProgressIndicator),
            matching: find.byType(LinearProgressIndicator),
          ),
        )
        .value!;

    await tester.pumpAndSettle();
    expect(progressValue(), 7 / 21);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(progressValue(), 7 / 21);

    await tester.pump(const Duration(milliseconds: 125));
    expect(progressValue(), greaterThan(7 / 21));
    expect(progressValue(), lessThan(8 / 21));

    await tester.pumpAndSettle();
    expect(progressValue(), 8 / 21);
  });

  testWidgets('completion failure is announced as a live region',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpFlow(
        tester,
        onFinishRequested: (_) => Future<void>.error(
          Exception('Could not finish setup. Please try again.'),
        ),
        draft: OnboardingDraft(
          selectedMode: AppMode.workout,
          currentStepId: OnboardingStepId.review,
          profile: _validProfile(),
          workout: _validWorkout(),
          completedStepIds: const {
            OnboardingStepId.profileBasics,
            OnboardingStepId.workoutPreferences,
            OnboardingStepId.targets,
            OnboardingStepId.healthConnections,
          },
        ),
        controllerFactory: (seed) => OnboardingController(
          entryPath: seed.entryPath,
          initialDraft: seed.draft,
          completionValidator: const _AlwaysEligibleValidator(),
        ),
      );

      expect(find.text('Finish'), findsOneWidget);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.text('Could not finish setup. Please try again.'),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _pumpFlow(
  WidgetTester tester, {
  Future<void> Function()? onExitRequested,
  Future<void> Function(OnboardingDraft draft)? onFinishRequested,
  OnboardingDraft? draft,
  OnboardingController Function(OnboardingControllerSeed seed)?
      controllerFactory,
  OnboardingStepBuilder? stepBuilder,
  bool useDefaultRenderer = false,
  TioThemeConfig config = const TioThemeConfig(),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final overrides = <Override>[
    if (controllerFactory != null)
      onboardingControllerProvider.overrideWith(
        (ref, seed) => controllerFactory(seed),
      ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: TioTheme(
            config: config,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: OnboardingFlowPage(
          seed: OnboardingControllerSeed(
            entryPath: OnboardingEntryPath.firstRun,
            draft: draft ??
                OnboardingDraft(
                  selectedMode: AppMode.workout,
                  goalSelection: const GoalIntentSelection(
                    primaryGoal: GoalIntent.loseWeight,
                  ),
                  currentStepId: OnboardingStepId.profileBasics,
                  profile: ProfileOnboardingDraft(name: 'Tio User'),
                ),
          ),
          onExitRequested: onExitRequested,
          onFinishRequested: onFinishRequested ?? (_) async {},
          stepBuilder: useDefaultRenderer ? null : stepBuilder ?? _buildPlaceholder,
        ),
      ),
    ),
  );
  await tester.pump();
}

Widget _buildPlaceholder(
  BuildContext context,
  OnboardingState state,
  OnboardingController controller,
) {
  return Text('Child ${state.stepId.name}');
}

Widget _buildProfileAwarePlaceholder(
  BuildContext context,
  OnboardingState state,
  OnboardingController controller,
) {
  return Text('Profile ${state.draft.profile.currentStepId.name}');
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
    targetWeightKg: 65,
    targetWeightDirection: GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout() {
  return const WorkoutOnboardingDraft(
    currentStepId: WorkoutStepId.specialEvent,
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.beginner,
    focusAreas: {WorkoutFocusArea.fullBody},
    trainingDays: {WorkoutTrainingDay.monday},
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.fullBody,
  );
}

class _AlwaysEligibleValidator extends OnboardingCompletionValidator {
  const _AlwaysEligibleValidator();

  @override
  OnboardingCompletionEligibility evaluate({
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
  }) {
    return OnboardingCompletionEligibility.eligible;
  }
}
