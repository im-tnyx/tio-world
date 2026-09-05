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
      expect(titleLeft, closeTo(TioSpacing.lg, 1));
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
        closeTo(
            tester.getRect(find.byKey(const ValueKey('shell-plan'))).center.dy,
            1),
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

  testWidgets('optional action sits left of a fixed right-side feature status',
      (tester) async {
    var todayTaps = 0;
    await tester.binding.setSurfaceSize(const Size(320, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpShell({Widget? leadingAction}) {
      return tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.8),
            ),
            child: TioTheme(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          home: TioShell(
            state: const ShellUiState(
              selectedTab: ShellTab.nutrition,
              visibleTabs: [ShellTab.home, ShellTab.nutrition],
            ),
            statusTopBarLeadingAction: leadingAction,
            onAction: (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    final status = find.byKey(const ValueKey('shell-meal-log-streak'));
    final streakIcon = find.byKey(const ValueKey('shell-status-streak-icon'));
    await pumpShell();
    final streakCenterWithoutAction = tester.getCenter(streakIcon).dx;

    await pumpShell(
      leadingAction: IconButton(
        key: const ValueKey('test-today-action'),
        tooltip: 'Today',
        onPressed: () => todayTaps++,
        icon: const Icon(Icons.calendar_today_outlined),
      ),
    );

    final action = find.byKey(const ValueKey('test-today-action'));
    expect(status, findsOneWidget);
    expect(action, findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getCenter(action).dx, lessThan(tester.getCenter(status).dx));
    expect(tester.getCenter(streakIcon).dx, streakCenterWithoutAction);
    expect(
      tester.getRect(streakIcon).left - tester.getRect(action).right,
      0,
    );

    await tester.tap(action);
    expect(todayTaps, 1);
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

  group('contextual status title', () {
    Future<void> pumpShell(
      WidgetTester tester, {
      required ShellTab tab,
      String? contextualTitle,
      Widget? center,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            child: child ?? const SizedBox.shrink(),
          ),
          home: TioShell(
            state: ShellUiState(
              selectedTab: tab,
              visibleTabs: const [
                ShellTab.home,
                ShellTab.workout,
                ShellTab.nutrition,
                ShellTab.progress,
              ],
            ),
            onAction: (_) {},
            statusTopBarTitle: contextualTitle,
            statusTopBarCenter: center,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    AppBar appBar(WidgetTester tester) => tester.widget<AppBar>(
          find.byType(AppBar),
        );

    String title(WidgetTester tester) => (appBar(tester).title! as Text).data!;

    testWidgets('a screen name replaces the tab label in the top bar only',
        (tester) async {
      // The tab names a domain; the screen inside it names itself.
      await pumpShell(
        tester,
        tab: ShellTab.nutrition,
        contextualTitle: 'Diary',
      );

      expect(title(tester), 'Diary');
      // The bottom navigation still says Nutrition, and the tab label itself
      // is untouched.
      expect(ShellTab.nutrition.label, 'Nutrition');
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Nutrition'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Diary'),
        ),
        findsNothing,
      );
    });

    testWidgets(
        'the tab label remains the fallback when no screen names '
        'itself', (tester) async {
      await pumpShell(tester, tab: ShellTab.nutrition);
      expect(title(tester), 'Nutrition');

      await pumpShell(tester, tab: ShellTab.workout);
      expect(title(tester), 'Workout');
    });

    testWidgets('a contextual title does not disturb the feature status',
        (tester) async {
      await pumpShell(
        tester,
        tab: ShellTab.nutrition,
        contextualTitle: 'Diary',
      );

      expect(
        find.byKey(const ValueKey('shell-meal-log-streak')),
        findsOneWidget,
      );
      expect(find.byTooltip('Meal log streak'), findsOneWidget);
    });
  });

  group('contextual status centre', () {
    Future<void> pumpCentre(
      WidgetTester tester, {
      required ShellTab tab,
      String? contextualTitle,
      Widget? center,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            child: child ?? const SizedBox.shrink(),
          ),
          home: TioShell(
            state: ShellUiState(
              selectedTab: tab,
              visibleTabs: const [
                ShellTab.home,
                ShellTab.workout,
                ShellTab.nutrition,
                ShellTab.progress,
              ],
            ),
            onAction: (_) {},
            statusTopBarTitle: contextualTitle,
            statusTopBarCenter: center,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a centre slot renders beside the title and the status',
        (tester) async {
      await pumpCentre(
        tester,
        tab: ShellTab.nutrition,
        contextualTitle: 'Diary',
        center: const Text('Sep 26', key: ValueKey('centre-probe')),
      );

      expect(find.byKey(const ValueKey('centre-probe')), findsOneWidget);
      expect(find.text('Diary'), findsWidgets);
      expect(
        find.byKey(const ValueKey('shell-meal-log-streak')),
        findsOneWidget,
      );

      // Title on the left, centre actually centred on the bar.
      final bar = tester.getRect(find.byType(AppBar));
      final centre = tester.getRect(find.byKey(const ValueKey('centre-probe')));
      expect((centre.center.dx - bar.center.dx).abs(), lessThan(1));
    });

    testWidgets('no centre slot leaves the bar exactly as it was',
        (tester) async {
      await pumpCentre(tester, tab: ShellTab.nutrition);
      expect(tester.widget<AppBar>(find.byType(AppBar)).flexibleSpace, isNull);
    });

    testWidgets('other shell surfaces are untouched', (tester) async {
      await pumpCentre(tester, tab: ShellTab.workout);
      expect(
        (tester.widget<AppBar>(find.byType(AppBar)).title! as Text).data,
        'Workout',
      );
      expect(tester.widget<AppBar>(find.byType(AppBar)).flexibleSpace, isNull);

      await pumpCentre(tester, tab: ShellTab.home);
      expect(find.text('TIO'), findsWidgets);
    });
  });

  group('compact month-year label', () {
    test('marks the year so it cannot read as a day', () {
      expect(
        tioCompactMonthYearLabel(DateTime(2026, 9), localeName: 'en_US'),
        'Sep ’26',
      );
      expect(
        tioCompactMonthYearLabel(DateTime(2026, 8), localeName: 'en_US'),
        'Aug ’26',
      );
      // A year whose last two digits need padding still reads as a year.
      expect(
        tioCompactMonthYearLabel(DateTime(2005, 1), localeName: 'en_US'),
        'Jan ’05',
      );
    });
  });
}
