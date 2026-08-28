import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('top bar contains only Back and one progress bar',
      (tester) async {
    await _pumpProfile(
      tester,
      onExitRequested: () async {},
    );

    final topBar = find.byType(OnboardingTopBar);
    expect(topBar, findsOneWidget);
    expect(
      find.descendant(of: topBar, matching: find.byType(IconButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: topBar,
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topBar, matching: find.byType(Text)),
      findsNothing,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    final material = tester.widget<Material>(
      find.descendant(of: topBar, matching: find.byType(Material)).first,
    );
    final padding = material.child! as Padding;
    expect(
      padding.padding,
      const EdgeInsets.fromLTRB(
        TioSpacing.sm,
        0.0,
        TioSpacing.lg,
        0.0,
      ),
    );

    final barHeight = padding.child! as SizedBox;
    expect(barHeight.height, 48);
    final row = barHeight.child! as Row;
    expect(row.children, hasLength(3));

    final progress = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: topBar,
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(progress.minHeight, 4);
    final progressAnimation = tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: topBar,
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    );
    expect(
      progressAnimation.duration,
      const Duration(milliseconds: TioMotion.progressMs),
    );

    final iconRect = tester.getRect(
      find.descendant(of: topBar, matching: find.byType(IconButton)),
    );
    final progressRect = tester.getRect(
      find.descendant(
        of: topBar,
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      progressRect.left - iconRect.right,
      closeTo(TioSpacing.sm, 0.001),
    );
    expect(
      screenWidth - progressRect.right,
      closeTo(TioSpacing.lg, 0.001),
    );
  });

  testWidgets('renders Name first, shows validation, and advances to Gender',
      (tester) async {
    final harness = await _pumpProfile(tester);

    expect(find.byType(ProfileSection), findsOneWidget);
    expect(find.text('What should Tio call you?'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-name-input')), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final nameField = tester.widget<TextField>(find.byType(TextField));
    expect(
      nameField.decoration?.errorText,
      'Enter at least 3 characters.',
    );

    await tester.enterText(find.byType(TextFormField), 'Tio User');
    await tester.pump();
    expect(harness.controller.state.draft.profile.name, 'Tio User');
    expect(harness.controller.state.validationErrors, isEmpty);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      harness.controller.state.draft.profile.currentStepId,
      ProfileStepId.gender,
    );
    expect(find.text('How do you describe your gender?'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('gender-female')),
    );
    await tester.pump();
    expect(harness.controller.state.draft.profile.gender, ProfileGender.female);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('What should Tio call you?'), findsOneWidget);
    expect(harness.controller.state.draft.profile.name, 'Tio User');
  });

  testWidgets('final Profile step enters Current Weight then Goal',
      (tester) async {
    final harness = await _pumpProfile(
      tester,
      profile: _validProfile(
        currentStepId: ProfileStepId.healthConditions,
        healthConditions: const {},
      ),
    );

    expect(
      find.text('Are you managing any health conditions?'),
      findsOneWidget,
    );
    final otherChoice = find.byKey(const ValueKey('health-other'));
    await tester.ensureVisible(otherChoice);
    await tester.pumpAndSettle();
    await tester.tap(otherChoice);
    await tester.pump();
    expect(
      harness.controller.state.draft.profile.healthConditions,
      {ProfileHealthCondition.other},
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(harness.controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(harness.controller.state.currentSection, OnboardingSectionId.bodyGoal);
    expect(find.byType(BodyGoalSection), findsOneWidget);
    expect(find.text('What is your current weight?'), findsOneWidget);
    expect(
      harness.controller.state.draft.profile.currentStepId,
      ProfileStepId.currentWeight,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('What do you want to achieve?'), findsOneWidget);
    expect(
      harness.controller.state.draft.profile.currentStepId,
      ProfileStepId.goal,
    );
  });

  testWidgets('common Profile subprogress has deterministic accessible semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpProfile(
        tester,
        profile: _validProfile(currentStepId: ProfileStepId.activity),
      );

      expect(
        find.bySemanticsLabel(
          "Profile step 6 of 7, What's your typical day like?",
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Profile renderer maps every common Profile child to its screen',
      (tester) async {
    const titles = {
      ProfileStepId.name: 'What should Tio call you?',
      ProfileStepId.gender: 'How do you describe your gender?',
      ProfileStepId.age: 'When were you born?',
      ProfileStepId.measurementUnits: 'Choose your units',
      ProfileStepId.height: 'What is your height?',
      ProfileStepId.activity: "What's your typical day like?",
      ProfileStepId.healthConditions: 'Are you managing any health conditions?',
    };

    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: _profileOnboardingDraft(ProfileStepId.name),
    );
    addTearDown(controller.dispose);
    await _pumpDirectProfileSection(tester, controller);

    double? expectedTitleTop;

    for (final entry in titles.entries) {
      controller.initialize(_profileOnboardingDraft(entry.key));
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key.name);
      final titleTop = tester.getTopLeft(find.text(entry.value)).dy;
      expectedTitleTop ??= titleTop;
      expect(titleTop, expectedTitleTop, reason: '${entry.key.name} title top');
    }
  });

  testWidgets('Body Goal renderer reuses Goal and weight screens', (tester) async {
    const titles = {
      ProfileStepId.goal: 'What do you want to achieve?',
      ProfileStepId.currentWeight: 'What is your current weight?',
      ProfileStepId.targetWeight: 'What is your target weight?',
    };

    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: _bodyGoalOnboardingDraft(ProfileStepId.goal),
    );
    addTearDown(controller.dispose);
    await _pumpDirectBodyGoalSection(tester, controller);

    double? expectedTitleTop;
    for (final entry in titles.entries) {
      controller.initialize(_bodyGoalOnboardingDraft(entry.key));
      await tester.pump();
      expect(controller.state.stepId, OnboardingStepId.bodyGoal);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key.name);
      final titleTop = tester.getTopLeft(find.text(entry.value)).dy;
      expectedTitleTop ??= titleTop;
      expect(titleTop, expectedTitleTop, reason: '${entry.key.name} title top');
    }
  });

  testWidgets('unified goals render in Body Goal and update ordered selection',
      (tester) async {
    final harness = await _pumpBodyGoal(
      tester,
      profile: _validProfile(currentStepId: ProfileStepId.goal),
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
      ),
    );

    expect(harness.controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(find.byType(BodyGoalSection), findsOneWidget);

    final primary = find.byKey(
      const ValueKey('goal-intent-buildMuscle'),
    );
    expect(
      find.descendant(of: primary, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );

    final supporting = find.byKey(
      const ValueKey('goal-intent-getStronger'),
    );
    await tester.ensureVisible(supporting);
    await tester.pumpAndSettle();
    await tester.tap(supporting);
    await tester.pump();

    expect(
      harness.controller.state.draft.goalSelection,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
        supportingGoal: GoalIntent.getStronger,
      ),
    );
  });
}

OnboardingDraft _profileOnboardingDraft(ProfileStepId stepId) {
  return OnboardingDraft(
    selectedMode: AppMode.workout,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
    ),
    currentStepId: OnboardingStepId.profileBasics,
    profile: _validProfile(currentStepId: stepId),
  );
}

OnboardingDraft _bodyGoalOnboardingDraft(ProfileStepId stepId) {
  return OnboardingDraft(
    selectedMode: AppMode.workout,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
    ),
    currentStepId: OnboardingStepId.bodyGoal,
    completedStepIds: const {OnboardingStepId.profileBasics},
    profile: _validProfile(currentStepId: stepId),
  );
}

Future<void> _pumpDirectProfileSection(
  WidgetTester tester,
  OnboardingController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TioTheme(
        child: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => SingleChildScrollView(
              child: ProfileSection(
                state: controller.state,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpDirectBodyGoalSection(
  WidgetTester tester,
  OnboardingController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TioTheme(
        child: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => SingleChildScrollView(
              child: BodyGoalSection(
                state: controller.state,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<_ProfileHarness> _pumpProfile(
  WidgetTester tester, {
  ProfileOnboardingDraft? profile,
  GoalIntentSelection goalSelection = const GoalIntentSelection(
    primaryGoal: GoalIntent.loseWeight,
  ),
  Future<void> Function()? onExitRequested,
}) async {
  return _pumpSection(
    tester,
    currentStepId: OnboardingStepId.profileBasics,
    profile: profile ?? ProfileOnboardingDraft(),
    goalSelection: goalSelection,
    onExitRequested: onExitRequested,
  );
}

Future<_ProfileHarness> _pumpBodyGoal(
  WidgetTester tester, {
  required ProfileOnboardingDraft profile,
  required GoalIntentSelection goalSelection,
}) async {
  return _pumpSection(
    tester,
    currentStepId: OnboardingStepId.bodyGoal,
    profile: profile,
    goalSelection: goalSelection,
  );
}

Future<_ProfileHarness> _pumpSection(
  WidgetTester tester, {
  required OnboardingStepId currentStepId,
  required ProfileOnboardingDraft profile,
  required GoalIntentSelection goalSelection,
  Future<void> Function()? onExitRequested,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final seed = OnboardingControllerSeed(
    entryPath: OnboardingEntryPath.firstRun,
    draft: OnboardingDraft(
      selectedMode: AppMode.workout,
      goalSelection: goalSelection,
      currentStepId: currentStepId,
      profile: profile,
    ),
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: TioTheme(
          child: OnboardingFlowPage(
            seed: seed,
            onExitRequested: onExitRequested,
            onFinishRequested: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return _ProfileHarness(
    controller: container.read(onboardingControllerProvider(seed)),
  );
}

ProfileOnboardingDraft _validProfile({
  required ProfileStepId currentStepId,
  Set<ProfileHealthCondition> healthConditions = const {
    ProfileHealthCondition.none,
  },
}) {
  return ProfileOnboardingDraft(
    currentStepId: currentStepId,
    name: 'Tio User',
    gender: ProfileGender.other,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 65,
    targetWeightDirection: GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: healthConditions,
  );
}

class _ProfileHarness {
  const _ProfileHarness({required this.controller});

  final OnboardingController controller;
}
