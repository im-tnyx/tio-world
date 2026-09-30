import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('loads persisted active Custom Exercises into ready state', () async {
    final repository = _FakeUserExerciseRepository(
      exercises: [_exercise(1, 'Paused Squat')],
    );
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(2)]),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state.status, CustomExercisesStatus.ready);
    expect(controller.state.exercises, [_exercise(1, 'Paused Squat')]);
    expect(repository.listCalls, 1);
  });

  test('load failure exposes retry and later recovers', () async {
    final repository = _FakeUserExerciseRepository(
      exercises: [_exercise(1, 'Paused Squat')],
      loadFailuresRemaining: 1,
    );
    final controller = CustomExercisesController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.status, CustomExercisesStatus.loadFailed);
    expect(controller.state.loadError, contains('Could not load custom exercises'));

    await controller.retryLoad();
    expect(controller.state.status, CustomExercisesStatus.ready);
    expect(controller.state.exercises.single.displayName, 'Paused Squat');
  });

  test('create persists exactly one user Exercise and updates active list',
      () async {
    final repository = _FakeUserExerciseRepository();
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final created = await controller.create('Paused Squat');

    expect(created, isTrue);
    expect(repository.attemptedCreateIds, [_id(1)]);
    expect(repository.exercises, [_exercise(1, 'Paused Squat')]);
    expect(controller.state.exercises, [_exercise(1, 'Paused Squat')]);
    expect(controller.state.actionError, isNull);
  });

  test('blank create is rejected without touching persistence', () async {
    final repository = _FakeUserExerciseRepository();
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('   '), isFalse);

    expect(repository.attemptedCreateIds, isEmpty);
    expect(controller.state.actionError, 'Enter an exercise name.');
  });

  test('ambiguous create response reconciles the durable Exercise', () async {
    final repository = _FakeUserExerciseRepository(
      createErrorAfterWrite: Exception('response lost'),
    );
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final created = await controller.create('Paused Squat');

    expect(created, isTrue);
    expect(repository.attemptedCreateIds, [_id(1)]);
    expect(repository.exercises, [_exercise(1, 'Paused Squat')]);
    expect(controller.state.exercises, [_exercise(1, 'Paused Squat')]);
    expect(repository.listCalls, 2);
  });

  test('retry after unresolved create failure reuses the same Exercise id',
      () async {
    final repository = _FakeUserExerciseRepository(
      createError: Exception('network down'),
    );
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1), _id(2)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('Paused Squat'), isFalse);
    repository.createError = null;
    expect(await controller.create('Paused Squat'), isTrue);

    expect(repository.attemptedCreateIds, [_id(1), _id(1)]);
    expect(repository.exercises, [_exercise(1, 'Paused Squat')]);
  });

  test('rename updates the active item and preserves canonical metadata',
      () async {
    final original = Exercise(
      ref: _id(1),
      displayName: 'Paused Squat',
      muscleGroup: 'upper_legs',
      primaryMuscles: const ['quadriceps'],
      primaryEquipment: 'barbell',
      category: 'strength',
      levels: const ['intermediate'],
      status: ExerciseStatus.active,
    );
    final repository = _FakeUserExerciseRepository(exercises: [original]);
    final controller = CustomExercisesController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(
      await controller.rename(id: _id(1), displayName: 'Tempo Squat'),
      isTrue,
    );

    final renamed = controller.state.exercises.single;
    expect(renamed.displayName, 'Tempo Squat');
    expect(renamed.muscleGroup, original.muscleGroup);
    expect(renamed.primaryMuscles, original.primaryMuscles);
    expect(renamed.primaryEquipment, original.primaryEquipment);
    expect(renamed.category, original.category);
    expect(renamed.levels, original.levels);
  });

  test('archive removes the Exercise from the active controller view',
      () async {
    final repository = _FakeUserExerciseRepository(
      exercises: [_exercise(1, 'Paused Squat'), _exercise(2, 'Tempo Bench')],
    );
    final controller = CustomExercisesController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.archive(_id(1)), isTrue);

    expect(controller.state.exercises, [_exercise(2, 'Tempo Bench')]);
    expect(
      (await repository.list(includeArchived: true))
          .firstWhere((exercise) => exercise.ref == _id(1))
          .status,
      ExerciseStatus.archived,
    );
  });

  test('write failure keeps active list and exposes sign-in error', () async {
    final repository = _FakeUserExerciseRepository(
      exercises: [_exercise(1, 'Paused Squat')],
      renameError: StateError('Please sign in to save Exercises.'),
    );
    final controller = CustomExercisesController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(
      await controller.rename(id: _id(1), displayName: 'Tempo Squat'),
      isFalse,
    );

    expect(controller.state.exercises, [_exercise(1, 'Paused Squat')]);
    expect(controller.state.actionError, 'Please sign in to save Exercises.');
  });
}

UserCreatedExerciseRef _id(int value) => UserCreatedExerciseRef(
      '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}',
    );

Exercise _exercise(int value, String name) => Exercise(
      ref: _id(value),
      displayName: name,
      status: ExerciseStatus.active,
    );

Exercise _copyExercise(
  Exercise exercise, {
  String? displayName,
  ExerciseStatus? status,
}) =>
    Exercise(
      ref: exercise.ref,
      displayName: displayName ?? exercise.displayName,
      muscleGroup: exercise.muscleGroup,
      primaryMuscles: exercise.primaryMuscles,
      secondaryMuscles: exercise.secondaryMuscles,
      primaryEquipment: exercise.primaryEquipment,
      category: exercise.category,
      levels: exercise.levels,
      status: status ?? exercise.status,
      media: exercise.media,
    );

final class _QueueUserExerciseIdGenerator implements UserExerciseIdGenerator {
  _QueueUserExerciseIdGenerator(this.ids);

  final List<UserCreatedExerciseRef> ids;
  var index = 0;

  @override
  UserCreatedExerciseRef generate(
    Iterable<UserCreatedExerciseRef> existingIds,
  ) =>
      ids[index++];
}

final class _FakeUserExerciseRepository implements UserExerciseRepository {
  _FakeUserExerciseRepository({
    List<Exercise>? exercises,
    this.loadFailuresRemaining = 0,
    this.createError,
    this.createErrorAfterWrite,
    this.renameError,
    this.archiveError,
  }) : exercises = [...?exercises];

  final List<Exercise> exercises;
  final List<UserCreatedExerciseRef> attemptedCreateIds = [];
  int loadFailuresRemaining;
  Object? createError;
  Object? createErrorAfterWrite;
  Object? renameError;
  Object? archiveError;
  int listCalls = 0;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async {
    listCalls++;
    if (loadFailuresRemaining > 0) {
      loadFailuresRemaining--;
      throw Exception('load failed');
    }
    return List.unmodifiable(
      exercises.where(
        (exercise) => includeArchived || exercise.status == ExerciseStatus.active,
      ),
    );
  }

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
  }) async {
    attemptedCreateIds.add(id);
    final beforeWrite = createError;
    if (beforeWrite != null) throw beforeWrite;
    if (exercises.any((exercise) => exercise.ref == id)) {
      throw StateError('duplicate user Exercise id');
    }
    exercises.add(
      Exercise(
        ref: id,
        displayName: displayName,
        status: ExerciseStatus.active,
      ),
    );
    final afterWrite = createErrorAfterWrite;
    if (afterWrite != null) throw afterWrite;
  }

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {
    final error = renameError;
    if (error != null) throw error;
    final index = exercises.indexWhere((exercise) => exercise.ref == id);
    if (index < 0) throw StateError('Exercise not found');
    exercises[index] = _copyExercise(
      exercises[index],
      displayName: displayName,
    );
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    final error = archiveError;
    if (error != null) throw error;
    final index = exercises.indexWhere((exercise) => exercise.ref == id);
    if (index < 0) throw StateError('Exercise not found');
    exercises[index] = _copyExercise(
      exercises[index],
      status: ExerciseStatus.archived,
    );
  }
}
