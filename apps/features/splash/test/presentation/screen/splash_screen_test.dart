import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_splash/splash.dart';

void main() {
  Widget buildTestApp({
    String? failureMessage,
    Future<void> Function()? onRetry,
  }) {
    return MaterialApp(
      builder: (context, child) => TioTheme(
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
