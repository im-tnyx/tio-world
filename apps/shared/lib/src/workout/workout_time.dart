/// Immutable accounting of active and paused time for one WorkoutSession.
///
/// All timestamps must be in UTC. Active workout duration subtracts pause
/// durations to ensure truthful training volume statistics. Monotonicity is
/// strictly enforced across all transitions (start -> pause -> resume -> pause -> finish).
final class WorkoutTime {
  WorkoutTime({
    required DateTime startedAtUtc,
    DateTime? pausedAtUtc,
    Duration accumulatedPausedDuration = Duration.zero,
    DateTime? completedAtUtc,
    DateTime? lastTransitionAtUtc,
  })  : startedAtUtc = _requireUtc(startedAtUtc, 'startedAtUtc'),
        pausedAtUtc = _validateOptionalUtc(pausedAtUtc, 'pausedAtUtc'),
        accumulatedPausedDuration =
            _requireNonNegativeDuration(accumulatedPausedDuration),
        completedAtUtc = _validateOptionalUtc(completedAtUtc, 'completedAtUtc'),
        lastTransitionAtUtc = _validateAndResolveLastTransition(
          startedAtUtc: startedAtUtc,
          pausedAtUtc: pausedAtUtc,
          accumulatedPausedDuration: accumulatedPausedDuration,
          completedAtUtc: completedAtUtc,
          lastTransitionAtUtc: lastTransitionAtUtc,
        ) {
    if (this.pausedAtUtc != null) {
      if (this.pausedAtUtc!.isBefore(this.startedAtUtc)) {
        throw ArgumentError.value(
          pausedAtUtc,
          'pausedAtUtc',
          'cannot be before startedAtUtc',
        );
      }
      // The total previous pause duration cannot exceed the window up to the current pause.
      if (this.startedAtUtc.add(this.accumulatedPausedDuration).isAfter(this.pausedAtUtc!)) {
        throw ArgumentError(
          'accumulatedPausedDuration ($accumulatedPausedDuration) exceeds time elapsed between start and current pause.',
        );
      }
    }
    if (this.completedAtUtc != null) {
      if (this.completedAtUtc!.isBefore(this.startedAtUtc)) {
        throw ArgumentError.value(
          completedAtUtc,
          'completedAtUtc',
          'cannot be before startedAtUtc',
        );
      }
      if (this.startedAtUtc.add(this.accumulatedPausedDuration).isAfter(this.completedAtUtc!)) {
        throw ArgumentError(
          'accumulatedPausedDuration ($accumulatedPausedDuration) exceeds total duration between start and finish.',
        );
      }
    }
    if (this.completedAtUtc != null && this.pausedAtUtc != null) {
      throw ArgumentError(
        'A completed or discarded session cannot remain paused.',
      );
    }
    // For currently active session that has resumed from a prior pause:
    if (this.pausedAtUtc == null && this.completedAtUtc == null && this.accumulatedPausedDuration > Duration.zero) {
      if (this.lastTransitionAtUtc.isBefore(this.startedAtUtc.add(this.accumulatedPausedDuration))) {
        throw ArgumentError(
          'lastTransitionAtUtc ($lastTransitionAtUtc) cannot be before startedAtUtc + accumulatedPausedDuration (${this.startedAtUtc.add(this.accumulatedPausedDuration)}).',
        );
      }
    }
  }

  /// Convenience factory for starting a session at [startedAtUtc].
  factory WorkoutTime.start({DateTime? startedAtUtc}) {
    final start = startedAtUtc ?? DateTime.timestamp();
    return WorkoutTime(
      startedAtUtc: start,
      lastTransitionAtUtc: start,
    );
  }

  /// UTC instant when the workout session started.
  final DateTime startedAtUtc;

  /// UTC instant when the current pause began; `null` while actively running or finished.
  final DateTime? pausedAtUtc;

  /// Total duration accumulated across previously completed pause intervals.
  final Duration accumulatedPausedDuration;

  /// UTC instant when the workout session finished (completed or discarded); `null` while in progress.
  final DateTime? completedAtUtc;

  /// UTC instant of the most recent lifecycle transition (start, pause, resume, or finish).
  ///
  /// Guarantees that subsequent transitions and duration evaluations cannot be backdated.
  final DateTime lastTransitionAtUtc;

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
    if (utc.isBefore(lastTransitionAtUtc)) {
      throw ArgumentError.value(
        utc,
        'atUtc',
        'pause timestamp cannot be before last transition ($lastTransitionAtUtc)',
      );
    }
    return WorkoutTime(
      startedAtUtc: startedAtUtc,
      pausedAtUtc: utc,
      accumulatedPausedDuration: accumulatedPausedDuration,
      completedAtUtc: completedAtUtc,
      lastTransitionAtUtc: utc,
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
      lastTransitionAtUtc: utc,
    );
  }

  /// Returns a new [WorkoutTime] marked complete (or discarded) at [atUtc].
  WorkoutTime finish(DateTime atUtc) {
    final utc = _requireUtc(atUtc, 'atUtc');
    if (isCompleted) {
      throw StateError('Workout is already finished.');
    }
    if (utc.isBefore(lastTransitionAtUtc)) {
      throw ArgumentError.value(
        utc,
        'atUtc',
        'finish timestamp cannot be before last transition ($lastTransitionAtUtc)',
      );
    }

    var totalPaused = accumulatedPausedDuration;
    if (isPaused) {
      totalPaused += utc.difference(pausedAtUtc!);
    }

    return WorkoutTime(
      startedAtUtc: startedAtUtc,
      pausedAtUtc: null,
      accumulatedPausedDuration: totalPaused,
      completedAtUtc: utc,
      lastTransitionAtUtc: utc,
    );
  }

  /// Computes the active workout duration (excluding pauses) as of [nowUtc].
  ///
  /// For finished workouts, [nowUtc] is ignored and the duration up to
  /// [completedAtUtc] is returned.
  Duration elapsedActiveDuration(DateTime nowUtc) {
    final now = _requireUtc(nowUtc, 'nowUtc');
    final effectiveEnd = completedAtUtc ?? now;
    if (effectiveEnd.isBefore(lastTransitionAtUtc)) {
      throw ArgumentError.value(
        nowUtc,
        'nowUtc',
        'evaluation instant cannot be before last transition ($lastTransitionAtUtc)',
      );
    }

    var totalPaused = accumulatedPausedDuration;
    if (isPaused) {
      totalPaused += effectiveEnd.difference(pausedAtUtc!);
    }

    final totalElapsed = effectiveEnd.difference(startedAtUtc);
    final active = totalElapsed - totalPaused;
    if (active.isNegative) {
      throw StateError(
        'Inconsistent duration state: total paused duration ($totalPaused) exceeds elapsed duration ($totalElapsed).',
      );
    }
    return active;
  }

  /// Total wall-clock time elapsed from start to finish (or [nowUtc]).
  Duration totalElapsedDuration(DateTime nowUtc) {
    final now = _requireUtc(nowUtc, 'nowUtc');
    final effectiveEnd = completedAtUtc ?? now;
    if (effectiveEnd.isBefore(lastTransitionAtUtc)) {
      throw ArgumentError.value(
        nowUtc,
        'nowUtc',
        'evaluation instant cannot be before last transition ($lastTransitionAtUtc)',
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

  static DateTime _validateAndResolveLastTransition({
    required DateTime startedAtUtc,
    required DateTime? pausedAtUtc,
    required Duration accumulatedPausedDuration,
    required DateTime? completedAtUtc,
    required DateTime? lastTransitionAtUtc,
  }) {
    if (lastTransitionAtUtc != null) {
      _requireUtc(lastTransitionAtUtc, 'lastTransitionAtUtc');
      if (lastTransitionAtUtc.isBefore(startedAtUtc)) {
        throw ArgumentError.value(
          lastTransitionAtUtc,
          'lastTransitionAtUtc',
          'cannot be before startedAtUtc',
        );
      }
      if (completedAtUtc != null && !lastTransitionAtUtc.isAtSameMomentAs(completedAtUtc)) {
        throw ArgumentError.value(
          lastTransitionAtUtc,
          'lastTransitionAtUtc',
          'must match completedAtUtc for finished sessions',
        );
      }
      if (pausedAtUtc != null && !lastTransitionAtUtc.isAtSameMomentAs(pausedAtUtc)) {
        throw ArgumentError.value(
          lastTransitionAtUtc,
          'lastTransitionAtUtc',
          'must match pausedAtUtc for currently paused sessions',
        );
      }
      return lastTransitionAtUtc;
    }

    // Default resolution when not explicitly supplied:
    if (completedAtUtc != null) return completedAtUtc;
    if (pausedAtUtc != null) return pausedAtUtc;
    if (accumulatedPausedDuration > Duration.zero) {
      return startedAtUtc.add(accumulatedPausedDuration);
    }
    return startedAtUtc;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTime &&
          other.startedAtUtc == startedAtUtc &&
          other.pausedAtUtc == pausedAtUtc &&
          other.accumulatedPausedDuration == accumulatedPausedDuration &&
          other.completedAtUtc == completedAtUtc &&
          other.lastTransitionAtUtc == lastTransitionAtUtc;

  @override
  int get hashCode => Object.hash(
        startedAtUtc,
        pausedAtUtc,
        accumulatedPausedDuration,
        completedAtUtc,
        lastTransitionAtUtc,
      );
}
