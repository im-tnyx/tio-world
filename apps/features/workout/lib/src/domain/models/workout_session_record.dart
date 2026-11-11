import 'package:tio_shared/shared.dart';

/// Synchronization state for a persisted WorkoutSession record.
enum WorkoutSessionSyncState {
  /// Confirmed persisted state in sync with server revision.
  synced,

  /// In-flight mutation encountered network timeout or connection loss;
  /// requires reconciliation against server truth before retrying.
  uncertain,
}

/// Lightweight persistence and synchronization envelope for a [WorkoutSession].
///
/// Keeps the pure-Dart W7A [WorkoutSession] aggregate untangled from transport,
/// database revision, and sync metadata.
final class WorkoutSessionRecord {
  const WorkoutSessionRecord({
    required this.session,
    required this.revision,
    this.syncState = WorkoutSessionSyncState.synced,
    this.createdAt,
    this.updatedAt,
  }) : assert(revision >= 1, 'revision must be >= 1');

  /// The underlying domain aggregate.
  final WorkoutSession session;

  /// Authoritative server revision number (from `user_workout_sessions.revision`).
  final int revision;

  /// Authoritative or uncertain synchronization state.
  final WorkoutSessionSyncState syncState;

  /// UTC timestamp when this session was first inserted on the server.
  final DateTime? createdAt;

  /// UTC timestamp when this session was last modified on the server.
  final DateTime? updatedAt;

  /// Creates a copy of this record with the given fields replaced.
  WorkoutSessionRecord copyWith({
    WorkoutSession? session,
    int? revision,
    WorkoutSessionSyncState? syncState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      WorkoutSessionRecord(
        session: session ?? this.session,
        revision: revision ?? this.revision,
        syncState: syncState ?? this.syncState,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionRecord &&
          runtimeType == other.runtimeType &&
          session == other.session &&
          revision == other.revision &&
          syncState == other.syncState &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        session,
        revision,
        syncState,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'WorkoutSessionRecord(id: ${session.id.value}, status: ${session.status.wireValue}, revision: $revision, syncState: ${syncState.name})';
}
