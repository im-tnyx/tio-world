import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _p = '10000000-0000-4000-8000-000000000001';
const _other = '10000000-0000-4000-8000-000000000002';
const _r = '20000000-0000-4000-8000-000000000001';
const _entryId = '30000000-0000-4000-8000-000000000001';
const _setId = '40000000-0000-4000-8000-000000000001';
const _exerciseRef = 'ex_bench_press';
const _newCustomRef = '70000000-0000-4000-8000-000000000001';

Program get _program => Program(id: ProgramId(_p), name: 'Strength');
Routine get _routine =>
    Routine(id: RoutineId(_r), programId: ProgramId(_p), name: 'Push Day');

RoutineCompositionEntry _entry({
  double? kg = 12.54321,
  int reps = 8,
  int? rest = 60,
}) => RoutineCompositionEntry(
      id: _entryId,
      exercise: ExerciseRef.catalog(_exerciseRef),
      sets: [
        RoutineCompositionSet(
          id: _setId,
          prescription: SetPrescription(
            reps: reps,
            loadKg: kg,
            restSeconds: rest,
          ),
        ),
      ],
    );

RoutineCompositionSnapshot _snapshot({
  List<RoutineCompositionEntry>? entries,
  int revision = 4,
  String? mutation,
}) => RoutineCompositionSnapshot(
      routineId: RoutineId(_r),
      revision: revision,
      lastMutationId: mutation,
      entries: entries ?? [_entry()],
    );

class _Fixtures {
  _Fixtures({this.unit = WeightUnit.kg, this.routine, this.repositoryAvailable = true})
      : compositions = _Compositions(_snapshot()),
        catalog = _Catalog(),
        users = _Users();

  final WeightUnit? unit;
  final Routine? routine;
  final bool repositoryAvailable;
  final _Compositions compositions;
  final _Catalog catalog;
  final _Users users;
  final _Routines routines = _Routines();
  bool? editorResult;
  int nextId = 0;

  String newId() {
    nextId++;
    return '90000000-0000-4000-8000-${nextId.toString().padLeft(12, '0')}';
  }

  Future<void> open(WidgetTester tester, {TioThemeMode mode = TioThemeMode.light}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              editorResult = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditRoutinePage(
                    program: _program,
                    routine: routine ?? _routine,
                    routineRepository:
                        repositoryAvailable ? routines : null,
                    compositionRepository:
                        repositoryAvailable ? compositions : null,
                    catalogRepository: catalog,
                    userExerciseRepository: users,
                    weightUnit: unit,
                    newUuid: newId,
                  ),
                ),
              );
            },
            child: const Text('Open editor'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('empty Routine offers Add Exercise without a database write',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    await f.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-picker-page')),
        findsOneWidget);
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-entry-90000000-0000-4000-8000-000000000001')),
        findsOneWidget);
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-cancel')));
    await tester.pumpAndSettle();
    expect(f.editorResult, isFalse);
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('picker returns freshly created Custom even when editor source is stale',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    await f.open(tester);
    expect(f.users.listCalls, 1);

    // A second device created this exercise after editor _source loaded.
    // The picker loads a new owner-scoped snapshot that includes it.
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'Fresh Custom Lift',
        status: ExerciseStatus.active,
      ),
    ];
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('Fresh Custom Lift'), findsOneWidget);
    expect(f.users.listCalls, 2);
    await tester.tap(find.text('Fresh Custom Lift'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(
        'edit-routine-entry-90000000-0000-4000-8000-000000000001')),
        findsOneWidget);
    expect(find.text('1. Fresh Custom Lift'), findsOneWidget);
    expect(f.users.listCalls, 3); // Refresh editor source for safe Update.
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    expect(f.compositions.lastSave!.entries.single.exercise,
        UserCreatedExerciseRef(_newCustomRef));
    expect(f.editorResult, isTrue);
    expect(f.users.writeCalls, 0);
  });

  testWidgets('editing reps preserves exact canonical kg and Set UUID',
      (tester) async {
    final f = _Fixtures(unit: WeightUnit.lb);
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-set-edit-$_setId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-set-weight')), findsOneWidget);
    expect(find.text('Edit Set'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('routine-set-reps')), '12');
    await tester.tap(find.byKey(const ValueKey('routine-set-confirm')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    final saved = f.compositions.lastSave!;
    expect(saved.expectedRevision, 4);
    expect(saved.entries.single.id, _entryId);
    expect(saved.entries.single.sets.single.id, _setId);
    expect(saved.entries.single.sets.single.prescription.reps, 12);
    expect(saved.entries.single.sets.single.prescription.loadKg, 12.54321);
    expect(f.editorResult, isTrue);
  });

  testWidgets('invalid Reps and negative Weight cannot alter the draft',
      (tester) async {
    final f = _Fixtures();
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-set-$_entryId')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('routine-set-reps')), '0');
    await tester.enterText(find.byKey(const ValueKey('routine-set-weight')), '-5');
    await tester.tap(find.byKey(const ValueKey('routine-set-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-set-validation-error')),
        findsOneWidget);
    expect(f.compositions.saveCount, 0);

    await tester.enterText(find.byKey(const ValueKey('routine-set-reps')), '6');
    await tester.enterText(find.byKey(const ValueKey('routine-set-weight')), '22.046226218487757');
    await tester.enterText(find.byKey(const ValueKey('routine-set-rest')), '0');
    await tester.tap(find.byKey(const ValueKey('routine-set-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    final added = f.compositions.lastSave!.entries.single.sets.last;
    expect(added.prescription.reps, 6);
    expect(added.prescription.restSeconds, 0);
    expect(added.prescription.loadKg, 22.046226218487757);
    expect(added.id, isNot(_setId));
  });

  testWidgets('no repository and cross-Program fail closed', (tester) async {
    final missing = _Fixtures(repositoryAvailable: false);
    await missing.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-unavailable')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-update')), findsNothing);
    expect(missing.compositions.readCount, 0);

    // Dispose the first Navigator stack before creating a second fixture.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final cross = _Fixtures(
      routine: Routine(
        id: RoutineId(_r),
        programId: ProgramId(_other),
        name: 'Other',
      ),
    );
    await cross.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-unavailable')),
        findsOneWidget);
    expect(cross.compositions.readCount, 0);
  });

  testWidgets('missing weight unit blocks form and write', (tester) async {
    final f = _Fixtures(unit: null);
    await f.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-unavailable')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-update')), findsNothing);
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('revision conflict offers explicit Reload, no second save',
      (tester) async {
    final f = _Fixtures();
    f.compositions.error = const RoutineCompositionException(
      RoutineCompositionFailureKind.revisionConflict,
    );
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-entry-remove-$_entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-conflict')), findsOneWidget);
    expect(f.compositions.saveCount, 1);
    expect(find.byKey(const ValueKey('edit-routine-reload')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-reload')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-entry-$_entryId')),
        findsOneWidget);
    expect(f.compositions.saveCount, 1);
  });

  testWidgets('uncertain Update only confirms by matching mutation read',
      (tester) async {
    final f = _Fixtures();
    f.compositions.error = const RoutineCompositionSaveOutcomeUnknown();
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-entry-remove-$_entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-unknown')), findsOneWidget);
    expect(f.compositions.saveCount, 1);
    await tester.tap(find.byKey(const ValueKey('edit-routine-verify')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-unknown')), findsOneWidget);
    expect(f.compositions.saveCount, 1);

    f.compositions.snapshot = _snapshot(
      entries: const [],
      revision: 5,
      mutation: f.compositions.lastSave!.mutationId,
    );
    await tester.tap(find.byKey(const ValueKey('edit-routine-verify')));
    await tester.pumpAndSettle();
    expect(f.editorResult, isTrue);
    expect(f.compositions.saveCount, 1);
  });

  testWidgets('large Routine is lazy, editor reaches first Set safely',
      (tester) async {
    final f = _Fixtures();
    final large = [
      for (var i = 1; i <= 1007; i++)
        RoutineCompositionSet(
          id: '40000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          prescription: SetPrescription(reps: 8),
        ),
    ];
    f.compositions.snapshot = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _entryId,
        exercise: ExerciseRef.catalog(_exerciseRef),
        sets: large,
      ),
    ]);
    await f.open(tester, mode: TioThemeMode.dark);
    expect(find.byKey(const ValueKey('edit-routine-set-list-$_entryId')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-set-40000000-0000-4000-8000-000000001007')),
        findsNothing);
    expect(tester.takeException(), isNull);
    expect(f.compositions.saveCount, 0);
  });
}

final class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
    Exercise(
      ref: ExerciseRef.catalog(_exerciseRef),
      displayName: 'Bench Press',
      status: ExerciseStatus.active,
    ),
  ]);
}

final class _Routines implements RoutineRepository {
  @override
  Future<List<Routine>> list(ProgramId id) async => [_routine];

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
  int saveCount = 0;
  RoutineCompositionSave? lastSave;
  Object? error;
  Completer<void>? saveGate;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId id) async {
    readCount++;
    return snapshot;
  }

  @override
  Future<int> save(RoutineCompositionSave command) async {
    saveCount++;
    lastSave = command;
    if (saveGate != null) await saveGate!.future;
    if (error != null) throw error!;
    snapshot = _snapshot(
      entries: command.entries,
      revision: command.expectedRevision + 1,
      mutation: command.mutationId,
    );
    return command.expectedRevision + 1;
  }
}

final class _Users implements UserExerciseRepository {
  List<Exercise> rows = const [];
  int listCalls = 0;
  int writeCalls = 0;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async {
    listCalls++;
    return List.unmodifiable(rows.where(
      (item) => includeArchived || item.status == ExerciseStatus.active,
    ));
  }

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    writeCalls++;
    throw UnimplementedError();
  }
}
