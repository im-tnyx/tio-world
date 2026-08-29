import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_splash/splash.dart';

void main() {
  Widget buildTestApp({
    String? failureMessage,
    Future<void> Function()? onRetry,
    TioThemeMode mode = TioThemeMode.dark,
  }) {
    return MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: SplashScreen(
        failureMessage: failureMessage,
        onRetry: onRetry,
      ),
    );
  }

  group('SplashScreen presentation', () {
    testWidgets('shows passive loading state while app bootstrap resolves',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows a bold TIO wordmark instead of the logo image',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.byType(Image), findsNothing);
      final wordmarkStyle = tester.widget<Text>(find.text('TIO')).style;
      expect(wordmarkStyle?.fontWeight, FontWeight.w900);
      expect(wordmarkStyle?.fontSize, TioFontSize.size44);
    });

    testWidgets(
        'TIO wordmark position is unaffected by whether the spinner or the '
        'failure/retry block renders below it', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      final loadingWordmarkY = tester.getCenter(find.text('TIO')).dy;

      await tester.pumpWidget(
        buildTestApp(
          failureMessage: 'Bootstrap failed.',
          onRetry: () async {},
        ),
      );
      await tester.pump();
      final failureWordmarkY = tester.getCenter(find.text('TIO')).dy;

      expect(
        loadingWordmarkY,
        failureWordmarkY,
        reason: 'the wordmark must stay in a fixed position regardless of '
            "the taller failure/retry block's own height",
      );
    });

    testWidgets(
        'loading spinner is horizontally centered and renders below the '
        'wordmark, never above it', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final screenCenterX =
          tester.getSize(find.byType(Scaffold)).center(Offset.zero).dx;
      final spinnerCenter =
          tester.getCenter(find.byType(CircularProgressIndicator));
      final wordmarkBottom = tester.getBottomLeft(find.text('TIO')).dy;

      expect(spinnerCenter.dx, screenCenterX);
      expect(
        spinnerCenter.dy,
        greaterThan(wordmarkBottom),
        reason: 'the spinner must render in the reserved area below the '
            'wordmark, never overlapping it',
      );
    });

    testWidgets(
        'wordmark and failure/retry content never overlap, even with a long '
        'wrapped message on a compact, text-scaled viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
          child: buildTestApp(
            failureMessage: "Couldn't finish signing you in. "
                'Check your connection and try again.',
            onRetry: () async {},
          ),
        ),
      );
      await tester.pump();

      final wordmarkRect = tester.getRect(find.text('TIO'));
      final retryRect = tester.getRect(find.text('Retry'));
      final failureTextRect = tester.getRect(
        find.textContaining("Couldn't finish signing you in"),
      );

      expect(
        wordmarkRect.overlaps(failureTextRect),
        isFalse,
        reason: 'wordmark and the failure message must never paint over '
            'each other on a compact, heavily text-scaled viewport',
      );
      expect(
        wordmarkRect.overlaps(retryRect),
        isFalse,
        reason: 'wordmark and the Retry button must never paint over each '
            'other on a compact, heavily text-scaled viewport',
      );
    });

    for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
      testWidgets('TIO wordmark stays readable against the background on $mode',
          (tester) async {
        await tester.pumpWidget(buildTestApp(mode: mode));
        await tester.pump();

        final context = tester.element(find.byType(SplashScreen));
        final colors = context.tioColors;
        final wordmarkColor =
            tester.widget<Text>(find.text('TIO')).style?.color;

        expect(
          wordmarkColor,
          colors.textPrimary,
          reason: 'the wordmark must use a theme-adaptive color, not a '
              'fixed tone that can match the theme-adaptive background',
        );
        expect(
          wordmarkColor,
          isNot(colors.background),
          reason: 'wordmark must not be the same color as its own background '
              'on $mode',
        );

        final spinnerColor =
            tester.widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            ).color;
        expect(
          spinnerColor,
          isNot(colors.background),
          reason: 'loading spinner must not be the same color as its own '
              'background on $mode',
        );
      });
    }

    testWidgets('failure mode replaces spinner with recoverable feedback',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          failureMessage:
              "Couldn't finish signing you in. Check your connection and try again.",
          onRetry: () async {},
        ),
      );
      await tester.pump();

      expect(
        find.text(
          "Couldn't finish signing you in. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Retry invokes the app-owned recovery callback', (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(
        buildTestApp(
          failureMessage: 'Bootstrap failed.',
          onRetry: () async {
            retryCount++;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryCount, 1);
    });

    testWidgets('async Retry shows progress and ignores duplicate taps',
        (tester) async {
      final retryCompletion = Completer<void>();
      var retryCount = 0;

      await tester.pumpWidget(
        buildTestApp(
          failureMessage: 'Bootstrap failed.',
          onRetry: () {
            retryCount++;
            return retryCompletion.future;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);

      retryCompletion.complete();
      await tester.pumpAndSettle();

      expect(retryCount, 1);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
