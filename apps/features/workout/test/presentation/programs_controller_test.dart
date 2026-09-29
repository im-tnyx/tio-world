import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('loads persisted Programs into ready state', () async {
    final repository = _FakeProgramRepository(
      programs: [_program(1, 'Strength')],
    );
    final controller = ProgramsController(
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(2)]),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state.status, ProgramsStatus.ready);
    expect(controller.state.programs, [_program(1, 'Strength')]);
    expect(repository.listCalls, 1);
  });

  test('load failure exposes retry and later recovers', () async {
    final repository = _FakeProgramRepository(
      programs: [_program(1, 'Strength')],
      loadFailuresRemaining: 1,
    );
    final controller = ProgramsController(
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(2)]),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.status, ProgramsStatus.loadFailed);
    expect(controller.state.loadError, contains('Could not load programs'));

    await controller.retryLoad();
    expect(controller.state.status, ProgramsStatus.ready);
    expect(controller.state.programs.single.name, 'Strength');
  });

  test('suggestedName chooses the first unused Program number', () async {
    final repository = _FakeProgramRepository(
      programs: [
        _program(1, 'Program 1'),
        _program(2, ' program 2 '),
        _program(3, 'Strength'),
      ],
    );
    final controller = ProgramsController(
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(4)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.suggestedName(), 'Program 3');
  });

  test('create persists exactly one Program and updates the collection',
      () async {
    final repository = _FakeProgramRepository();
    final controller = ProgramsController(
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(1)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final created = await controller.create('Strength');

    expect(created, isTrue);
    expect(repository.created, hasLength(1));
    expect(repository.created.single, _program(1, 'Strength'));
    expect(controller.state.programs, [_program(1, 'Strength')]);
    expect(controller.state.createError, isNull);
  });

  test('create failure keeps the canonical list unchanged', () async {
    final repository = _FakeProgramRepository(
      programs: [_program(1, 'Existing')],
      createError: Exception('network down'),
    );
    final controller = ProgramsController(
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(2)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final created = await controller.create('Strength');

    expect(created, isFalse);
    expect(controller.state.programs, [_program(1, 'Existing')]);
    expect(controller.state.createError, contains('Could not create program'));
  });
}

ProgramId _id(int value) => ProgramId(
      '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}',
    );

Program _program(int value, String name) => Program(id: _id(value), name: name);

final class _QueueProgramIdGenerator implements ProgramIdGenerator {
  _QueueProgramIdGenerator(this.ids);

  final List<ProgramId> ids;
  var index = 0;

  @override
  ProgramId generate(Iterable<ProgramId> existingIds) => ids[index++];
}

final class _FakeProgramRepository implements ProgramRepository {
  _FakeProgramRepository({
    List<Program>? programs,
    this.loadFailuresRemaining = 0,
    this.createError,
  }) : programs = [...?programs];

  final List<Program> programs;
  final List<Program> created = [];
  int loadFailuresRemaining;
  Object? createError;
  int listCalls = 0;

  @override
  Future<List<Program>> list() async {
    listCalls++;
    if (loadFailuresRemaining > 0) {
      loadFailuresRemaining--;
      throw Exception('load failed');
    }
    return List.unmodifiable(programs);
  }

  @override
  Future<void> create(Program program) async {
    final error = createError;
    if (error != null) throw error;
    created.add(program);
    programs.add(program);
  }

  @override
  Future<void> rename({
    required ProgramId id,
    required String name,
  }) async {
    throw UnimplementedError();
  }
}
