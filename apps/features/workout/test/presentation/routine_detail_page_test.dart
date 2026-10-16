import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _p1 = '10000000-0000-4000-8000-000000000001';
const _p2 = '10000000-0000-4000-8000-000000000002';
const _r1 = '20000000-0000-4000-8000-000000000001';
const _e1 = '30000000-0000-4000-8000-000000000001';
const _s1 = '40000000-0000-4000-8000-000000000001';

Program get _program => Program(id: ProgramId(_p1), name: 'Strength');
Routine get _routine =>
    Routine(id: RoutineId(_r1), programId: ProgramId(_p1), name: 'Push Day');

RoutineCompositionSnapshot _snapshot({List<RoutineCompositionEntry> entries = const []}) =>
    RoutineCompositionSnapshot(
      routineId: RoutineId(_r1),
      revision: 1,
      entries: entries,
    );

Future<void> _pump(
  WidgetTester tester, {
  required RoutineRepository? routines,
  required RoutineCompositionRepository? compositions,
  Routine? selected,
  TioThemeMode mode = TioThemeMode.light,
  WeightUnit? weightUnit = WeightUnit.kg,
  Future<bool?> Function(Routine)? onEditPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: RoutineDetailPage(
        program: _program,
        routine: selected ?? _routine,
        routineRepository: routines,
        compositionRepository: compositions,
        catalogRepository: _Catalog(),
        weightUnit: weightUnit,
        onEditPressed: onEditPressed,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders real ordered Exercise/Set summary without fake Start',
      (tester) async {
    final composition = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _e1,
        exercise: ExerciseRef.catalog('ex_bench_press'),
        sets: [
          RoutineCompositionSet(
            id: _s1,
            prescription:
                SetPrescription(reps: 8, loadKg: 0, restSeconds: 60),
          ),
        ],
      ),
    ]);
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(composition),
    );

    expect(find.byKey(const ValueKey('routine-detail-page')), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('SET'), findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(find.text('1 exercise · 1 set'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('0'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-entry-$_e1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-set-$_s1')),
        findsOneWidget);
    // Small Routines must not gain a nested scrolling surface.
    expect(find.byKey(const ValueKey('routine-detail-set-list-$_e1')),
        findsNothing);
    expect(find.text('Start Workout'), findsNothing);
    expect(find.text('5 min cardio'), findsNothing);
  });

  testWidgets('load display follows kg/lb preference and avoids guesses',
      (tester) async {
    final composition = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _e1,
        exercise: ExerciseRef.catalog('ex_bench_press'),
        sets: [
          RoutineCompositionSet(
            id: _s1,
            prescription:
                SetPrescription(reps: 5, loadKg: 12.5, restSeconds: 90),
          ),
        ],
      ),
    ]);
    final routines = _Routines([_routine]);
    final compositions = _Compositions(composition);

    await _pump(tester,
        routines: routines,
        compositions: compositions,
        weightUnit: WeightUnit.kg);
    expect(find.text('12.5'),
        findsOneWidget);

    await _pump(tester,
        routines: routines,
        compositions: compositions,
        weightUnit: WeightUnit.lb);
    expect(find.text('27.6'),
        findsOneWidget);
    expect(find.text('12.5'),
        findsNothing);

    // No fabricated default on a route whose Profile data has not resolved.
    await _pump(tester,
        routines: routines,
        compositions: compositions,
        weightUnit: null);
    expect(find.text('Load unavailable'),
        findsOneWidget);
    expect(find.text('12.5'),
        findsNothing);
  });

  testWidgets('legacy Treadmill and Plank targets remain visible after catalog reprofile',
      (tester) async {
    final old = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _e1,
        exercise: ExerciseRef.catalog('ex_run_on_treadmill'),
        sets: [
          RoutineCompositionSet(
            id: _s1,
            prescription: SetPrescription(reps: 6, loadKg: 22),
          ),
        ],
      ),
    ]);
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(old),
    );
    expect(find.text('Run on Treadmill'), findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(find.text('KM'), findsNothing);
    expect(find.text('TIME'), findsNothing);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(_snapshot(entries: [
        RoutineCompositionEntry(
          id: _e1,
          exercise: ExerciseRef.catalog('ex_front_plank'),
          sets: [
            RoutineCompositionSet(
              id: _s1,
              prescription: SetPrescription(reps: 60),
            ),
          ],
        ),
      ])),
    );
    expect(find.text('Front Plank'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(find.text('TIME'), findsNothing);
    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('Custom missing type still displays persisted KM/TIME targets',
      (tester) async {
    final historic = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _e1,
        exercise: ExerciseRef.userCreated(
          '90000000-0000-4000-8000-000000000001',
        ),
        sets: [
          RoutineCompositionSet(
            id: _s1,
            prescription: SetPrescription(
              distanceMeters: 3000, durationSeconds: 900,
            ),
          ),
        ],
      ),
    ]);
    // No Custom metadata is available; canonical type is null. Read-only
    // Detail must render stored metric values rather than fake KG/REPS.
    await _pump(tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(historic),
    );
    expect(find.text('KM'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('REPS'), findsNothing);
    expect(find.text('KG'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty persisted Routine shows truthful empty state',
      (tester) async {
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(_snapshot()),
    );

    expect(find.byKey(const ValueKey('routine-detail-empty')), findsOneWidget);
    expect(find.text('No exercises in this Routine yet.'), findsOneWidget);
    expect(find.text('Start Workout'), findsNothing);
  });

  testWidgets('Exercises row owns the only Edit action on ready-empty Routine',
      (tester) async {
    var edits = 0;
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(_snapshot()),
      onEditPressed: (_) async {
        edits++;
        return false;
      },
    );

    final header = find.byKey(
      const ValueKey('routine-detail-exercises-header'),
    );
    final edit = find.byKey(const ValueKey('routine-detail-edit'));
    expect(header, findsOneWidget);
    expect(edit, findsOneWidget);
    final headerRow = find.ancestor(
      of: header,
      matching: find.byType(Row),
    ).first;
    expect(find.descendant(of: headerRow, matching: edit), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TioAppBar),
        matching: edit,
      ),
      findsNothing,
      reason: 'Edit Routine must not appear in the top app bar',
    );
    expect(find.text('0 exercises · 0 sets'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-empty')), findsOneWidget);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exercises and Edit stay together at compact width in both themes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    for (final theme in [TioThemeMode.light, TioThemeMode.dark]) {
      await _pump(
        tester,
        routines: _Routines([_routine]),
        compositions: _Compositions(_snapshot()),
        mode: theme,
        onEditPressed: (_) async => false,
      );

      final header = find.byKey(
        const ValueKey('routine-detail-exercises-header'),
      );
      final edit = find.byKey(const ValueKey('routine-detail-edit'));
      expect(header, findsOneWidget);
      expect(edit, findsOneWidget);
      final row = find.ancestor(of: header, matching: find.byType(Row)).first;
      expect(find.descendant(of: row, matching: edit), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('missing repository fails closed without fabricated content',
      (tester) async {
    await _pump(tester, routines: _Routines([_routine]), compositions: null);
    expect(find.byKey(const ValueKey('routine-detail-unavailable')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-entries')), findsNothing);
  });

  testWidgets('missing owner association cannot expose composition',
      (tester) async {
    final comp = _Compositions(_snapshot());
    await _pump(
      tester,
      routines: _Routines([]),
      compositions: comp,
    );
    expect(find.byKey(const ValueKey('routine-detail-not-found')),
        findsOneWidget);
    expect(comp.readCount, 0);
  });

  testWidgets('cross-Program selection fails without composition read',
      (tester) async {
    final comp = _Compositions(_snapshot());
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: comp,
      selected: Routine(
        id: RoutineId(_r1),
        programId: ProgramId(_p2),
        name: 'Foreign',
      ),
    );
    expect(find.byKey(const ValueKey('routine-detail-not-found')),
        findsOneWidget);
    expect(comp.readCount, 0);
  });

  testWidgets('network failure offers retry and later owner data',
      (tester) async {
    final comp = _Compositions(_snapshot())..failures = 1;
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: comp,
    );
    expect(find.byKey(const ValueKey('routine-detail-failed')), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-entries')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('routine-detail-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-detail-empty')), findsOneWidget);
  });

  testWidgets('missing reference shows unavailable, never an invented Exercise',
      (tester) async {
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(_snapshot(entries: [
        RoutineCompositionEntry(
          id: _e1,
          exercise: ExerciseRef.catalog('ex_unknown'),
        ),
      ])),
    );
    expect(find.text('Exercise unavailable'), findsOneWidget);
    expect(find.text('Exercise information is not available in this app.'),
        findsOneWidget);
    expect(find.text('No sets prescribed'), findsOneWidget);
  });

  testWidgets('Edit action is gated by ready owner data and resolved unit',
      (tester) async {
    final compositions = _Compositions(_snapshot());
    var calls = 0;
    Future<bool?> navigate(Routine owned) async {
      calls++;
      expect(owned.id, _routine.id);
      return false;
    }

    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: compositions,
      onEditPressed: navigate,
      weightUnit: null,
    );
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsNothing);

    await _pump(
      tester,
      routines: _Routines([]),
      compositions: compositions,
      onEditPressed: navigate,
    );
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsNothing);
    expect(calls, 0);

    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: compositions,
      onEditPressed: navigate,
    );
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    // Cancel/Back does not trigger a new composition read.
    expect(compositions.readCount, 2);
  });

  testWidgets('confirmed editor return re-reads persisted Routine Detail',
      (tester) async {
    final compositions = _Compositions(_snapshot());
    var callbacks = 0;
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: compositions,
      onEditPressed: (owned) async {
        callbacks++;
        compositions.snapshot = _snapshot(entries: [
          RoutineCompositionEntry(
            id: _e1,
            exercise: ExerciseRef.catalog('ex_bench_press'),
            sets: [
              RoutineCompositionSet(
                id: _s1,
                prescription: SetPrescription(reps: 10, restSeconds: 45),
              ),
            ],
          ),
        ]);
        return true; // Existing revision-guarded Editor confirmed Update.
      },
    );
    expect(find.byKey(const ValueKey('routine-detail-empty')), findsOneWidget);
    expect(compositions.readCount, 1);

    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();

    expect(callbacks, 1);
    expect(compositions.readCount, 2);
    expect(find.text('1 exercise · 1 set'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('Detail to real Edit screen saves once and refreshes server truth',
      (tester) async {
    final comp = _Compositions(_snapshot());
    final routines = _Routines([_routine]);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: RoutineDetailPage(
          program: _program,
          routine: _routine,
          routineRepository: routines,
          compositionRepository: comp,
          catalogRepository: _Catalog(),
          weightUnit: WeightUnit.kg,
          onEditPressed: (owned) =>
              navigatorKey.currentState!.push<bool>(
            MaterialPageRoute(
              builder: (_) => EditRoutinePage(
                program: _program,
                routine: owned,
                routineRepository: routines,
                compositionRepository: comp,
                catalogRepository: _Catalog(),
                weightUnit: WeightUnit.kg,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-detail-empty')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-page')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 exercise'), findsOneWidget);
    expect(comp.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(comp.saveCount, 0);
    // Batch confirmation creates Set 1 locally; its target starts blank.
    final row = tester.widget<RoutineSetInputRow>(
      find.byType(RoutineSetInputRow));
    final reps = find.byKey(ValueKey('routine-set-reps-${row.set.id}'));
    final weight = find.byKey(ValueKey('routine-set-weight-${row.set.id}'));
    expect(tester.widget<TioInput>(reps).controller!.text, isEmpty);
    await tester.enterText(reps, '8');
    await tester.enterText(weight, '12');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();

    expect(comp.saveCount, 1);
    expect(comp.readCount, 3); // initial Detail + Editor + refreshed Detail
    expect(find.byKey(const ValueKey('routine-detail-page')), findsOneWidget);
    expect(find.text('1 exercise · 1 set'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('read failure and missing repositories never expose Edit',
      (tester) async {
    final comp = _Compositions(_snapshot())..failures = 1;
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: comp,
      onEditPressed: (_) async => true,
    );
    expect(find.byKey(const ValueKey('routine-detail-failed')), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsNothing);

    await _pump(
      tester,
      routines: null,
      compositions: comp,
      onEditPressed: (_) async => true,
    );
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsNothing);
  });

  testWidgets('long Routine builds only visible cards until scrolling',
      (tester) async {
    final entries = [
      for (var i = 1; i <= 80; i++)
        RoutineCompositionEntry(
          id: '30000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          exercise: ExerciseRef.catalog('ex_bench_press'),
        ),
    ];
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(_snapshot(entries: entries)),
    );
    expect(find.text('80 exercises · 0 sets'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-entry-30000000-0000-4000-8000-000000000001')), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-entry-30000000-0000-4000-8000-000000000080')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one Exercise with 1007 sets builds rows lazily and reaches last',
      (tester) async {
    const totalSets = 1007;
    String setId(int i) =>
        '40000000-0000-4000-8000-${i.toString().padLeft(12, '0')}';
    final composition = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _e1,
        exercise: ExerciseRef.catalog('ex_bench_press'),
        sets: [
          for (var i = 1; i <= totalSets; i++)
            RoutineCompositionSet(
              id: setId(i),
              prescription: SetPrescription(reps: 8),
            ),
        ],
      ),
    ]);

    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(composition),
    );
    expect(find.text('1 exercise · 1007 sets'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-entry-$_e1')),
        findsOneWidget);
    final innerList =
        find.byKey(const ValueKey('routine-detail-set-list-$_e1'));
    expect(innerList, findsOneWidget);
    expect(find.byKey(ValueKey('routine-detail-set-${setId(1)}')),
        findsOneWidget);
    expect(find.byKey(ValueKey('routine-detail-set-${setId(totalSets)}')),
        findsNothing);

    // Scroll the inner lazy list, not the parent Routine/Exercise list.
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('routine-detail-set-${setId(totalSets)}')),
      1800,
      scrollable: find.descendant(
        of: innerList,
        matching: find.byType(Scrollable),
      ),
      maxScrolls: 80,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('routine-detail-set-${setId(totalSets)}')),
        findsOneWidget);
    expect(find.text('1007'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact dark screen retains readable detail and back control',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      routines: _Routines([_routine]),
      compositions: _Compositions(_snapshot()),
      mode: TioThemeMode.dark,
    );
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _Routines implements RoutineRepository {
  _Routines(this.rows);
  final List<Routine> rows;

  @override
  Future<List<Routine>> list(ProgramId programId) async =>
      rows.where((row) => row.programId == programId).toList();

  @override
  Future<void> create(Routine routine) async => throw UnimplementedError();

  @override
  Future<void> rename({required RoutineId id, required String name}) async =>
      throw UnimplementedError();
}

final class _Compositions implements RoutineCompositionRepository {
  _Compositions(this.snapshot);
  RoutineCompositionSnapshot? snapshot;
  int readCount = 0;
  int failures = 0;
  int saveCount = 0;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId routineId) async {
    readCount++;
    if (failures > 0) {
      failures--;
      throw StateError('lost connection');
    }
    return snapshot;
  }

  @override
  Future<int> save(RoutineCompositionSave command) async {
    saveCount++;
    final nextRevision = command.expectedRevision + 1;
    snapshot = RoutineCompositionSnapshot(
      routineId: command.routineId,
      revision: nextRevision,
      lastMutationId: command.mutationId,
      entries: command.entries,
    );
    return nextRevision;
  }
}

final class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.catalog('ex_bench_press'),
          displayName: 'Bench Press',
          status: ExerciseStatus.active,
        ),
        Exercise(
          ref: ExerciseRef.catalog('ex_run_on_treadmill'),
          displayName: 'Run on Treadmill',
          status: ExerciseStatus.active,
          exerciseType: ExerciseType.distanceDuration,
        ),
        Exercise(
          ref: ExerciseRef.catalog('ex_front_plank'),
          displayName: 'Front Plank',
          status: ExerciseStatus.active,
          exerciseType: ExerciseType.duration,
        ),
      ]);
}
