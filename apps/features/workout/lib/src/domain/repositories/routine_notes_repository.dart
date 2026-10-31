import 'package:tio_shared/shared.dart';

enum RoutineNoteFailureKind {
  unauthorized,
  forbidden,
  notFound,
  invalidRequest,
  quotaExceeded,
  revisionConflict,
  mutationConflict,

  /// Receipt is past retention; its mutation cannot be retried or recovered.
  expired,
  malformedData,
  unavailable,
}

final class RoutineNoteException implements Exception {
  const RoutineNoteException(this.kind);

  final RoutineNoteFailureKind kind;

  @override
  String toString() => 'RoutineNoteException(${kind.name})';
}

enum RoutineNoteUncertainty { unconfirmed, sessionChanged }

final class RoutineNoteOutcomeUnknown implements Exception {
  const RoutineNoteOutcomeUnknown({
    required this.mutationId,
    this.reason = RoutineNoteUncertainty.unconfirmed,
  });

  final String mutationId;
  final RoutineNoteUncertainty reason;

  @override
  String toString() => 'RoutineNoteOutcomeUnknown(${reason.name})';
}

final class RoutineNoteCreate {
  RoutineNoteCreate({
    required String id,
    required this.scope,
    required String body,
    required String mutationId,
  })  : id = _uuid(id, 'id'),
        body = RoutineNote.normalizeBody(body),
        mutationId = _uuid(mutationId, 'mutationId');

  final String id;
  final RoutineNoteScope scope;
  final String body;
  final String mutationId;
}

final class RoutineNoteUpdate {
  RoutineNoteUpdate({
    required String id,
    required this.expectedRevision,
    required String body,
    required String mutationId,
  })  : id = _uuid(id, 'id'),
        body = RoutineNote.normalizeBody(body),
        mutationId = _uuid(mutationId, 'mutationId') {
    if (expectedRevision < 0) {
      throw ArgumentError.value(expectedRevision, 'expectedRevision');
    }
  }

  final String id;
  final int expectedRevision;
  final String body;
  final String mutationId;
}

final class RoutineNoteTransfer {
  RoutineNoteTransfer({
    required String id,
    required this.destination,
    required this.expectedRevision,
    required String mutationId,
  })  : id = _uuid(id, 'id'),
        mutationId = _uuid(mutationId, 'mutationId') {
    if (expectedRevision < 0) {
      throw ArgumentError.value(expectedRevision, 'expectedRevision');
    }
  }

  final String id;
  final RoutineNoteScope destination;
  final int expectedRevision;
  final String mutationId;
}

final class RoutineNoteDelete {
  RoutineNoteDelete({
    required String id,
    required this.expectedRevision,
    required String mutationId,
  })  : id = _uuid(id, 'id'),
        mutationId = _uuid(mutationId, 'mutationId') {
    if (expectedRevision < 0) {
      throw ArgumentError.value(expectedRevision, 'expectedRevision');
    }
  }

  final String id;
  final int expectedRevision;
  final String mutationId;
}

abstract interface class RoutineNotesRepository {
  Future<List<RoutineNote>> read(RoutineNoteScope scope);

  Future<RoutineNote> create(RoutineNoteCreate command);

  Future<RoutineNote> update(RoutineNoteUpdate command);

  Future<RoutineNote> transfer(RoutineNoteTransfer command);

  Future<void> delete(RoutineNoteDelete command);
}

String _uuid(String value, String name) {
  final normalized = value.trim().toLowerCase();
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  ).hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be a canonical UUID');
  }
  return normalized;
}
