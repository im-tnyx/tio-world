import 'package:tio_shared/shared.dart';

enum CustomExercisesStatus { loading, ready, loadFailed }

final class CustomExercisesState {
  const CustomExercisesState.loading()
      : status = CustomExercisesStatus.loading,
        exercises = const [],
        loadError = null,
        actionInProgress = false,
        actionError = null;

  CustomExercisesState.ready({
    required List<Exercise> exercises,
    this.actionInProgress = false,
    this.actionError,
  })  : status = CustomExercisesStatus.ready,
        exercises = List.unmodifiable(exercises),
        loadError = null;

  const CustomExercisesState.loadFailed(this.loadError)
      : status = CustomExercisesStatus.loadFailed,
        exercises = const [],
        actionInProgress = false,
        actionError = null;

  final CustomExercisesStatus status;
  final List<Exercise> exercises;
  final String? loadError;
  final bool actionInProgress;
  final String? actionError;
}