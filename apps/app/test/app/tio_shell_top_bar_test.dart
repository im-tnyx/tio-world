import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('Home top bar never derives a Back button from Navigator history',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  appBar: TioShellTopBar(
                    planTier: ShellPlanTier.free,
                    scrollOpacity: 0,
                    onAction: (_) {},
                  ),
                  body: const SizedBox.shrink(),
                ),
              ),
            ),
            child: const Text('Open Home shell'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Home shell'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.text('TIO'), findsOneWidget);
    expect(find.text('Get Pro'), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-workout-streak')), findsNothing);
    expect(find.byKey(const ValueKey('shell-meal-log-streak')), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('-'), findsNothing);
    expect(find.text('—'), findsNothing);
    expect(find.byTooltip('Profile'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsNothing);
  });

  for (final testCase in <(ShellPlanTier, String)>[
    (ShellPlanTier.free, 'Get Pro'),
    (ShellPlanTier.plus, 'Plus'),
    (ShellPlanTier.premium, 'Pro'),
  ]) {
    testWidgets('renders ${testCase.$2} plan and profile in order',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            appBar: TioShellTopBar(
              planTier: testCase.$1,
              scrollOpacity: 0,
              onAction: (_) {},
            ),
          ),
        ),
      );

      final titleX = tester.getCenter(find.text('TIO')).dx;
      final titleLeft = tester.getTopLeft(find.text('TIO')).dx;
      final planX =
          tester.getCenter(find.byKey(const ValueKey('shell-plan'))).dx;
      final profileX = tester.getCenter(find.byTooltip('Profile')).dx;
      final screenCenterX = tester.getSize(find.byType(Scaffold)).width / 2;
      final planWidth =
          tester.getSize(find.byKey(const ValueKey('shell-plan'))).width;
      final planPill = tester.widget<Container>(
        find.byKey(const ValueKey('shell-plan')),
      );

      expect(titleX, lessThan(planX));
      expect(titleLeft, closeTo(TioSpacing.large, 1));
      expect(planX, lessThan(profileX));
      expect(planX, closeTo(screenCenterX, 1));
      expect(planWidth, TioNavigationTokens.planPillWidth);
      expect(
        tester.getSize(find.byKey(const ValueKey('shell-plan'))).height,
        TioNavigationTokens.planPillHeight,
      );
      expect(find.text(testCase.$2), findsOneWidget);
      expect(
        tester.getRect(find.text(testCase.$2)).center.dy,
        closeTo(tester.getRect(find.byKey(const ValueKey('shell-plan'))).center.dy, 1),
      );
      expect(
        (planPill.decoration! as ShapeDecoration).shape,
        isA<StadiumBorder>(),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.shape, isNull);
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      switch (testCase.$1) {
        case ShellPlanTier.free:
          expect(
            find.byKey(const ValueKey('tio-avatar-plus-ring')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('tio-avatar-pro-hexagon')),
            findsNothing,
          );
          break;
        case ShellPlanTier.plus:
          expect(
            find.byKey(const ValueKey('tio-avatar-plus-ring')),
            findsOneWidget,
          );
          break;
        case ShellPlanTier.premium:
          expect(
            find.byKey(const ValueKey('tio-avatar-pro-hexagon')),
            findsOneWidget,
          );
          break;
      }
    });
  }

  testWidgets('Home chrome stays separate at compact width and large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
          ),
          child: TioTheme(child: child ?? const SizedBox.shrink()),
        ),
        home: Scaffold(
          appBar: TioShellTopBar(
            planTier: ShellPlanTier.free,
            scrollOpacity: 0,
            onAction: (_) {},
          ),
        ),
      ),
    );

    final titleRect = tester.getRect(find.text('TIO'));
    final planRect = tester.getRect(
      find.byKey(const ValueKey('shell-plan')),
    );
    final planTextRect = tester.getRect(find.text('Get Pro'));
    final profileRect = tester.getRect(find.byTooltip('Profile'));

    expect(tester.takeException(), isNull);
    expect(titleRect.right, lessThan(planRect.left));
    expect(planRect.right, lessThan(profileRect.left));
    expect(planTextRect.left, greaterThanOrEqualTo(planRect.left));
    expect(planTextRect.top, greaterThanOrEqualTo(planRect.top));
    expect(planTextRect.right, lessThanOrEqualTo(planRect.right));
    expect(planTextRect.center.dy, closeTo(planRect.center.dy, 1));
    expect(find.byKey(const ValueKey('shell-workout-streak')), findsNothing);
    expect(find.byKey(const ValueKey('shell-meal-log-streak')), findsNothing);
  });

  for (final testCase in <(ShellTab, String, Key)>[
    (
      ShellTab.workout,
      'Workout streak',
      const ValueKey('shell-workout-streak'),
    ),
    (
      ShellTab.nutrition,
      'Meal log streak',
      const ValueKey('shell-meal-log-streak'),
    ),
  ]) {
    testWidgets('${testCase.$1.name} root owns its status top bar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            child: child ?? const SizedBox.shrink(),
          ),
          home: TioShell(
            state: ShellUiState(
              selectedTab: testCase.$1,
              visibleTabs: const [
                ShellTab.home,
                ShellTab.workout,
                ShellTab.nutrition,
                ShellTab.progress,
              ],
            ),
            onAction: (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text(testCase.$1.label), findsWidgets);
      expect(find.byKey(testCase.$3), findsOneWidget);
      expect(find.byTooltip(testCase.$2), findsOneWidget);
      expect(find.text('TIO'), findsNothing);
      expect(find.byKey(const ValueKey('shell-plan')), findsNothing);
      expect(
        tester.widget<Semantics>(find.byKey(testCase.$3)).properties.onTap,
        isNull,
      );
    });
  }

  testWidgets('feature status shows only a real positive count',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          child: child ?? const SizedBox.shrink(),
        ),
        home: TioShell(
          state: const ShellUiState(
            selectedTab: ShellTab.workout,
            visibleTabs: [ShellTab.home, ShellTab.workout, ShellTab.progress],
            workoutStreakDays: 7,
          ),
          onAction: (_) {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.byTooltip('Workout streak, 7 days'), findsOneWidget);
  });

  testWidgets('feature status keeps zero icon-only and one day singular',
      (tester) async {
    Future<void> pumpStatus(int days) {
      return tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            child: child ?? const SizedBox.shrink(),
          ),
          home: TioShell(
            state: ShellUiState(
              selectedTab: ShellTab.workout,
              visibleTabs: const [
                ShellTab.home,
                ShellTab.workout,
                ShellTab.progress,
              ],
              workoutStreakDays: days,
            ),
            onAction: (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    await pumpStatus(0);
    expect(find.text('0'), findsNothing);
    expect(find.byTooltip('Workout streak'), findsOneWidget);

    await pumpStatus(1);
    expect(find.text('1'), findsOneWidget);
    expect(find.byTooltip('Workout streak, 1 day'), findsOneWidget);
  });

  testWidgets('sub-screens do not inherit a root status top bar',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          child: child ?? const SizedBox.shrink(),
        ),
        home: TioShell(
          state: const ShellUiState(
            selectedTab: ShellTab.workout,
            visibleTabs: [ShellTab.home, ShellTab.workout, ShellTab.progress],
            isBottomNavVisible: false,
            isRootTopBarVisible: false,
          ),
          onAction: (_) {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('shell-workout-streak')), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
