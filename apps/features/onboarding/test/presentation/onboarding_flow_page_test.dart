import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('keeps parent regions fixed while only child content changes',
      (tester) async {
    await _pumpFlow(tester);

    expect(find.text('Set up Tio'), findsNothing);
    expect(find.byType(OnboardingTopBar), findsNothing);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);
    expect(find.text('Child mode'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Set up Tio'), findsOneWidget);
    expect(find.byType(OnboardingTopBar), findsOneWidget);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);
    expect(find.text('Child profileBasics'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OnboardingBottomBar),
        matching: find.text('Back'),
      ),
      findsNothing,
    );
  });

  testWidgets('parent rebuild keeps the active step and controller',
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
                  draft: OnboardingDraft(selectedMode: AppMode.workout),
                ),
                onFinishRequested: () async {},
                stepBuilder: (context, state, controller) {
                  return Text('Child ${state.stepId.name}');
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Child profileBasics'), findsOneWidget);

    rebuildParent(() {});
    await tester.pump();

    expect(find.text('Child profileBasics'), findsOneWidget);
  });

  testWidgets('mode is excluded from top chrome and progress calculation',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpFlow(tester);

      expect(find.byType(OnboardingTopBar), findsNothing);
      expect(find.byType(OnboardingProgressIndicator), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Step 1 of 5, About you'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('App Mode section updates the draft and derives its child path',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpFlow(
        tester,
        draft: OnboardingDraft(),
        stepBuilder: _buildModeAwareStep,
      );

      expect(find.text('How will you use Tio?'), findsOneWidget);
      expect(find.byType(OnboardingTopBar), findsNothing);
      expect(find.byType(OnboardingProgressIndicator), findsNothing);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);

      await tester.tap(find.byKey(const ValueKey('app-mode-nutrition')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Next, Tio will focus setup on nutrition targets and meal preferences.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Child profileBasics'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Step 1 of 5, About you'),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Child nutritionIntro'), findsOneWidget);
      expect(find.text('Child workoutIntro'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('system back uses the same internal previous transition',
      (tester) async {
    await _pumpFlow(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Child profileBasics'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Child mode'), findsOneWidget);
  });

  testWidgets('visible top-bar Back uses the internal previous transition',
      (tester) async {
    await _pumpFlow(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Child mode'), findsOneWidget);
  });

  testWidgets('busy completion blocks visible and system Back', (tester) async {
    final completion = Completer<void>();
    var exits = 0;
    await _pumpFlow(
      tester,
      onExitRequested: () async => exits++,
      onFinishRequested: () => completion.future,
    );

    for (var step = 0;
        step < 8 && find.text('Finish').evaluate().isEmpty;
        step++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    }

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

  testWidgets('first-step system back delegates to explicit exit',
      (tester) async {
    var exits = 0;
    await _pumpFlow(
      tester,
      onExitRequested: () async => exits++,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(exits, 1);
    expect(find.byTooltip('Back'), findsNothing);
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
  });

  testWidgets('compact width and large text keep bottom actions reachable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpFlow(tester, textScaler: const TextScaler.linear(1.8));

    expect(tester.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('completion failure is announced as a live region',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpFlow(
        tester,
        onFinishRequested: () => Future<void>.error(StateError('failed')),
      );

      for (var step = 0;
          step < 8 && find.text('Finish').evaluate().isEmpty;
          step++) {
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }

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
  Future<void> Function()? onFinishRequested,
  OnboardingDraft? draft,
  OnboardingStepBuilder? stepBuilder,
  TioThemeConfig config = const TioThemeConfig(),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    ProviderScope(
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
            draft: draft ?? OnboardingDraft(selectedMode: AppMode.workout),
          ),
          onExitRequested: onExitRequested,
          onFinishRequested: onFinishRequested ?? () async {},
          stepBuilder: stepBuilder ?? _buildPlaceholderStep,
        ),
      ),
    ),
  );
  await tester.pump();
}

Widget _buildModeAwareStep(
  BuildContext context,
  OnboardingState state,
  OnboardingController controller,
) {
  if (state.stepId == OnboardingStepId.mode) {
    return AppModeStep(
      selectedMode: state.draft.selectedMode,
      onModeSelected: controller.selectMode,
    );
  }

  return _buildPlaceholderStep(context, state, controller);
}

Widget _buildPlaceholderStep(
  BuildContext context,
  OnboardingState state,
  OnboardingController controller,
) {
  return Text('Child ${state.stepId.name}');
}
