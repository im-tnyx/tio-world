import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _p1 = '10000000-0000-4000-8000-000000000001';
const _p2 = '10000000-0000-4000-8000-000000000002';
const _r1 = '20000000-0000-4000-8000-000000000001';
const _r2 = '20000000-0000-4000-8000-000000000002';
const _e1 = '30000000-0000-4000-8000-000000000001';
const _e2 = '30000000-0000-4000-8000-000000000002';
const _s1 = '40000000-0000-4000-8000-000000000001';
const _s2 = '40000000-0000-4000-8000-000000000002';
const _custom = '50000000-0000-4000-8000-000000000001';

Program _program(String id) => Program(id: ProgramId(id), name: 'Program');
Routine _routine(String id, String program) =>
    Routine(id: RoutineId(id), programId: ProgramId(program), name: 'Day One');

RoutineCompositionSnapshot _snapshot({
  String routineId = _r1,
  List<RoutineCompositionEntry> entries = const [],
}) => RoutineCompositionSnapshot(
      routineId: RoutineId(routineId),
      revision: 3,
      entries: entries,
    );

RoutineCompositionEntry _entry(
  String id,
  ExerciseRef ref, {
  List<RoutineCompositionSet> sets = const [],
}) => RoutineCompositionEntry(id: id, exercise: ref, sets: sets);

RoutineCompositionSet _set(String id, int reps) => RoutineCompositionSet(
      id: id,
      prescription: SetPrescription(reps: reps, loadKg: 12.5, restSeconds: 45),
    );

RoutineDetailController _controller(
  _Routines routines,
  _Compositions compositions, {
  _Catalog? catalog,
  UserExerciseRepository? userExercises,
  Routine? selected,
}) => RoutineDetailController(
      program: _program(_p1),
      routine: selected ?? _routine(_r1, _p1),
      routines: routines,
      compositions: compositions,
      catalog: catalog ?? _Catalog(),
      userExercises: userExercises,
    );

void main() {
  test('reads only selected owner Routine and preserves repeated entries/sets',
      () async {
    final ref = ExerciseRef.catalog('ex_approved_bench');
    final contents = _snapshot(entries: [
      _entry(_e1, ref, sets: [_set(_s1, 8)]),
      _entry(_e2, ref, sets: [_set(_s2, 10)]),
    ]);
    final routines = _Routines([_routine(_r1, _p1)]);
    final comp = _Compositions(contents);
    final controller = _controller(routines, comp);
    addTearDown(controller.dispose);
    await controller.load();

    expect(routines.lastProgram, ProgramId(_p1));
    expect(comp.requested, RoutineId(_r1));
    expect(controller.state.status, RoutineDetailStatus.ready);
    expect(controller.state.exerciseCount, 2);
    expect(controller.state.setCount, 2);
    expect(controller.state.revision, 3);
    expect(controller.state.entries.map((item) => item.entry.id), [_e1, _e2]);
    expect(controller.state.entries.first.entry.sets.single.id, _s1);
    expect(controller.state.entries.last.entry.sets.single.id, _s2);
    expect(controller.state.entries.first.exercise?.displayName, 'Bench Press');
  });

  test('wrong Program relationship fails before any persisted read', () async {
    final routines = _Routines([_routine(_r1, _p2)]);
    final comp = _Compositions(_snapshot());
    final controller = _controller(
      routines, comp, selected: _routine(_r1, _p2),
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.status, RoutineDetailStatus.notFound);
    expect(routines.lastProgram, isNull);
    expect(comp.requested, isNull);
  });

  test('missing owner Routine does not read its composition', () async {
    final routines = _Routines([_routine(_r2, _p1)]);
    final comp = _Compositions(_snapshot());
    final controller = _controller(routines, comp);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.notFound);
    expect(comp.requested, isNull);
  });

  test('foreign or duplicate rows from repository fail closed', () async {
    final routines = _Routines([_routine(_r1, _p2)]);
    final controller = _controller(routines, _Compositions(_snapshot()));
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.failed);
    expect(controller.state.entries, isEmpty);
  });

  test('inaccessible composition is not found', () async {
    final controller = _controller(
      _Routines([_routine(_r1, _p1)]), _Compositions(null),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.notFound);
  });

  test('mismatched composition identity fails closed', () async {
    final controller = _controller(
      _Routines([_routine(_r1, _p1)]),
      _Compositions(_snapshot(routineId: _r2)),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.failed);
  });

  test('read failures clear content and retry from same owner', () async {
    final routines = _Routines([_routine(_r1, _p1)]);
    final comp = _Compositions(_snapshot())..failures = 1;
    final controller = _controller(routines, comp);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.failed);
    expect(controller.state.entries, isEmpty);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.ready);
    expect(routines.lastProgram, ProgramId(_p1));
  });

  test('archived user Exercise resolves through owner repository', () async {
    final ref = ExerciseRef.userCreated(_custom);
    final users = _Users([
      Exercise(
        ref: ref,
        displayName: 'My archived movement',
        status: ExerciseStatus.archived,
      ),
    ]);
    final controller = _controller(
      _Routines([_routine(_r1, _p1)]),
      _Compositions(_snapshot(entries: [_entry(_e1, ref)])),
      userExercises: users,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(users.includeArchived, isTrue);
    expect(controller.state.entries.single.exercise?.displayName,
        'My archived movement');
  });

  test('missing Exercise never invents a title', () async {
    final controller = _controller(
      _Routines([_routine(_r1, _p1)]),
      _Compositions(_snapshot(entries: [
        _entry(_e1, ExerciseRef.catalog('ex_missing')),
      ])),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.ready);
    expect(controller.state.entries.single.exercise, isNull);
  });

  test('empty composition does not depend on the built-in catalog', () async {
    final catalog = _Catalog()..failures = 1;
    final controller = _controller(
      _Routines([_routine(_r1, _p1)]),
      _Compositions(_snapshot()),
      catalog: catalog,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.ready);
    expect(controller.state.entries, isEmpty);
    expect(catalog.loadCount, 0);
  });

  test('custom-only composition reads without loading bundled catalog',
      () async {
    final catalog = _Catalog()..failures = 1;
    final ref = ExerciseRef.userCreated(_custom);
    final users = _Users([
      Exercise(ref: ref, displayName: 'Custom Curl', status: ExerciseStatus.active),
    ]);
    final controller = _controller(
      _Routines([_routine(_r1, _p1)]),
      _Compositions(_snapshot(entries: [_entry(_e1, ref)])),
      catalog: catalog,
      userExercises: users,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.ready);
    expect(controller.state.entries.single.exercise?.displayName, 'Custom Curl');
    expect(catalog.loadCount, 0);
    expect(users.includeArchived, isTrue);
  });

  test('Exercise source failure hides private snapshot and offers retry',
      () async {
    final catalog = _Catalog()..failures = 1;
    final controller = _controller(
      _Routines([_routine(_r1, _p1)]),
      _Compositions(_snapshot(entries: [
        _entry(_e1, ExerciseRef.catalog('ex_approved_bench')),
      ])),
      catalog: catalog,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.failed);
    expect(controller.state.entries, isEmpty);
    await controller.load();
    expect(controller.state.status, RoutineDetailStatus.ready);
  });
}

final class _Routines implements RoutineRepository {
  _Routines(this.rows);
  final List<Routine> rows;
  ProgramId? lastProgram;

  @override
  Future<List<Routine>> list(ProgramId programId) async {
    lastProgram = programId;
    return rows;
  }

  @override
  Future<void> create(Routine routine) async => throw UnimplementedError();

  @override
  Future<void> rename({required RoutineId id, required String name}) async =>
      throw UnimplementedError();
}

final class _Compositions implements RoutineCompositionRepository {
  _Compositions(this.result);
  final RoutineCompositionSnapshot? result;
  int failures = 0;
  RoutineId? requested;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId routineId) async {
    requested = routineId;
    if (failures > 0) {
      failures--;
      throw StateError('permission');
    }
    return result;
  }

  @override
  Future<int> save(RoutineCompositionSave command) async =>
      throw UnimplementedError();
}

final class _Catalog implements ExerciseCatalogRepository {
  int failures = 0;
  int loadCount = 0;

  @override
  Future<ExerciseCatalog> load() async {
    loadCount++;
    if (failures > 0) {
      failures--;
      throw StateError('catalog unavailable');
    }
    return ExerciseCatalog([
      Exercise(
        ref: ExerciseRef.catalog('ex_approved_bench'),
        displayName: 'Bench Press',
        status: ExerciseStatus.active,
      ),
    ]);
  }
}

final class _Users implements UserExerciseRepository {
  _Users(this.rows);
  final List<Exercise> rows;
  bool? includeArchived;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async {
    this.includeArchived = includeArchived;
    return rows;
  }

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async => throw UnimplementedError();

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async => throw UnimplementedError();

  @override
  Future<void> archive(UserCreatedExerciseRef id) async =>
      throw UnimplementedError();
}
