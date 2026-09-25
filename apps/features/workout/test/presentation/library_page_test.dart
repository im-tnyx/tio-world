import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onExercisesPressed,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: LibraryPage(onExercisesPressed: onExercisesPressed ?? () {}),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the Library title with back', (tester) async {
    await _pump(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Library')),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('lists only the ready Exercises section', (tester) async {
    await _pump(tester);

    expect(find.byType(TioSettingsNavigationRow), findsOneWidget);
    final entry = find.byKey(const ValueKey('library-exercises-entry'));
    expect(
      find.descendant(of: entry, matching: find.text('Exercises')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: entry, matching: find.text('Browse all exercises')),
      findsOneWidget,
    );
    for (final placeholder in [
      'Programs',
      'Routines',
      'Plans',
      'Training Plans',
      'Create Exercise',
      'Favorite exercises',
      'Custom exercises',
    ]) {
      expect(find.text(placeholder), findsNothing, reason: placeholder);
    }
    // The root never renders the Exercise catalog itself.
    expect(find.byType(ExercisesPage), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('Exercises hands off to the owning route', (tester) async {
    var opened = 0;
    await _pump(tester, onExercisesPressed: () => opened++);

    await tester.tap(find.byKey(const ValueKey('library-exercises-entry')));
    await tester.pump();

    expect(opened, 1);
  });

  for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
    testWidgets('renders on the ${mode.name} theme background', (tester) async {
      await _pump(tester, mode: mode);

      final context = tester.element(find.byType(LibraryPage));
      final scaffold = tester.widget<Scaffold>(
        find.byKey(const ValueKey('library-page')),
      );
      expect(scaffold.backgroundColor, context.tioColors.background);
      expect(tester.takeException(), isNull);
    });
  }
}
