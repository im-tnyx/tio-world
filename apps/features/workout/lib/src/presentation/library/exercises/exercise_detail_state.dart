import 'package:tio_shared/shared.dart';

enum ExerciseDetailStatus { loading, ready, unavailable, failed }

final class ExerciseDetailState {
  const ExerciseDetailState._({
    required this.status,
    this.exercise,
    this.errorMessage,
  });

  const ExerciseDetailState.loading()
      : this._(status: ExerciseDetailStatus.loading);

  const ExerciseDetailState.ready(Exercise exercise)
      : this._(status: ExerciseDetailStatus.ready, exercise: exercise);

  const ExerciseDetailState.unavailable([String? message])
      : this._(
          status: ExerciseDetailStatus.unavailable,
          errorMessage: message,
        );

  const ExerciseDetailState.failed(String message)
      : this._(
          status: ExerciseDetailStatus.failed,
          errorMessage: message,
        );

  final ExerciseDetailStatus status;
  final Exercise? exercise;
  final String? errorMessage;
}
