import 'dart:async';

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
    expect(controller.state.loadError,
        contains('Could not load custom exercises'));

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

    final created = await controller.create(
      'Paused Squat',
      draftIdentity: Object(),
    );

    expect(created, isTrue);
    expect(repository.attemptedCreateIds, [_id(1)]);
    expect(repository.exercises, [_exercise(1, 'Paused Squat')]);
    expect(controller.state.exercises, [_exercise(1, 'Paused Squat')]);
    expect(controller.state.actionError, isNull);
  });

  test('load and retryLoad do not release an in-flight action lock', () async {
    final gate = Completer<void>();
    final repository = _FakeUserExerciseRepository(createGate: gate);
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final createFuture = controller.create(
      'Paused Squat',
      draftIdentity: Object(),
    );
    expect(controller.state.actionInProgress, isTrue);

    await controller.load();
    await controller.retryLoad();

    expect(controller.state.actionInProgress, isTrue);
    expect(repository.listCalls, 1);

    gate.complete();
    expect(await createFuture, isTrue);
    expect(controller.state.actionInProgress, isFalse);
    expect(controller.state.exercises, [_exercise(1, 'Paused Squat')]);
  });

  test('blank create is rejected without touching persistence', () async {
    final repository = _FakeUserExerciseRepository();
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(
      await controller.create('   ', draftIdentity: Object()),
      isFalse,
    );

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

    final created = await controller.create(
      'Paused Squat',
      draftIdentity: Object(),
    );

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

    final draftIdentity = Object();
    expect(
      await controller.create(
        'Paused Squat',
        draftIdentity: draftIdentity,
      ),
      isFalse,
    );
    repository.createError = null;
    expect(
      await controller.create(
        'Paused Squat',
        draftIdentity: draftIdentity,
      ),
      isTrue,
    );

    expect(repository.attemptedCreateIds, [_id(1), _id(1)]);
    expect(repository.exercises, [_exercise(1, 'Paused Squat')]);
  });

  test('edited retry reconciles the latest name onto the durable Exercise',
      () async {
    final repository = _FakeUserExerciseRepository(
      createErrorAfterWrite: Exception('response lost'),
    );
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1), _id(2)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final draftIdentity = Object();
    repository.loadFailuresRemaining = 1;
    expect(
      await controller.create(
        'Paused Squat',
        draftIdentity: draftIdentity,
      ),
      isFalse,
    );

    repository.createErrorAfterWrite = null;
    expect(
      await controller.create(
        'Tempo Squat',
        draftIdentity: draftIdentity,
      ),
      isTrue,
    );

    expect(repository.attemptedCreateIds, [_id(1), _id(1)]);
    expect(repository.exercises, [_exercise(1, 'Tempo Squat')]);
    expect(controller.state.exercises, [_exercise(1, 'Tempo Squat')]);
  });


  test('new draft after unresolved create uses a fresh Exercise id', () async {
    final repository = _FakeUserExerciseRepository(
      createErrorAfterWrite: Exception('response lost'),
    );
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1), _id(2)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    repository.loadFailuresRemaining = 1;
    expect(
      await controller.create(
        'Paused Squat',
        draftIdentity: Object(),
      ),
      isFalse,
    );

    repository.createErrorAfterWrite = null;
    expect(
      await controller.create(
        'Tempo Squat',
        draftIdentity: Object(),
      ),
      isTrue,
    );

    expect(repository.attemptedCreateIds, [_id(1), _id(2)]);
    expect(
      repository.exercises.map((exercise) => exercise.displayName),
      ['Paused Squat', 'Tempo Squat'],
    );
  });

  test('structured create publishes the persisted definition', () async {
    final repository = _FakeUserExerciseRepository();
    final controller = CustomExercisesController(
      repository: repository,
      idGenerator: _QueueUserExerciseIdGenerator([_id(1)]),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final definition = UserExerciseDefinition(
      description: 'Pause at depth',
      exerciseType: ExerciseType.weightReps,
      primaryMuscle: 'quadriceps',
      secondaryMuscles: const ['gluteus_maximus'],
      primaryEquipment: 'barbell',
    );
    expect(
      await controller.create(
        'Paused Squat',
        draftIdentity: Object(),
        definition: definition,
      ),
      isTrue,
    );

    final exercise = controller.state.exercises.single;
    expect(exercise.displayName, 'Paused Squat');
    expect(exercise.description, 'Pause at depth');
    expect(exercise.exerciseType, ExerciseType.weightReps);
    expect(exercise.primaryMuscles, const ['quadriceps']);
    expect(exercise.secondaryMuscles, const ['gluteus_maximus']);
    expect(exercise.primaryEquipment, 'barbell');
  });

  test('edit reconciles name and structured definition from durable state',
      () async {
    final repository = _FakeUserExerciseRepository(
      exercises: [_exercise(1, 'Paused Squat')],
    );
    final controller = CustomExercisesController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    final definition = UserExerciseDefinition(
      description: 'Three second eccentric',
      exerciseType: ExerciseType.weightReps,
      primaryMuscle: 'quadriceps',
      secondaryMuscles: const ['gluteus_maximus'],
      primaryEquipment: 'barbell',
    );
    expect(
      await controller.edit(
        id: _id(1),
        displayName: 'Tempo Squat',
        definition: definition,
      ),
      isTrue,
    );

    final exercise = controller.state.exercises.single;
    expect(exercise.displayName, 'Tempo Squat');
    expect(exercise.description, 'Three second eccentric');
    expect(exercise.primaryMuscles, const ['quadriceps']);
    expect(exercise.secondaryMuscles, const ['gluteus_maximus']);
  });

  test('edit definition failure reloads a successful rename before error',
      () async {
    final repository = _FakeUserExerciseRepository(
      exercises: [_exercise(1, 'Paused Squat')],
      updateDefinitionError: Exception('network down'),
    );
    final controller = CustomExercisesController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    final definition = UserExerciseDefinition(
      exerciseType: ExerciseType.weightReps,
      primaryMuscle: 'quadriceps',
    );
    expect(
      await controller.edit(
        id: _id(1),
        displayName: 'Tempo Squat',
        definition: definition,
      ),
      isFalse,
    );

    expect(controller.state.exercises.single.displayName, 'Tempo Squat');
    expect(
      controller.state.actionError,
      'Could not update exercise. Please try again.',
    );
  });

  test('rename updates the active item and preserves canonical metadata',
      () async {
    final original = Exercise(
      ref: _id(1),
      displayName: 'Paused Squat',
      description: 'Pause at depth',
      exerciseType: ExerciseType.weightReps,
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
    expect(renamed.description, original.description);
    expect(renamed.exerciseType, original.exerciseType);
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

  test('archive failure keeps the active list unchanged', () async {
    final repository = _FakeUserExerciseRepository(
      exercises: [_exercise(1, 'Paused Squat')],
      archiveError: Exception('network down'),
    );
    final controller = CustomExercisesController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.archive(_id(1)), isFalse);

    expect(controller.state.exercises, [_exercise(1, 'Paused Squat')]);
    expect(
      controller.state.actionError,
      'Could not archive exercise. Please try again.',
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
      description: exercise.description,
      exerciseType: exercise.exerciseType,
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
    this.createGate,
    this.renameError,
    this.updateDefinitionError,
    this.archiveError,
  }) : exercises = [...?exercises];

  final List<Exercise> exercises;
  final List<UserCreatedExerciseRef> attemptedCreateIds = [];
  int loadFailuresRemaining;
  Object? createError;
  Object? createErrorAfterWrite;
  Completer<void>? createGate;
  Object? renameError;
  Object? updateDefinitionError;
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
        (exercise) =>
            includeArchived || exercise.status == ExerciseStatus.active,
      ),
    );
  }

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {
    attemptedCreateIds.add(id);
    final gate = createGate;
    if (gate != null) await gate.future;
    final beforeWrite = createError;
    if (beforeWrite != null) throw beforeWrite;
    if (exercises.any((exercise) => exercise.ref == id)) {
      throw StateError('duplicate user Exercise id');
    }
    exercises.add(
      Exercise(
        ref: id,
        displayName: displayName,
        description: definition?.description,
        exerciseType: definition?.exerciseType,
        primaryMuscles: definition?.primaryMuscle == null
            ? const []
            : [definition!.primaryMuscle!],
        secondaryMuscles: definition?.secondaryMuscles ?? const [],
        primaryEquipment: definition?.primaryEquipment,
        status: ExerciseStatus.active,
      ),
    );
    final afterWrite = createErrorAfterWrite;
    if (afterWrite != null) throw afterWrite;
  }

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {
    final error = updateDefinitionError;
    if (error != null) throw error;
    final index = exercises.indexWhere((exercise) => exercise.ref == id);
    if (index < 0) throw StateError('Exercise not found');
    final exercise = exercises[index];
    exercises[index] = Exercise(
      ref: exercise.ref,
      displayName: exercise.displayName,
      description: definition.description,
      exerciseType: definition.exerciseType,
      primaryMuscles: definition.primaryMuscle == null
          ? const []
          : [definition.primaryMuscle!],
      secondaryMuscles: definition.secondaryMuscles,
      primaryEquipment: definition.primaryEquipment,
      status: exercise.status,
    );
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
