import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

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

  Future<void> load() async {
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

  Future<bool> create(String displayName) async {
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

    late final UserCreatedExerciseRef id;
    try {
      id = _pendingCreateId ??
          idGenerator.generate(
            current.exercises
                .map((exercise) => exercise.ref)
                .whereType<UserCreatedExerciseRef>(),
          );
      _pendingCreateId ??= id;
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
      await repository.create(id: id, displayName: displayName);
      if (_disposed) return false;
      _pendingCreateId = null;
      final created = Exercise(
        ref: id,
        displayName: displayName,
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
      );
      if (_disposed) return false;
      if (reconciled != null) {
        _pendingCreateId = null;
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
      if (_disposed) return false;
      _publish(
        CustomExercisesState.ready(
          exercises: current.exercises,
          actionError: _actionFailureMessage(
            error,
            fallback: 'Could not archive exercise. Please try again.',
          ),
        ),
      );
      return false;
    }
  }

  Future<List<Exercise>?> _reconcileCreate({
    required UserCreatedExerciseRef id,
    required String displayName,
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
      if (persisted.displayName == displayName) return exercises;

      await repository.rename(id: id, displayName: displayName);
      exercises = await repository.list();
      if (exercises.any(
        (exercise) =>
            exercise.ref == id && exercise.displayName == displayName,
      )) {
        return exercises;
      }
    } catch (_) {
      // Preserve the pending stable identity when the durable outcome is
      // still unknown so another retry cannot create a second Exercise.
    }
    return null;
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
