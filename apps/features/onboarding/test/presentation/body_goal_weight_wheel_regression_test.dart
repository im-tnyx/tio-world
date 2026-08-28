import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_onboarding/src/presentation/screens/profile/current_weight_screen.dart';
import 'package:tio_feature_onboarding/src/presentation/screens/profile/target_weight_screen.dart';
import 'package:tio_feature_onboarding/src/presentation/widgets/wheels/onboarding_weight_wheel.dart';
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

  testWidgets('Goal Pace presents canonical pace in the selected weight unit',
      (tester) async {
    await _pumpBodyGoal(
      tester,
      profile: _profileFor(
        ProfileStepId.goalPace,
        targetWeightKg: 65,
        weightUnit: 'lbs',
      ),
    );

    expect(find.byType(GoalPaceScreen), findsOneWidget);
    expect(find.text('1.1 lb / week'), findsOneWidget);
  });

  testWidgets('Goal Pace info sheet stays Body-owned and calorie-free',
      (tester) async {
    await _pumpBodyGoal(
      tester,
      profile: _profileFor(
        ProfileStepId.goalPace,
        targetWeightKg: 65,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('targets-goal-pace-info')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('targets-goal-pace-info-sheet')),
      findsOneWidget,
    );
    expect(find.byType(TioInformationBottomSheet), findsOneWidget);
    expect(find.text('How goal pace works'), findsOneWidget);
    expect(find.textContaining('weekly'), findsWidgets);
    expect(find.textContaining('target date'), findsOneWidget);
    expect(find.textContaining('BMR'), findsNothing);
    expect(find.textContaining('TDEE'), findsNothing);
    expect(find.textContaining('calorie'), findsNothing);
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
  String weightUnit = 'kg',
}) {
  return ProfileOnboardingDraft(
    currentStepId: stepId,
    name: 'Tio User',
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: heightCm,
    currentWeightKg: currentWeightKg,
    weightUnit: weightUnit,
    targetWeightKg: targetWeightKg,
    targetWeightDirection:
        targetWeightKg == null ? null : GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}
