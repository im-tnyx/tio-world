import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('renders and selects only the supplied guided tabs',
      (tester) async {
    final semantics = tester.ensureSemantics();
    ShellTab? selected;
    try {
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

      final homeNode = tester.getSemantics(find.text('Home'));
      expect(homeNode.flagsCollection.isButton, isTrue);
      expect(homeNode.flagsCollection.isSelected, Tristate.isTrue);

      final workoutNode = tester.getSemantics(find.text('Workout'));
      expect(workoutNode.flagsCollection.isButton, isTrue);
      expect(workoutNode.flagsCollection.isSelected, Tristate.isFalse);

      await tester.tap(find.text('Workout'));
      expect(selected, ShellTab.workout);
    } finally {
      semantics.dispose();
    }
  });
}
