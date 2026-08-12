import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('compatibility page reuses AppModeStep and confirms on Continue',
      (tester) async {
    AppMode? confirmedMode;
    await _pumpPage(
      tester,
      onModeConfirmed: (mode) async => confirmedMode = mode,
    );

    expect(find.byType(AppModeStep), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.byKey(const ValueKey('app-mode-hybrid')));
    await tester.pumpAndSettle();

    expect(confirmedMode, isNull);
    await _scrollToContinue(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(confirmedMode, AppMode.hybrid);
  });

  testWidgets('compatibility save failure remains retryable and is announced',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPage(
        tester,
        onModeConfirmed: (_) => Future<void>.error(StateError('failed')),
      );

      await tester.tap(find.byKey(const ValueKey('app-mode-workout')));
      await tester.pump();
      await _scrollToContinue(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final errorFinder =
          find.text('Could not save your mode. Please try again.');
      expect(errorFinder, findsOneWidget);
      expect(
        tester.getSemantics(errorFinder).flagsCollection.isLiveRegion,
        isTrue,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('compatibility save locks selection and duplicate confirmation',
      (tester) async {
    final saveGate = Completer<void>();
    var confirmationCalls = 0;
    await _pumpPage(
      tester,
      onModeConfirmed: (_) {
        confirmationCalls++;
        return saveGate.future;
      },
    );

    await tester.tap(find.byKey(const ValueKey('app-mode-workout')));
    await tester.pump();
    await _scrollToContinue(tester);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(confirmationCalls, 1);
    expect(find.text('Saving'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('app-mode-nutrition')),
          )
          .onTap,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(confirmationCalls, 1);

    saveGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saving'), findsNothing);
  });

  testWidgets('system Back exits the top-bar-free compatibility page',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TioTheme(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TioTheme(
                    child: AppModeOnboardingPage(
                      onModeConfirmed: (_) async {},
                    ),
                  ),
                ),
              ),
              child: const Text('Open mode chooser'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open mode chooser'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Open mode chooser'), findsOneWidget);
    expect(find.byType(AppModeStep), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Future<void> Function(AppMode mode) onModeConfirmed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TioTheme(
        child: AppModeOnboardingPage(
          onModeConfirmed: onModeConfirmed,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _scrollToContinue(WidgetTester tester) async {
  await tester.fling(
    find.byType(ListView),
    const Offset(0, -700),
    1200,
  );
  await tester.pumpAndSettle();
  expect(find.text('Continue'), findsOneWidget);
}
