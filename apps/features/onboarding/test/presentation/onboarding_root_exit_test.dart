import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('nested Back reaches Name before offering root logout',
      (tester) async {
    var exits = 0;
    await _pumpRootFlow(
      tester,
      profileStep: ProfileStepId.gender,
      onExitRequested: () async => exits++,
    );

    expect(find.text('Profile gender'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Profile name'), findsOneWidget);
    expect(find.byType(TioConfirmationCard), findsNothing);
    expect(exits, 0);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(TioConfirmationCard), findsOneWidget);
    expect(find.text('Log out of Tio?'), findsOneWidget);
    expect(exits, 0);
  });

  testWidgets('root logout confirmation Cancel stays on Name', (tester) async {
    var exits = 0;
    await _pumpRootFlow(
      tester,
      profileStep: ProfileStepId.name,
      onExitRequested: () async => exits++,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(TioConfirmationCard), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.byType(TioConfirmationCard), findsNothing);
    expect(find.text('Profile name'), findsOneWidget);
    expect(exits, 0);
  });

  testWidgets('root logout confirmation Confirm delegates exit once',
      (tester) async {
    var exits = 0;
    await _pumpRootFlow(
      tester,
      profileStep: ProfileStepId.name,
      onExitRequested: () async => exits++,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(exits, 1);
    expect(find.byType(TioConfirmationCard), findsNothing);
  });

  testWidgets('system Back opens the same root logout confirmation',
      (tester) async {
    var exits = 0;
    await _pumpRootFlow(
      tester,
      profileStep: ProfileStepId.name,
      onExitRequested: () async => exits++,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TioConfirmationCard), findsOneWidget);
    expect(find.text('Log out of Tio?'), findsOneWidget);
    expect(exits, 0);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(exits, 1);
  });
}

Future<void> _pumpRootFlow(
  WidgetTester tester, {
  required ProfileStepId profileStep,
  required Future<void> Function() onExitRequested,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: TioTheme(
          child: OnboardingFlowPage(
            seed: OnboardingControllerSeed(
              entryPath: OnboardingEntryPath.firstRun,
              draft: OnboardingDraft(
                selectedMode: AppMode.workout,
                currentStepId: OnboardingStepId.profileBasics,
                profile: ProfileOnboardingDraft(
                  currentStepId: profileStep,
                  name: 'Tio User',
                ),
              ),
            ),
            onExitRequested: onExitRequested,
            onFinishRequested: (_) async {},
            stepBuilder: (context, state, controller) => Text(
              'Profile ${state.draft.profile.currentStepId.name}',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
