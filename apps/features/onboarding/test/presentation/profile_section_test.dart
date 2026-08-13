import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('top bar contains only Back and one progress bar',
      (tester) async {
    await _pumpProfile(tester);

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
        TioSpacing.small,
        TioSpacing.small,
        TioSpacing.extraLarge,
        TioSpacing.small,
      ),
    );

    final barHeight = padding.child! as SizedBox;
    expect(barHeight.height, 48);
    final row = barHeight.child! as Row;
    expect(row.children, hasLength(2));

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
      closeTo(0, 0.001),
    );
    expect(
      screenWidth - progressRect.right,
      closeTo(TioSpacing.extraLarge, 0.001),
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
      find.byKey(const ValueKey('profile-choice-gender-female')),
    );
    await tester.pump();
    expect(harness.controller.state.draft.profile.gender, ProfileGender.female);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('What should Tio call you?'), findsOneWidget);
    expect(harness.controller.state.draft.profile.name, 'Tio User');
  });

  testWidgets('health Other uses typed draft and final step follows mode plan',
      (tester) async {
    final harness = await _pumpProfile(
      tester,
      profile: _validProfile(
        currentStepId: ProfileStepId.healthConditions,
        healthConditions: const {},
      ),
    );

    expect(
      find.text('Any health conditions to consider?'),
      findsOneWidget,
    );
    final otherChoice =
        find.byKey(const ValueKey('profile-choice-health-other'));
    await tester.ensureVisible(otherChoice);
    await tester.pumpAndSettle();
    await tester.tap(otherChoice);
    await tester.pump();
    expect(
      harness.controller.state.draft.profile.healthConditions,
      {ProfileHealthCondition.other},
    );
    expect(
      find.byKey(const ValueKey('profile-other-health-input')),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final otherField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('profile-other-health-input')),
        matching: find.byType(TextField),
      ),
    );
    expect(
      otherField.decoration?.errorText,
      'Describe the other health condition.',
    );

    final otherInput = find.byType(TextFormField);
    await tester.ensureVisible(otherInput);
    await tester.pumpAndSettle();
    await tester.enterText(otherInput, 'Asthma');
    await tester.pump();
    expect(
      harness.controller.state.draft.profile.otherHealthCondition,
      'Asthma',
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      harness.controller.state.stepId,
      OnboardingStepId.workoutPreferences,
    );
    expect(find.text('Training preferences'), findsWidgets);
  });

  testWidgets('profile subprogress has deterministic accessible semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpProfile(
        tester,
        profile: _validProfile(currentStepId: ProfileStepId.activity),
      );

      expect(
        find.bySemanticsLabel(
          'Profile step 8 of 9, How active is a typical day?',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('renderer maps every typed ProfileStepId to its screen',
      (tester) async {
    const titles = {
      ProfileStepId.name: 'What should Tio call you?',
      ProfileStepId.gender: 'How do you describe your gender?',
      ProfileStepId.goal: 'What is your main goal?',
      ProfileStepId.age: 'When were you born?',
      ProfileStepId.height: 'What is your height?',
      ProfileStepId.currentWeight: 'What is your current weight?',
      ProfileStepId.targetWeight: 'What is your target weight?',
      ProfileStepId.activity: 'How active is a typical day?',
      ProfileStepId.healthConditions: 'Any health conditions to consider?',
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

  testWidgets('selected goals render and update the typed draft',
      (tester) async {
    final harness = await _pumpProfile(
      tester,
      profile: _validProfile(currentStepId: ProfileStepId.goal),
    );
    final keepFit = find.byKey(
      const ValueKey('profile-choice-goal-keepFit'),
    );
    expect(
      find.descendant(of: keepFit, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );

    final supporting = find.byKey(
      const ValueKey('profile-choice-goal-boostStrength'),
    );
    await tester.ensureVisible(supporting);
    await tester.pumpAndSettle();
    await tester.tap(supporting);
    await tester.pump();

    expect(
      harness.controller.state.draft.profile.goals,
      {ProfileGoal.keepFit, ProfileGoal.boostStrength},
    );
  });
}

OnboardingDraft _profileOnboardingDraft(ProfileStepId stepId) {
  return OnboardingDraft(
    selectedMode: AppMode.workout,
    currentStepId: OnboardingStepId.profileBasics,
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

Future<_ProfileHarness> _pumpProfile(
  WidgetTester tester, {
  ProfileOnboardingDraft? profile,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final seed = OnboardingControllerSeed(
    entryPath: OnboardingEntryPath.firstRun,
    draft: OnboardingDraft(
      selectedMode: AppMode.workout,
      currentStepId: OnboardingStepId.profileBasics,
      profile: profile ?? ProfileOnboardingDraft(),
    ),
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: TioTheme(
          child: OnboardingFlowPage(
            seed: seed,
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
    targetWeightKg: 70,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: healthConditions,
  );
}

class _ProfileHarness {
  const _ProfileHarness({required this.controller});

  final OnboardingController controller;
}
