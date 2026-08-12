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

    expect(find.text('Set up Tio'), findsOneWidget);
    expect(find.byType(OnboardingTopBar), findsOneWidget);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);
    expect(find.text('Child mode'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Set up Tio'), findsOneWidget);
    expect(find.byType(OnboardingTopBar), findsOneWidget);
    expect(find.byType(OnboardingBottomBar), findsOneWidget);
    expect(find.text('Child profileBasics'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
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

  testWidgets('progress exposes position and title semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpFlow(tester);

      expect(
        find.bySemanticsLabel('Step 1 of 6, Choose mode'),
        findsOneWidget,
      );
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
  });
}

Future<void> _pumpFlow(
  WidgetTester tester, {
  Future<void> Function()? onExitRequested,
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
            draft: OnboardingDraft(selectedMode: AppMode.workout),
          ),
          onExitRequested: onExitRequested,
          onFinishRequested: () async {},
          stepBuilder: (context, state, controller) {
            return Text('Child ${state.stepId.name}');
          },
        ),
      ),
    ),
  );
  await tester.pump();
}
