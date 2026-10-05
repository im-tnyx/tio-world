import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onProgramsPressed,
  VoidCallback? onExercisesPressed,
  VoidCallback? onCreateExercisePressed,
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
        onCreateExercisePressed: onCreateExercisePressed ?? () {},
        onSearchPressed: onSearchPressed ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows Library chrome, full category strip and Programs default',
      (tester) async {
    await _pump(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Library')),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byKey(const ValueKey('library-category-strip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('library-category-clear')), findsNothing);
    expect(
      find.byKey(const ValueKey('library-programs-content')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('library-programs-entry')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-exercises-content')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-custom-exercises-entry')),
      findsNothing,
    );
    expect(find.text('Your Plan'), findsNothing);
    expect(find.text('Routines'), findsNothing);
  });

  testWidgets('Exercises selection collapses pills and shows only two actions',
      (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-category-clear')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-programs-content')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-exercises-content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-create-exercise-entry')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('library-exercises-entry')), findsOneWidget);
    expect(find.text('Favorite Exercises'), findsNothing);
    expect(find.text('Custom Exercises'), findsNothing);
    expect(find.byType(ExercisesPage), findsNothing);
  });

  testWidgets('clear restores the full strip and default Programs content',
      (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-category-clear')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-category-clear')), findsNothing);
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-programs-content')),
      findsOneWidget,
    );
  });

  testWidgets('Programs explicit selection keeps current Programs capability',
      (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const ValueKey('library-category-programs')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-category-clear')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('library-programs-entry')), findsOneWidget);
  });

  testWidgets('Programs action hands off to the owning route', (tester) async {
    var opened = 0;
    await _pump(tester, onProgramsPressed: () => opened++);

    await tester.tap(find.byKey(const ValueKey('library-programs-entry')));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('Exercises actions use separate create and browse handoffs',
      (tester) async {
    var created = 0;
    var browsed = 0;
    await _pump(
      tester,
      onCreateExercisePressed: () => created++,
      onExercisesPressed: () => browsed++,
    );

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('library-create-exercise-entry')),
    );
    await tester.pump();
    expect(created, 1);
    expect(browsed, 0);

    await tester.tap(find.byKey(const ValueKey('library-exercises-entry')));
    await tester.pump();
    expect(created, 1);
    expect(browsed, 1);
  });

  testWidgets('the top-bar search icon keeps the existing Exercises search',
      (tester) async {
    var searched = 0;
    await _pump(tester, onSearchPressed: () => searched++);

    final search = find.byKey(const ValueKey('library-search'));
    final button = tester.widget<IconButton>(search);
    expect(button.tooltip, 'Search exercises');

    await tester.tap(search);
    await tester.pump();
    expect(searched, 1);
  });

  for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
    testWidgets('renders category UI on the ${mode.name} theme background',
        (tester) async {
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
