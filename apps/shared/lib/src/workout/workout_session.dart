import 'performed_set.dart';
import 'program_id.dart';
import 'routine_id.dart';
import 'workout_id_validation.dart';
import 'workout_session_id.dart';
import 'workout_session_snapshot.dart';
import 'workout_session_status.dart';
import 'workout_time.dart';

/// Canonical pure-Dart root entity for one active or completed WorkoutSession.
///
/// Encapsulates execution lifecycle, timing, immutable routine snapshot,
/// and performed set records.
final class WorkoutSession {
  WorkoutSession({
    required this.id,
    required String userId,
    required this.programId,
    required this.routineId,
    required this.status,
    required this.time,
    required String localDate,
    required this.snapshot,
    List<PerformedSet> performedSets = const [],
    this.notes,
    this.discardReason,
  })  : userId = requireCanonicalUuid(userId, 'userId'),
        localDate = _validateLocalDate(localDate),
        performedSets = List<PerformedSet>.unmodifiable(
          List<PerformedSet>.of(performedSets),
        ) {
    if (snapshot.routineId != routineId) {
      throw ArgumentError(
        'snapshot.routineId (${snapshot.routineId}) does not match session routineId ($routineId)',
      );
    }
    if (snapshot.programId != programId) {
      throw ArgumentError(
        'snapshot.programId (${snapshot.programId}) does not match session programId ($programId)',
      );
    }
    _validateStatusAndTimeAlignment();
    _validateDiscardReason();
    _validatePerformedSets(this.performedSets, snapshot);
  }

  /// Convenience factory to start a new active session from a verified snapshot.
  factory WorkoutSession.start({
    required WorkoutSessionId id,
    required String userId,
    required ProgramId programId,
    required RoutineId routineId,
    required WorkoutSessionSnapshot snapshot,
    required String localDate,
    DateTime? startedAtUtc,
  }) {
    final startUtc = startedAtUtc ?? DateTime.timestamp();
    return WorkoutSession(
      id: id,
      userId: userId,
      programId: programId,
      routineId: routineId,
      status: WorkoutSessionStatus.active,
      time: WorkoutTime.start(startedAtUtc: startUtc),
      localDate: localDate,
      snapshot: snapshot,
    );
  }

  /// Durable unique identity of this WorkoutSession.
  final WorkoutSessionId id;

  /// Canonical UUID of the owning user.
  final String userId;

  /// Owning Program identity.
  final ProgramId programId;

  /// Source Routine identity.
  final RoutineId routineId;

  /// Current lifecycle state.
  final WorkoutSessionStatus status;

  /// Active and paused duration accounting.
  final WorkoutTime time;

  /// User's local calendar date (`YYYY-MM-DD`) for diary/history attribution.
  final String localDate;

  /// Frozen snapshot of the source routine composition at start time.
  final WorkoutSessionSnapshot snapshot;

  /// Ordered list of sets actually performed or skipped during the workout.
  final List<PerformedSet> performedSets;

  /// Optional athlete notes for the overall workout session.
  final String? notes;

  /// Mandatory discard explanation when [status] is [WorkoutSessionStatus.discarded].
  final String? discardReason;

  /// Whether this session is in a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Transitions an active session into [WorkoutSessionStatus.paused] at [atUtc].
  WorkoutSession pause(DateTime atUtc) {
    if (!status.canTransitionTo(WorkoutSessionStatus.paused)) {
      throw StateError('Cannot pause session in status $status');
    }
    return WorkoutSession(
      id: id,
      userId: userId,
      programId: programId,
      routineId: routineId,
      status: WorkoutSessionStatus.paused,
      time: time.pause(atUtc),
      localDate: localDate,
      snapshot: snapshot,
      performedSets: performedSets,
      notes: notes,
    );
  }

  /// Transitions a paused session back into [WorkoutSessionStatus.active] at [atUtc].
  WorkoutSession resume(DateTime atUtc) {
    if (!status.canTransitionTo(WorkoutSessionStatus.active)) {
      throw StateError('Cannot resume session in status $status');
    }
    return WorkoutSession(
      id: id,
      userId: userId,
      programId: programId,
      routineId: routineId,
      status: WorkoutSessionStatus.active,
      time: time.resume(atUtc),
      localDate: localDate,
      snapshot: snapshot,
      performedSets: performedSets,
      notes: notes,
    );
  }

  /// Transitions the session to [WorkoutSessionStatus.completed] at [atUtc].
  WorkoutSession complete(DateTime atUtc, {String? notes}) {
    if (!status.canTransitionTo(WorkoutSessionStatus.completed)) {
      throw StateError('Cannot complete session in status $status');
    }
    return WorkoutSession(
      id: id,
      userId: userId,
      programId: programId,
      routineId: routineId,
      status: WorkoutSessionStatus.completed,
      time: time.finish(atUtc),
      localDate: localDate,
      snapshot: snapshot,
      performedSets: performedSets,
      notes: notes ?? this.notes,
    );
  }

  /// Transitions the session to [WorkoutSessionStatus.discarded] at [atUtc].
  WorkoutSession discard(DateTime atUtc, {required String reason}) {
    if (!status.canTransitionTo(WorkoutSessionStatus.discarded)) {
      throw StateError('Cannot discard session in status $status');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'must contain at least one non-whitespace character',
      );
    }
    return WorkoutSession(
      id: id,
      userId: userId,
      programId: programId,
      routineId: routineId,
      status: WorkoutSessionStatus.discarded,
      time: time.finish(atUtc),
      localDate: localDate,
      snapshot: snapshot,
      performedSets: performedSets,
      notes: notes,
      discardReason: trimmedReason,
    );
  }

  /// Records or replaces a performed set in this session.
  ///
  /// Matches existing set by [PerformedSet.id] if present, otherwise appends.
  /// Validates that the set references a valid snapshot exercise occurrence,
  /// matching `exerciseRef`, and that no distinct set ID occupies the same slot.
  /// Throws [StateError] if session is already in a terminal state.
  WorkoutSession logSet(PerformedSet set) {
    if (isTerminal) {
      throw StateError('Cannot log sets in terminal session ($status)');
    }

    _validateSinglePerformedSet(set, snapshot);

    final updated = List<PerformedSet>.of(performedSets);
    final existingIndex = updated.indexWhere((item) => item.id == set.id);

    // Reject two different set IDs claiming the same slot
    final slotConflictIndex = updated.indexWhere(
      (item) =>
          item.sessionExerciseIndex == set.sessionExerciseIndex &&
          item.setIndex == set.setIndex &&
          item.id != set.id,
    );
    if (slotConflictIndex >= 0) {
      final conflicting = updated[slotConflictIndex];
      throw ArgumentError(
        'Slot (sessionExerciseIndex: ${set.sessionExerciseIndex}, setIndex: ${set.setIndex}) is already occupied by set ID ${conflicting.id}.',
      );
    }

    if (existingIndex >= 0) {
      updated[existingIndex] = set;
    } else {
      updated.add(set);
    }

    return WorkoutSession(
      id: id,
      userId: userId,
      programId: programId,
      routineId: routineId,
      status: status,
      time: time,
      localDate: localDate,
      snapshot: snapshot,
      performedSets: updated,
      notes: notes,
      discardReason: discardReason,
    );
  }

  /// Removes a performed set by its UUID [setId].
  ///
  /// Throws [StateError] if session is already in a terminal state.
  WorkoutSession removeSet(String setId) {
    if (isTerminal) {
      throw StateError('Cannot remove sets from terminal session ($status)');
    }
    final canonicalId = requireCanonicalUuid(setId, 'setId');
    final updated =
        performedSets.where((item) => item.id != canonicalId).toList();
    return WorkoutSession(
      id: id,
      userId: userId,
      programId: programId,
      routineId: routineId,
      status: status,
      time: time,
      localDate: localDate,
      snapshot: snapshot,
      performedSets: updated,
      notes: notes,
      discardReason: discardReason,
    );
  }

  static void _validateSinglePerformedSet(
    PerformedSet set,
    WorkoutSessionSnapshot snapshot,
  ) {
    if (snapshot.exercises.isEmpty ||
        set.sessionExerciseIndex < 0 ||
        set.sessionExerciseIndex >= snapshot.exercises.length) {
      throw ArgumentError.value(
        set.sessionExerciseIndex,
        'sessionExerciseIndex',
        'does not exist in session snapshot (snapshot has ${snapshot.exercises.length} exercises)',
      );
    }
    final occurrence = snapshot.exercises[set.sessionExerciseIndex];
    if (set.exerciseRef != occurrence.exerciseRef) {
      throw ArgumentError(
        'Performed set exerciseRef (${set.exerciseRef}) does not match snapshot occurrence at index ${set.sessionExerciseIndex} (${occurrence.exerciseRef}).',
      );
    }
  }

  static void _validatePerformedSets(
    List<PerformedSet> sets,
    WorkoutSessionSnapshot snapshot,
  ) {
    final seenIds = <String>{};
    final seenSlots = <(int, int)>{};

    for (final set in sets) {
      _validateSinglePerformedSet(set, snapshot);

      if (!seenIds.add(set.id)) {
        throw ArgumentError('Duplicate performed set ID: ${set.id}');
      }

      final slot = (set.sessionExerciseIndex, set.setIndex);
      if (!seenSlots.add(slot)) {
        throw ArgumentError(
          'Duplicate performed set slot (sessionExerciseIndex: ${set.sessionExerciseIndex}, setIndex: ${set.setIndex}) under distinct set IDs in session.',
        );
      }
    }
  }

  void _validateStatusAndTimeAlignment() {
    switch (status) {
      case WorkoutSessionStatus.active:
        if (time.isPaused) {
          throw ArgumentError('Active session cannot have paused time.');
        }
        if (time.isCompleted) {
          throw ArgumentError('Active session cannot have completed time.');
        }
      case WorkoutSessionStatus.paused:
        if (!time.isPaused) {
          throw ArgumentError('Paused session must have pausedAtUtc set.');
        }
        if (time.isCompleted) {
          throw ArgumentError('Paused session cannot have completed time.');
        }
      case WorkoutSessionStatus.completed:
      case WorkoutSessionStatus.discarded:
        if (!time.isCompleted) {
          throw ArgumentError('Terminal session must have completedAtUtc set.');
        }
    }
  }

  void _validateDiscardReason() {
    if (status == WorkoutSessionStatus.discarded) {
      if (discardReason == null || discardReason!.trim().isEmpty) {
        throw ArgumentError(
          'discardReason is required when status is discarded.',
        );
      }
    } else {
      if (discardReason != null) {
        throw ArgumentError(
          'discardReason must be null when status is not discarded ($status).',
        );
      }
    }
  }

  static String _validateLocalDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw ArgumentError.value(
        value,
        'localDate',
        'must be a valid YYYY-MM-DD Gregorian date string',
      );
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'localDate.year', 'out of range 1-9999');
    }
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError.value(
        value,
        'localDate',
        'must be a valid Gregorian calendar date',
      );
    }
    return value;
  }

  static bool _setsEqual(List<PerformedSet> a, List<PerformedSet> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          other.id == id &&
          other.userId == userId &&
          other.programId == programId &&
          other.routineId == routineId &&
          other.status == status &&
          other.time == time &&
          other.localDate == localDate &&
          other.snapshot == snapshot &&
          _setsEqual(other.performedSets, performedSets) &&
          other.notes == notes &&
          other.discardReason == discardReason;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        programId,
        routineId,
        status,
        time,
        localDate,
        snapshot,
        Object.hashAll(performedSets),
        notes,
        discardReason,
      );
}
