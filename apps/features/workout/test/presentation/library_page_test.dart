import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onProgramsPressed,
  VoidCallback? onExercisesPressed,
  VoidCallback? onSearchPressed,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: LibraryPage(
        onProgramsPressed: onProgramsPressed ?? () {},
        onExercisesPressed: onExercisesPressed ?? () {},
        onSearchPressed: onSearchPressed ?? () {},
      ),
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

  testWidgets('lists ready Programs above Exercises', (tester) async {
    await _pump(tester);

    expect(find.byType(TioSettingsNavigationRow), findsNWidgets(2));
    final programs = find.byKey(const ValueKey('library-programs-entry'));
    final exercises = find.byKey(const ValueKey('library-exercises-entry'));

    expect(
      find.descendant(of: programs, matching: find.text('Programs')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: programs,
        matching: find.text('Create and manage programs'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: exercises, matching: find.text('Exercises')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: exercises,
        matching: find.text('Browse all exercises'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(programs).dy,
      lessThan(tester.getTopLeft(exercises).dy),
    );

    for (final placeholder in [
      'Routines',
      'Plans',
      'Training Plans',
      'Create Exercise',
      'Favorite exercises',
      'Custom exercises',
    ]) {
      expect(find.text(placeholder), findsNothing, reason: placeholder);
    }
    expect(find.byType(ProgramsPage), findsNothing);
    expect(find.byType(ExercisesPage), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('the top-bar search icon opens Exercises search', (tester) async {
    var searched = 0;
    await _pump(tester, onSearchPressed: () => searched++);

    final search = find.byKey(const ValueKey('library-search'));
    expect(
      find.descendant(of: find.byType(AppBar), matching: search),
      findsOneWidget,
    );
    final button = tester.widget<IconButton>(search);
    expect(button.tooltip, 'Search exercises');
    expect((button.icon as Icon).icon, Icons.search_rounded);

    await tester.tap(search);
    await tester.pump();
    expect(searched, 1);
  });

  testWidgets('Programs hands off to the owning route', (tester) async {
    var opened = 0;
    await _pump(tester, onProgramsPressed: () => opened++);

    await tester.tap(find.byKey(const ValueKey('library-programs-entry')));
    await tester.pump();

    expect(opened, 1);
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
