import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('renders and selects only the supplied guided tabs',
      (tester) async {
    ShellTab? selected;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          bottomNavigationBar: TioShellBottomNav(
            selectedTab: ShellTab.home,
            visibleTabs: const [
              ShellTab.home,
              ShellTab.workout,
              ShellTab.progress
            ],
            onTabSelected: (tab) => selected = tab,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Nutrition'), findsNothing);
    expect(find.text('Tio'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    await tester.tap(find.text('Workout'));
    expect(selected, ShellTab.workout);
  });

  testWidgets('single Home tab expands to missing-mode compatibility navigation',
      (tester) async {
    ShellTab? selected;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: TioShell(
          state: const ShellUiState(
            selectedTab: ShellTab.home,
            visibleTabs: [ShellTab.home],
            isBottomNavVisible: true,
            isRootTopBarVisible: false,
          ),
          onAction: (action) {
            if (action is ShellTabSelected) selected = action.tab;
          },
          child: const Text('Home body'),
        ),
      ),
    );

    expect(find.text('Home body'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Tio'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Nutrition'));
    expect(selected, ShellTab.nutrition);
  });

  testWidgets('arbitrary single destination still hides Material NavigationBar',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: TioShell(
          state: const ShellUiState(
            selectedTab: ShellTab.workout,
            visibleTabs: [ShellTab.workout],
            isBottomNavVisible: true,
            isRootTopBarVisible: false,
          ),
          onAction: (_) {},
          child: const Text('Workout body'),
        ),
      ),
    );

    expect(find.text('Workout body'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
