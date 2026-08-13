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
}
