import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_splash/splash.dart';

void main() {
  Widget buildTestApp({
    Future<String> Function()? onCheckInitialDestination,
    String? failureMessage,
    Future<void> Function()? onRetry,
  }) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashScreen(
            onCheckInitialDestination: onCheckInitialDestination,
            failureMessage: failureMessage,
            onRetry: onRetry,
          ),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: Text('Auth Route')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding Route')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home Route')),
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => TioTheme(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  group('SplashScreen Destination Resolution', () {
    testWidgets('stays on Splash when no destination checker is provided', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Auth Route'), findsNothing);
      expect(find.text('Onboarding Route'), findsNothing);
      expect(find.text('Home Route'), findsNothing);
    });

    testWidgets('navigates to /auth when unauthenticated session is detected', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onCheckInitialDestination: () async => '/auth',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Auth Route'), findsOneWidget);
    });

    testWidgets('navigates to /onboarding when authenticated user has incomplete profile', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onCheckInitialDestination: () async => '/onboarding',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Onboarding Route'), findsOneWidget);
    });

    testWidgets('navigates to / (Home) when authenticated user has completed account', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onCheckInitialDestination: () async => '/',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Home Route'), findsOneWidget);
    });

    testWidgets('falls back to /auth when destination check throws an error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onCheckInitialDestination: () => Future.error(Exception('Network timeout')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Auth Route'), findsOneWidget);
    });

    testWidgets('failure mode replaces permanent spinner with recoverable feedback', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          failureMessage: "Couldn't finish signing you in. Check your connection and try again.",
          onRetry: () async {},
        ),
      );
      await tester.pump();

      expect(
        find.text("Couldn't finish signing you in. Check your connection and try again."),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Retry invokes the recovery callback', (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(
        buildTestApp(
          failureMessage: "Couldn't finish signing you in. Check your connection and try again.",
          onRetry: () async {
            retryCount++;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCount, 1);
    });
  });
}
