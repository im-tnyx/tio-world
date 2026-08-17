import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_onboarding/src/presentation/screens/profile/mobile_screen.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('mobile uses parent spacing and fixed bottom info action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
          home: OnboardingFlowPage(
            seed: OnboardingControllerSeed(
              entryPath: OnboardingEntryPath.firstRun,
              draft: OnboardingDraft(
                selectedMode: AppMode.workout,
                currentStepId: OnboardingStepId.mobile,
                completedStepIds: const {
                  OnboardingStepId.mode,
                  OnboardingStepId.profileBasics,
                },
                profile: _validProfile(),
              ),
            ),
            onFinishRequested: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MobileScreen), findsOneWidget);
    expect(find.byType(TioMobileNumberField), findsOneWidget);
    expect(find.text("What's your mobile number?"), findsOneWidget);
    expect(find.textContaining('(Optional)'), findsNothing);

    expect(
      find.descendant(
        of: find.byType(OnboardingContentHost),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );

    const infoLabel = 'Why do we ask for your mobile number?';
    expect(
      find.descendant(
        of: find.byType(OnboardingBottomBar),
        matching: find.text(infoLabel),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MobileScreen),
        matching: find.text(infoLabel),
      ),
      findsNothing,
    );

    await tester.tap(find.text(infoLabel));
    await tester.pumpAndSettle();

    expect(find.text('Data Collection'), findsOneWidget);
    expect(find.text('Understood'), findsOneWidget);
    expect(find.byType(TioButton), findsWidgets);

    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();
    expect(find.text('Data Collection'), findsNothing);
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
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}
