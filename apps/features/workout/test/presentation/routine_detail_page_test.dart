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
    expect(find.text('1 exercises · 1 sets'), findsOneWidget);
    expect(find.text('1. Bench Press'), findsOneWidget);
    expect(find.text('Set 1 · 8 reps · 0.0 kg · 60 sec rest'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-entry-$_e1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-set-$_s1')),
        findsOneWidget);
    expect(find.text('Start Workout'), findsNothing);
    expect(find.text('5 min cardio'), findsNothing);
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
    expect(find.text('1. Exercise unavailable'), findsOneWidget);
    expect(find.text('Exercise information is not available in this app.'),
        findsOneWidget);
    expect(find.text('No sets prescribed'), findsOneWidget);
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
  final RoutineCompositionSnapshot? snapshot;
  int readCount = 0;
  int failures = 0;

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
  Future<int> save(RoutineCompositionSave command) async =>
      throw UnimplementedError();
}

final class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.catalog('ex_bench_press'),
          displayName: 'Bench Press',
          status: ExerciseStatus.active,
        ),
      ]);
}
