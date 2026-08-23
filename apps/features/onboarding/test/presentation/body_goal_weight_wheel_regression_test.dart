import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('Body Goal Current Weight renders the shared weight wheel',
      (tester) async {
    await _pumpBodyGoal(
      tester,
      profile: _profileFor(ProfileStepId.currentWeight),
    );

    expect(find.byType(CurrentWeightScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('current-weight-wheel')), findsOneWidget);
    expect(find.byKey(const ValueKey('target-weight-wheel')), findsNothing);
  });

  testWidgets('eligible Body Goal Target Weight renders the shared weight wheel',
      (tester) async {
    await _pumpBodyGoal(
      tester,
      profile: _profileFor(
        ProfileStepId.targetWeight,
        targetWeightKg: 65,
      ),
    );

    expect(find.byType(TargetWeightScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('target-weight-wheel')), findsOneWidget);
    expect(find.byKey(const ValueKey('current-weight-wheel')), findsNothing);
  });

  testWidgets(
      'Target Weight wheel falls back to Current Weight when recommendation is suppressed',
      (tester) async {
    await _pumpBodyGoal(
      tester,
      profile: _profileFor(
        ProfileStepId.targetWeight,
        heightCm: 180,
        currentWeightKg: 50,
      ),
    );

    final wheel = tester.widget<OnboardingWeightWheel>(
      find.byKey(const ValueKey('target-weight-wheel')),
    );
    expect(wheel.valueKg, 50);
  });
}

Future<void> _pumpBodyGoal(
  WidgetTester tester, {
  required ProfileOnboardingDraft profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(),
          child: child ?? const SizedBox.shrink(),
        ),
        home: OnboardingFlowPage(
          seed: OnboardingControllerSeed(
            entryPath: OnboardingEntryPath.firstRun,
            draft: OnboardingDraft(
              selectedMode: AppMode.nutrition,
              goalSelection: const GoalIntentSelection(
                primaryGoal: GoalIntent.loseWeight,
              ),
              currentStepId: OnboardingStepId.bodyGoal,
              profile: profile,
            ),
          ),
          onFinishRequested: (_) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProfileOnboardingDraft _profileFor(
  ProfileStepId stepId, {
  double heightCm = 170,
  double currentWeightKg = 70,
  double? targetWeightKg,
}) {
  return ProfileOnboardingDraft(
    currentStepId: stepId,
    name: 'Tio User',
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: heightCm,
    currentWeightKg: currentWeightKg,
    targetWeightKg: targetWeightKg,
    targetWeightDirection:
        targetWeightKg == null ? null : GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}
