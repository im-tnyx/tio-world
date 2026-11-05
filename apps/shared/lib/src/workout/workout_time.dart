/// Immutable accounting of active and paused time for one WorkoutSession.
///
/// All timestamps must be in UTC. Active workout duration subtracts pause
/// durations to ensure truthful training volume statistics.
final class WorkoutTime {
  WorkoutTime({
    required DateTime startedAtUtc,
    DateTime? pausedAtUtc,
    Duration accumulatedPausedDuration = Duration.zero,
    DateTime? completedAtUtc,
  })  : startedAtUtc = _requireUtc(startedAtUtc, 'startedAtUtc'),
        pausedAtUtc = _validateOptionalUtc(pausedAtUtc, 'pausedAtUtc'),
        accumulatedPausedDuration =
            _requireNonNegativeDuration(accumulatedPausedDuration),
        completedAtUtc = _validateOptionalUtc(completedAtUtc, 'completedAtUtc') {
    if (this.pausedAtUtc != null &&
        this.pausedAtUtc!.isBefore(this.startedAtUtc)) {
      throw ArgumentError.value(
        pausedAtUtc,
        'pausedAtUtc',
        'cannot be before startedAtUtc',
      );
    }
    if (this.completedAtUtc != null &&
        this.completedAtUtc!.isBefore(this.startedAtUtc)) {
      throw ArgumentError.value(
        completedAtUtc,
        'completedAtUtc',
        'cannot be before startedAtUtc',
      );
    }
    if (this.completedAtUtc != null && this.pausedAtUtc != null) {
      throw ArgumentError(
        'A completed or discarded session cannot remain paused.',
      );
    }
  }

  /// Convenience factory for starting a session at [startedAtUtc].
  factory WorkoutTime.start({DateTime? startedAtUtc}) {
    final start = startedAtUtc ?? DateTime.timestamp();
    return WorkoutTime(startedAtUtc: start);
  }

  /// UTC instant when the workout session started.
  final DateTime startedAtUtc;

  /// UTC instant when the current pause began; `null` while actively running or finished.
  final DateTime? pausedAtUtc;

  /// Total duration accumulated across previously completed pause intervals.
  final Duration accumulatedPausedDuration;

  /// UTC instant when the workout session finished (completed or discarded); `null` while in progress.
  final DateTime? completedAtUtc;

  /// Whether the workout is currently paused.
  bool get isPaused => pausedAtUtc != null;

  /// Whether the workout has reached a terminal time state.
  bool get isCompleted => completedAtUtc != null;

  /// Returns a new [WorkoutTime] paused at [atUtc].
  WorkoutTime pause(DateTime atUtc) {
    final utc = _requireUtc(atUtc, 'atUtc');
    if (isCompleted) {
      throw StateError('Cannot pause a completed or discarded session.');
    }
    if (isPaused) {
      throw StateError('Workout is already paused.');
    }
    if (utc.isBefore(startedAtUtc)) {
      throw ArgumentError.value(
        utc,
        'atUtc',
        'pause timestamp cannot be before startedAtUtc',
      );
    }
    return WorkoutTime(
      startedAtUtc: startedAtUtc,
      pausedAtUtc: utc,
      accumulatedPausedDuration: accumulatedPausedDuration,
      completedAtUtc: completedAtUtc,
    );
  }

  /// Returns a new [WorkoutTime] resumed from pause at [atUtc].
  WorkoutTime resume(DateTime atUtc) {
    final utc = _requireUtc(atUtc, 'atUtc');
    if (isCompleted) {
      throw StateError('Cannot resume a completed or discarded session.');
    }
    if (!isPaused) {
      throw StateError('Workout is not paused.');
    }
    if (utc.isBefore(pausedAtUtc!)) {
      throw ArgumentError.value(
        utc,
        'atUtc',
        'resume timestamp cannot be before pausedAtUtc',
      );
    }
    final additionalPause = utc.difference(pausedAtUtc!);
    return WorkoutTime(
      startedAtUtc: startedAtUtc,
      pausedAtUtc: null,
      accumulatedPausedDuration: accumulatedPausedDuration + additionalPause,
      completedAtUtc: completedAtUtc,
    );
  }

  /// Returns a new [WorkoutTime] marked complete (or discarded) at [atUtc].
  WorkoutTime finish(DateTime atUtc) {
    final utc = _requireUtc(atUtc, 'atUtc');
    if (isCompleted) {
      throw StateError('Workout is already finished.');
    }
    if (utc.isBefore(startedAtUtc)) {
      throw ArgumentError.value(
        utc,
        'atUtc',
        'finish timestamp cannot be before startedAtUtc',
      );
    }

    var totalPaused = accumulatedPausedDuration;
    if (isPaused) {
      if (utc.isBefore(pausedAtUtc!)) {
        throw ArgumentError.value(
          utc,
          'atUtc',
          'finish timestamp cannot be before pausedAtUtc',
        );
      }
      totalPaused += utc.difference(pausedAtUtc!);
    }

    return WorkoutTime(
      startedAtUtc: startedAtUtc,
      pausedAtUtc: null,
      accumulatedPausedDuration: totalPaused,
      completedAtUtc: utc,
    );
  }

  /// Computes the active workout duration (excluding pauses) as of [nowUtc].
  ///
  /// For finished workouts, [nowUtc] is ignored and the duration up to
  /// [completedAtUtc] is returned.
  Duration elapsedActiveDuration(DateTime nowUtc) {
    final now = _requireUtc(nowUtc, 'nowUtc');
    final effectiveEnd = completedAtUtc ?? now;
    if (effectiveEnd.isBefore(startedAtUtc)) {
      throw ArgumentError.value(
        nowUtc,
        'nowUtc',
        'evaluation instant cannot be before startedAtUtc',
      );
    }

    var totalPaused = accumulatedPausedDuration;
    if (isPaused) {
      final pauseEnd = effectiveEnd.isBefore(pausedAtUtc!)
          ? pausedAtUtc!
          : effectiveEnd;
      totalPaused += pauseEnd.difference(pausedAtUtc!);
    }

    final totalElapsed = effectiveEnd.difference(startedAtUtc);
    final active = totalElapsed - totalPaused;
    return active.isNegative ? Duration.zero : active;
  }

  /// Total wall-clock time elapsed from start to finish (or [nowUtc]).
  Duration totalElapsedDuration(DateTime nowUtc) {
    final now = _requireUtc(nowUtc, 'nowUtc');
    final effectiveEnd = completedAtUtc ?? now;
    if (effectiveEnd.isBefore(startedAtUtc)) {
      throw ArgumentError.value(
        nowUtc,
        'nowUtc',
        'evaluation instant cannot be before startedAtUtc',
      );
    }
    return effectiveEnd.difference(startedAtUtc);
  }

  static DateTime _requireUtc(DateTime dt, String name) {
    if (!dt.isUtc) {
      throw ArgumentError.value(dt, name, 'must be a UTC DateTime');
    }
    return dt;
  }

  static DateTime? _validateOptionalUtc(DateTime? dt, String name) {
    if (dt == null) return null;
    return _requireUtc(dt, name);
  }

  static Duration _requireNonNegativeDuration(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'accumulatedPausedDuration',
        'must be non-negative',
      );
    }
    return duration;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTime &&
          other.startedAtUtc == startedAtUtc &&
          other.pausedAtUtc == pausedAtUtc &&
          other.accumulatedPausedDuration == accumulatedPausedDuration &&
          other.completedAtUtc == completedAtUtc;

  @override
  int get hashCode => Object.hash(
        startedAtUtc,
        pausedAtUtc,
        accumulatedPausedDuration,
        completedAtUtc,
      );
}
