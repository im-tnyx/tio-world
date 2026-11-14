import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_exercise_options_sheet.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_superset_member_sheet.dart';
import 'package:tio_feature_workout/src/presentation/widgets/superset_group_marker.dart';

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
                  initiatingExerciseTitle: 'Bench Press',
                  candidates: const [],
                ),
                child: const Text('Open empty members'),
              ),
              TextButton(
                key: const ValueKey('open-members'),
                onPressed: () => result = showRoutineSupersetMemberSheet(
                  context,
                  initiatingExerciseTitle: 'Bench Press',
                  candidates: const [
                    RoutineSupersetMemberCandidate(
                      entryId: 'entry-2',
                      title: 'Squat',
                      supersetLabel: 'A2',
                    ),
                    RoutineSupersetMemberCandidate(
                      entryId: 'entry-3',
                      title: 'Cable Row',
                    ),
                    RoutineSupersetMemberCandidate(
                      entryId: 'entry-4',
                      title: 'Leg Curl',
                      supersetLabel: 'B1',
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
    expect(
        find.byKey(const ValueKey('routine-superset-empty')), findsOneWidget);
    expect(
        find.text(
            'Add a second exercise first. A Superset needs at least two exercises.'),
        findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-members')));
    await tester.pumpAndSettle();
    expect(find.text('Superset'), findsOneWidget);
    expect(find.text('Bench Press with…'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('routine-superset-candidate-accent-entry-2'),
      ),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('superset-group-marker-A2')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('superset-group-marker-B1')), findsOneWidget);
    expect(find.textContaining('Already in Superset'), findsNothing);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(
              const ValueKey('routine-superset-candidate-semantics-entry-2'),
            ),
          )
          .properties
          .label,
      'Squat, already in Superset A',
    );
    expect(find.text('Add to Superset'), findsNothing);
    expect(find.text('Cable Row'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('routine-superset-candidate-divider-top')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('routine-superset-candidate-divider-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('routine-superset-candidate-divider-2')),
      findsOneWidget,
    );
    final groupedRow = tester.widget<ListTile>(
      find.byKey(const ValueKey('routine-superset-candidate-entry-2')),
    );
    expect(groupedRow.onTap, isNull);
    expect(groupedRow.horizontalTitleGap, TioSpacing.xs);
    expect(groupedRow.minLeadingWidth, TioSize.dp4);
    final availableRow = tester.widget<ListTile>(
      find.byKey(const ValueKey('routine-superset-candidate-entry-3')),
    );
    expect(availableRow.trailing, isA<Icon>());
    expect((availableRow.trailing! as Icon).icon,
        Icons.radio_button_unchecked_rounded);
    final groupedRowForGroupB = tester.widget<ListTile>(
      find.byKey(const ValueKey('routine-superset-candidate-entry-4')),
    );
    expect((groupedRowForGroupB.trailing! as Icon).icon,
        Icons.check_circle_rounded);
    await tester.tap(
      find.byKey(const ValueKey('routine-superset-candidate-entry-2')),
    );
    expect(find.byKey(const ValueKey('routine-superset-member-sheet')),
        findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('routine-superset-candidate-entry-3')),
    );
    await tester.pumpAndSettle();
    expect(await result, 'entry-3');
  });

  testWidgets('long Superset list scrolls while the picker header stays put',
      (tester) async {
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const ValueKey('open-long-members'),
            onPressed: () => showRoutineSupersetMemberSheet(
              context,
              initiatingExerciseTitle: 'Bench Press',
              candidates: [
                for (var index = 0; index < 20; index++)
                  RoutineSupersetMemberCandidate(
                    entryId: 'entry-$index',
                    title: 'Exercise $index',
                  ),
              ],
            ),
            child: const Text('Open long members'),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('open-long-members')));
    await tester.pumpAndSettle();
    final title = find.text('Bench Press with…');
    final titleTop = tester.getRect(title).top;
    final list = find.byKey(const ValueKey('routine-superset-candidate-list'));
    final listRect = tester.getRect(list);
    await tester.dragUntilVisible(
      find.text('Exercise 19'),
      list,
      const Offset(0, -200),
      maxIteration: 10,
    );
    await tester.pumpAndSettle();
    final lastCandidate =
        find.byKey(const ValueKey('routine-superset-candidate-entry-19'));
    expect(find.text('Exercise 19'), findsOneWidget);
    expect(tester.getRect(title).top, titleTop);
    expect(tester.getRect(lastCandidate).bottom,
        lessThanOrEqualTo(listRect.bottom));
    expect(
        tester.getRect(lastCandidate).top, greaterThanOrEqualTo(listRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Superset groups use a distinct accent by group label',
      (tester) async {
    late Color firstGroup;
    late Color secondGroup;
    late Color thirdGroup;
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) {
          firstGroup = supersetGroupColor(context, 'A1');
          secondGroup = supersetGroupColor(context, 'B1');
          thirdGroup = supersetGroupColor(context, 'C1');
          return const Scaffold(body: SizedBox.shrink());
        },
      ),
    ));

    expect(firstGroup, isNot(secondGroup));
    expect(firstGroup, isNot(thirdGroup));
    expect(secondGroup, isNot(thirdGroup));
    expect(
        supersetGroupColor(
          tester.element(find.byType(Scaffold)),
          'A2',
        ),
        firstGroup);
  });
}
