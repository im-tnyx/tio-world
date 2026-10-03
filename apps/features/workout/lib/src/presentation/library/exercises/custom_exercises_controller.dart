import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/user_exercise_definition.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/usecases/user_exercise_id_generator.dart';
import 'custom_exercises_state.dart';

final class CustomExercisesController extends ChangeNotifier {
  CustomExercisesController({
    required this.repository,
    UserExerciseIdGenerator? idGenerator,
  }) : idGenerator = idGenerator ?? UuidUserExerciseIdGenerator();

  final UserExerciseRepository repository;
  final UserExerciseIdGenerator idGenerator;

  CustomExercisesState _state = const CustomExercisesState.loading();
  CustomExercisesState get state => _state;

  var _loadVersion = 0;
  var _disposed = false;
  UserCreatedExerciseRef? _pendingCreateId;
  String? _pendingCreateDisplayName;
  UserExerciseDefinition? _pendingCreateDefinition;

  Future<void> load() async {
    if (_state.actionInProgress) return;

    final version = ++_loadVersion;
    _publish(const CustomExercisesState.loading());

    try {
      final exercises = await repository.list();
      if (_disposed || version != _loadVersion) return;
      final pendingId = _pendingCreateId;
      if (pendingId != null &&
          exercises.any((exercise) => exercise.ref == pendingId)) {
        _pendingCreateId = null;
      }
      _publish(CustomExercisesState.ready(exercises: exercises));
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      _publish(
        const CustomExercisesState.loadFailed(
          'Could not load custom exercises. Please try again.',
        ),
      );
    }
  }

  Future<void> retryLoad() => load();

  Future<bool> create(
    String displayName, {
    UserExerciseDefinition? definition,
  }) async {
    final current = _state;
    if (current.status != CustomExercisesStatus.ready ||
        current.actionInProgress) {
      return false;
    }

    if (displayName.trim().isEmpty) {
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: 'Enter an exercise name.',
        ),
      );
      return false;
    }

    final normalizedName = displayName.trim();
    final canRetryPending = _pendingCreateId != null &&
        _pendingCreateDisplayName == normalizedName &&
        _pendingCreateDefinition == definition;
    if (!canRetryPending) {
      _pendingCreateId = null;
      _pendingCreateDisplayName = null;
      _pendingCreateDefinition = null;
    }

    late final UserCreatedExerciseRef id;
    try {
      id = _pendingCreateId ??
          idGenerator.generate(
            current.exercises
                .map((exercise) => exercise.ref)
                .whereType<UserCreatedExerciseRef>(),
          );
      if (_pendingCreateId == null) {
        _pendingCreateId = id;
        _pendingCreateDisplayName = normalizedName;
        _pendingCreateDefinition = definition;
      }
    } catch (_) {
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: 'Could not create exercise. Please try again.',
        ),
      );
      return false;
    }

    _publish(
      CustomExercisesState.ready(
        exercises: current.exercises,
        actionInProgress: true,
      ),
    );

    try {
      await repository.create(
        id: id,
        displayName: displayName,
        definition: definition,
      );
      if (_disposed) return false;
      _pendingCreateId = null;
      final created = Exercise(
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
      );
      _publish(
        CustomExercisesState.ready(
          exercises: [...current.exercises, created],
        ),
      );
      return true;
    } catch (error) {
      final reconciled = await _reconcileCreate(
        id: id,
        displayName: displayName,
        definition: definition,
      );
      if (_disposed) return false;
      if (reconciled != null) {
        _clearPendingCreate();
        _publish(CustomExercisesState.ready(exercises: reconciled));
        return true;
      }
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: _actionFailureMessage(
            error,
            fallback: 'Could not create exercise. Please try again.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> edit({
    required UserCreatedExerciseRef id,
    required String displayName,
    required UserExerciseDefinition definition,
  }) async {
    final current = _state;
    if (current.status != CustomExercisesStatus.ready ||
        current.actionInProgress) {
      return false;
    }
    if (displayName.trim().isEmpty) {
      _publish(CustomExercisesState.ready(
        exercises: current.exercises,
        actionError: 'Enter an exercise name.',
      ));
      return false;
    }
    if (!current.exercises.any((item) => item.ref == id)) {
      _publish(CustomExercisesState.ready(
        exercises: current.exercises,
        actionError: 'Could not update exercise. Please try again.',
      ));
      return false;
    }

    _publish(CustomExercisesState.ready(
      exercises: current.exercises,
      actionInProgress: true,
    ));
    try {
      await repository.rename(id: id, displayName: displayName);
      await repository.updateDefinition(id: id, definition: definition);
      final reconciled = await repository.list();
      if (_disposed) return false;
      _publish(CustomExercisesState.ready(exercises: reconciled));
      return true;
    } catch (error) {
      final isSignInFailure = _isSignInFailure(error);
      final reconciled =
          isSignInFailure ? null : await _reloadAfterWriteFailure();
      if (_disposed) return false;
      if (!isSignInFailure &&
          reconciled != null &&
          _containsDefinition(
            reconciled,
            id: id,
            displayName: displayName,
            definition: definition,
          )) {
        _publish(CustomExercisesState.ready(exercises: reconciled));
        return true;
      }
      _publish(CustomExercisesState.ready(
        exercises: reconciled ?? current.exercises,
        actionError: _actionFailureMessage(
          error,
          fallback: 'Could not update exercise. Please try again.',
        ),
      ));
      return false;
    }
  }

  Future<bool> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {
    final current = _state;
    if (current.status != CustomExercisesStatus.ready ||
        current.actionInProgress) {
      return false;
    }

    if (displayName.trim().isEmpty) {
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: 'Enter an exercise name.',
        ),
      );
      return false;
    }

    final index = current.exercises.indexWhere((item) => item.ref == id);
    if (index < 0) {
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: 'Could not rename exercise. Please try again.',
        ),
      );
      return false;
    }

    _publish(
      CustomExercisesState.ready(
        exercises: current.exercises,
        actionInProgress: true,
      ),
    );

    try {
      await repository.rename(id: id, displayName: displayName);
      if (_disposed) return false;
      final updated = [...current.exercises];
      updated[index] = _copyWithDisplayName(updated[index], displayName);
      _publish(CustomExercisesState.ready(exercises: updated));
      return true;
    } catch (error) {
      if (_disposed) return false;
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: _actionFailureMessage(
            error,
            fallback: 'Could not rename exercise. Please try again.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> archive(UserCreatedExerciseRef id) async {
    final current = _state;
    if (current.status != CustomExercisesStatus.ready ||
        current.actionInProgress) {
      return false;
    }

    final index = current.exercises.indexWhere((item) => item.ref == id);
    if (index < 0) {
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: 'Could not archive exercise. Please try again.',
        ),
      );
      return false;
    }

    _publish(
      CustomExercisesState.ready(
        exercises: current.exercises,
        actionInProgress: true,
      ),
    );

    try {
      await repository.archive(id);
      if (_disposed) return false;
      final updated = [...current.exercises]..removeAt(index);
      _publish(CustomExercisesState.ready(exercises: updated));
      return true;
    } catch (error) {
      final isSignInFailure = _isSignInFailure(error);
      final reconciled =
          isSignInFailure ? null : await _reloadAfterWriteFailure();
      if (_disposed) return false;
      if (!isSignInFailure &&
          reconciled != null &&
          !reconciled.any((exercise) => exercise.ref == id)) {
        _publish(CustomExercisesState.ready(exercises: reconciled));
        return true;
      }
      _publish(
        CustomExercisesState.ready(
          exercises: reconciled ?? current.exercises,
          actionError: _actionFailureMessage(
            error,
            fallback: 'Could not archive exercise. Please try again.',
          ),
        ),
      );
      return false;
    }
  }

  bool _containsDefinition(
    List<Exercise> exercises, {
    required UserCreatedExerciseRef id,
    required String displayName,
    required UserExerciseDefinition definition,
  }) {
    for (final exercise in exercises) {
      if (exercise.ref == id &&
          exercise.displayName == displayName &&
          exercise.description == definition.description &&
          exercise.exerciseType == definition.exerciseType &&
          listEquals(
            exercise.primaryMuscles,
            definition.primaryMuscle == null
                ? const <String>[]
                : [definition.primaryMuscle!],
          ) &&
          listEquals(exercise.secondaryMuscles, definition.secondaryMuscles) &&
          exercise.primaryEquipment == definition.primaryEquipment) {
        return true;
      }
    }
    return false;
  }

  Future<List<Exercise>?> _reloadAfterWriteFailure() async {
    try {
      return await repository.list();
    } catch (_) {
      return null;
    }
  }

  Future<List<Exercise>?> _reconcileCreate({
    required UserCreatedExerciseRef id,
    required String displayName,
    UserExerciseDefinition? definition,
  }) async {
    try {
      var exercises = await repository.list();
      Exercise? persisted;
      for (final exercise in exercises) {
        if (exercise.ref == id) {
          persisted = exercise;
          break;
        }
      }
      if (persisted == null) return null;
      final definitionMatches = definition == null ||
          (persisted.description == definition.description &&
              persisted.exerciseType == definition.exerciseType &&
              listEquals(
                persisted.primaryMuscles,
                (definition.primaryMuscle == null
                      ? const <String>[]
                      : [definition.primaryMuscle!]),
              ) &&
              listEquals(persisted.secondaryMuscles, definition.secondaryMuscles) &&
              persisted.primaryEquipment == definition.primaryEquipment);
      if (persisted.displayName == displayName && definitionMatches) {
        return exercises;
      }

      if (persisted.displayName != displayName) {
        await repository.rename(id: id, displayName: displayName);
      }
      if (definition != null && !definitionMatches) {
        await repository.updateDefinition(id: id, definition: definition);
      }
      exercises = await repository.list();
      for (final exercise in exercises) {
        if (exercise.ref != id || exercise.displayName != displayName) continue;
        if (definition == null ||
            (exercise.description == definition.description &&
                exercise.exerciseType == definition.exerciseType &&
                listEquals(
                  exercise.primaryMuscles,
                  definition.primaryMuscle == null
                      ? const <String>[]
                      : [definition.primaryMuscle!],
                ) &&
                listEquals(
                  exercise.secondaryMuscles,
                  definition.secondaryMuscles,
                ) &&
                exercise.primaryEquipment == definition.primaryEquipment)) {
          return exercises;
        }
      }
    } catch (_) {
      // Preserve the pending stable identity when the durable outcome is
      // still unknown so another retry cannot create a second Exercise.
    }
    return null;
  }

  void _clearPendingCreate() {
    _pendingCreateId = null;
    _pendingCreateDisplayName = null;
    _pendingCreateDefinition = null;
  }

  bool _isSignInFailure(Object error) {
    return error is StateError &&
        error.message.toString() == 'Please sign in to save Exercises.';
  }

  String _actionFailureMessage(Object error, {required String fallback}) {
    if (error is StateError &&
        error.message.toString() == 'Please sign in to save Exercises.') {
      return 'Please sign in to save Exercises.';
    }
    return fallback;
  }

  static Exercise _copyWithDisplayName(
    Exercise exercise,
    String displayName,
  ) =>
      Exercise(
        ref: exercise.ref,
        displayName: displayName,
        description: exercise.description,
        exerciseType: exercise.exerciseType,
        muscleGroup: exercise.muscleGroup,
        primaryMuscles: exercise.primaryMuscles,
        secondaryMuscles: exercise.secondaryMuscles,
        primaryEquipment: exercise.primaryEquipment,
        category: exercise.category,
        levels: exercise.levels,
        status: exercise.status,
        media: exercise.media,
      );

  void _publish(CustomExercisesState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    super.dispose();
  }
}
