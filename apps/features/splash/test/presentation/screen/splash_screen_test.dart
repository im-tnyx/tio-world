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
