import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_exercise_options_sheet.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_superset_member_sheet.dart';

Widget _app(Widget home) => MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );

void main() {
  testWidgets('exercise options expose Superset add and ungroup actions',
      (tester) async {
    Future<RoutineExerciseOption?>? result;
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => result = showRoutineExerciseOptionsSheet(
              context,
              isGrouped: true,
            ),
            child: const Text('Open options'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open options'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-options-sheet')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-exercise-option-add-superset')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('routine-exercise-option-remove-superset')),
        findsOneWidget);

    await tester.tap(
        find.byKey(const ValueKey('routine-exercise-option-remove-superset')));
    await tester.pumpAndSettle();
    expect(await result, RoutineExerciseOption.removeFromSuperset);
  });

  testWidgets('member picker reports honest empty state and selects candidate',
      (tester) async {
    Future<String?>? result;
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              TextButton(
                key: const ValueKey('open-empty-members'),
                onPressed: () => result = showRoutineSupersetMemberSheet(
                  context,
                  candidates: const [],
                ),
                child: const Text('Open empty members'),
              ),
              TextButton(
                key: const ValueKey('open-members'),
                onPressed: () => result = showRoutineSupersetMemberSheet(
                  context,
                  candidates: const [
                    RoutineSupersetMemberCandidate(
                      entryId: 'entry-2',
                      title: 'Squat',
                    ),
                  ],
                ),
                child: const Text('Open members'),
              ),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('open-empty-members')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-superset-empty')),
        findsOneWidget);
    expect(find.text('There are no eligible exercises. Add another exercise first.'),
        findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-members')));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const ValueKey('routine-superset-candidate-entry-2')));
    await tester.pumpAndSettle();
    expect(await result, 'entry-2');
  });
}
