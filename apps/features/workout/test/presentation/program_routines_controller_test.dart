import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('list is scoped to the selected owning Program', () async {
    final repository = _FakeRoutines([
      _routine(1, 11, 'Push'),
      _routine(2, 21, 'Pull'),
    ]);
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.status, ProgramRoutinesStatus.ready);
    expect(repository.lastListProgramId, _program(1).id);
    expect(controller.state.routines, [_routine(1, 11, 'Push')]);
  });

  test('missing/invalid cross-owner rows fail closed instead of showing them',
      () async {
    final repository = _FakeRoutines([_routine(2, 21, 'Foreign')])
      ..returnForeign = true;
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.status, ProgramRoutinesStatus.loadFailed);
    expect(controller.state.routines, isEmpty);
  });

  test('load failure retries from same ProgramId', () async {
    final repository = _FakeRoutines()..loadFailures = 1;
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, ProgramRoutinesStatus.loadFailed);
    await controller.retryLoad();
    expect(controller.state.status, ProgramRoutinesStatus.ready);
    expect(repository.lastListProgramId, _program(1).id);
  });

  test('suggested generated name skips existing case-insensitive names',
      () async {
    final repository = _FakeRoutines([
      _routine(1, 11, 'Routine 1'),
      _routine(1, 12, ' routine 2 '),
    ]);
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.suggestedName(), 'Routine 3');
  });

  test('create persists exactly one Program-owned Routine', () async {
    final repository = _FakeRoutines();
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('Strength'), isTrue);
    expect(repository.attempted, [_routine(1, 41, 'Strength')]);
    expect(controller.state.routines.single.programId, _program(1).id);
    expect(controller.state.routines.single.name, 'Strength');
  });

  test('lost create response reconciles one durable Routine', () async {
    final repository = _FakeRoutines()..throwAfterCreate = true;
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('Strength'), isTrue);
    expect(repository.attempted, hasLength(1));
    expect(repository.rows, hasLength(1));
    expect(controller.state.routines.single.id, _rid(41));
  });

  test('unconfirmed failure keeps the same UUID across retry', () async {
    final repository = _FakeRoutines()..throwBeforeCreate = true;
    var generated = 0;
    final controller = ProgramRoutinesController(
      program: _program(1),
      repository: repository,
      newRoutineUuid: () {
        generated++;
        return _rid(generated + 40).value;
      },
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('First attempt'), isFalse);
    repository.throwBeforeCreate = false;
    expect(await controller.create('Second attempt'), isTrue);

    expect(generated, 1);
    expect(repository.attempted.map((r) => r.id), [_rid(41), _rid(41)]);
    expect(repository.rows.single.name, 'Second attempt');
  });

  test('unauthenticated creates expose sign-in requirement', () async {
    final repository = _FakeRoutines()..unauthenticated = true;
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('Morning'), isFalse);
    expect(controller.state.error, 'Please sign in to save Routines.');
    expect(controller.state.routines, isEmpty);
  });

  test('rename is verified by owner-scoped read', () async {
    final repository = _FakeRoutines([_routine(1, 11, 'Morning')]);
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    final result = await controller.rename(
      routine: controller.state.routines.single,
      name: 'Evening',
    );
    expect(result, isNull);
    expect(repository.rows.single.name, 'Evening');
    expect(controller.state.routines.single.name, 'Evening');
    expect(repository.lastListProgramId, _program(1).id);
  });

  test('lost rename response reconciles when name persisted', () async {
    final repository = _FakeRoutines([_routine(1, 11, 'Morning')])
      ..throwAfterRename = true;
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();
    expect(
      await controller.rename(
        routine: controller.state.routines.single,
        name: 'Evening',
      ),
      isNull,
    );
    expect(controller.state.routines.single.name, 'Evening');
  });

  test('rename cannot target another Program', () async {
    final repository = _FakeRoutines([_routine(1, 11, 'Morning')]);
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    final result = await controller.rename(
      routine: _routine(2, 21, 'Foreign'),
      name: 'Hijacked',
    );
    expect(result, isNotNull);
    expect(repository.renameCount, 0);
  });

  test('zero-row rename does not falsely report success', () async {
    final repository = _FakeRoutines([_routine(1, 11, 'Morning')])
      ..ignoreRename = true;
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    final result = await controller.rename(
      routine: controller.state.routines.single,
      name: 'Evening',
    );
    expect(result, contains('Could not confirm'));
    expect(controller.state.routines.single.name, 'Morning');
  });
}

Program _program(int number) => Program(
      id: ProgramId('10000000-0000-4000-8000-${number.toString().padLeft(12, '0')}'),
      name: 'Program $number',
    );

RoutineId _rid(int number) => RoutineId(
      '20000000-0000-4000-8000-${number.toString().padLeft(12, '0')}',
    );

Routine _routine(int program, int id, String name) => Routine(
      id: _rid(id),
      programId: _program(program).id,
      name: name,
    );

ProgramRoutinesController _controller(_FakeRoutines repository) =>
    ProgramRoutinesController(
      program: _program(1),
      repository: repository,
      newRoutineUuid: () => _rid(41).value,
    );

final class _FakeRoutines implements RoutineRepository {
  _FakeRoutines([List<Routine> initial = const []]) : rows = [...initial];

  final List<Routine> rows;
  final List<Routine> attempted = [];
  ProgramId? lastListProgramId;
  int loadFailures = 0;
  int renameCount = 0;
  bool returnForeign = false;
  bool throwBeforeCreate = false;
  bool throwAfterCreate = false;
  bool throwAfterRename = false;
  bool ignoreRename = false;
  bool unauthenticated = false;

  @override
  Future<List<Routine>> list(ProgramId programId) async {
    lastListProgramId = programId;
    if (loadFailures > 0) {
      loadFailures--;
      throw Exception('network');
    }
    return List.unmodifiable(returnForeign
        ? rows
        : rows.where((routine) => routine.programId == programId));
  }

  @override
  Future<void> create(Routine routine) async {
    attempted.add(routine);
    if (unauthenticated) {
      throw StateError('Please sign in to save Routines.');
    }
    if (throwBeforeCreate) throw Exception('network');
    if (rows.any((existing) => existing.id == routine.id)) {
      throw StateError('duplicate');
    }
    rows.add(routine);
    if (throwAfterCreate) throw Exception('lost response');
  }

  @override
  Future<void> rename({required RoutineId id, required String name}) async {
    renameCount++;
    if (ignoreRename) return;
    final idx = rows.indexWhere((r) => r.id == id);
    if (idx == -1) throw StateError('missing');
    final old = rows[idx];
    rows[idx] = Routine(id: old.id, programId: old.programId, name: name);
    if (throwAfterRename) throw Exception('lost response');
  }
}
