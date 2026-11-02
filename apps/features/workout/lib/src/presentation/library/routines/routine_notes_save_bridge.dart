import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/routine_notes_repository.dart';
import 'routine_notes_controller.dart';

/// A temporary inline Note draft owned by one Exercise card.
///
/// The card identity is presentation-only. Persistence always uses the
/// canonical ExerciseRef or the durable RoutineId supplied at save time.
final class ExerciseNoteDraftSnapshot {
  const ExerciseNoteDraftSnapshot({
    required this.draftId,
    required this.exerciseRef,
    required this.type,
    required this.body,
  });

  final String draftId;
  final ExerciseRef exerciseRef;
  final RoutineNoteType type;
  final String body;
}

enum RoutineNotesSaveStatus {
  saved,
  unavailable,
  unauthorized,
  invalid,
  quota,
  unknown
}

final class RoutineNotesSaveResult {
  const RoutineNotesSaveResult(this.status, [this.message]);

  final RoutineNotesSaveStatus status;
  final String? message;

  bool get isSuccess => status == RoutineNotesSaveStatus.saved;
}

/// Commits inline drafts only after the surrounding Routine mutation has been
/// confirmed. Existing Note commands are frozen once dispatched so a retry
/// reconciles an unknown outcome instead of issuing a duplicate write.
final class RoutineNotesSaveBridge {
  RoutineNotesSaveBridge({
    required RoutineNotesRepository repository,
    required String ownerId,
    required RoutineNotesSessionIsCurrent isSessionCurrent,
    String Function()? newUuid,
  })  : _repository = repository,
        _ownerId = ownerId.trim().toLowerCase(),
        _isSessionCurrent = isSessionCurrent,
        _newUuid = newUuid ?? (() => const Uuid().v4());

  final RoutineNotesRepository _repository;
  final String _ownerId;
  RoutineNotesSessionIsCurrent _isSessionCurrent;
  final String Function() _newUuid;
  final Map<String, _PendingInlineNote> _pending = {};

  bool get hasPending => _pending.values.any((item) => !item.confirmed);

  void updateSessionIsCurrent(RoutineNotesSessionIsCurrent callback) {
    _isSessionCurrent = callback;
  }

  Future<RoutineNotesSaveResult> save({
    required Iterable<ExerciseNoteDraftSnapshot> drafts,
    required RoutineId? routineId,
  }) async {
    if (!_current()) {
      return const RoutineNotesSaveResult(
        RoutineNotesSaveStatus.unauthorized,
        'Session changed. Reopen Routine before saving Notes.',
      );
    }

    final snapshots = drafts.where((draft) => draft.body.trim().isNotEmpty);
    for (final draft in snapshots) {
      final scope = draft.type == RoutineNoteType.pinnedRoutine
          ? routineId == null
              ? null
              : RoutineNoteScope.routine(routineId)
          : RoutineNoteScope.exercise(draft.exerciseRef);
      if (scope == null) {
        return const RoutineNotesSaveResult(
          RoutineNotesSaveStatus.invalid,
          'Routine identity is required before saving a Routine Note.',
        );
      }
      final body = _normalize(draft.body);
      if (body == null) {
        return const RoutineNotesSaveResult(
          RoutineNotesSaveStatus.invalid,
          'Note must contain between 1 and 500 characters.',
        );
      }
      final current = _pending[draft.draftId];
      if (current == null) {
        _pending[draft.draftId] = _PendingInlineNote(
          command: RoutineNoteCreate(
            id: _newUuid(),
            scope: scope,
            body: body,
            mutationId: _newUuid(),
          ),
        );
      } else if (!current.confirmed &&
          (current.command.scope != scope || current.command.body != body)) {
        return const RoutineNotesSaveResult(
          RoutineNotesSaveStatus.unknown,
          'A previous Note result is unconfirmed. Refresh before editing it again.',
        );
      }
    }

    final quota = await _checkQuota();
    if (quota != null) return quota;

    for (final pending in _pending.values) {
      if (pending.confirmed) continue;
      if (!_current()) {
        return const RoutineNotesSaveResult(
          RoutineNotesSaveStatus.unauthorized,
          'Session changed. Routine was saved, but Notes need verification.',
        );
      }
      if (pending.unknown) {
        final confirmed = await _reconcile(pending.command);
        if (!confirmed) {
          return const RoutineNotesSaveResult(
            RoutineNotesSaveStatus.unknown,
            'Note save could not be confirmed. Press Save/Update again to refresh.',
          );
        }
        pending.confirmed = true;
        continue;
      }
      try {
        final created = await _repository.create(pending.command);
        if (!_current()) {
          return const RoutineNotesSaveResult(
            RoutineNotesSaveStatus.unauthorized,
            'Session changed. Routine was saved, but Notes need verification.',
          );
        }
        if (created.userId != _ownerId ||
            created.id != pending.command.id ||
            created.scope != pending.command.scope ||
            created.body != pending.command.body) {
          return const RoutineNotesSaveResult(
            RoutineNotesSaveStatus.unknown,
            'Note save returned unverified data. Press Save/Update again to refresh.',
          );
        }
        pending.confirmed = true;
      } on RoutineNoteOutcomeUnknown {
        pending.unknown = true;
        if (await _reconcile(pending.command)) {
          pending.confirmed = true;
          continue;
        }
        return const RoutineNotesSaveResult(
          RoutineNotesSaveStatus.unknown,
          'Note save could not be confirmed. Press Save/Update again to refresh.',
        );
      } on RoutineNoteException catch (error) {
        return RoutineNotesSaveResult(
          _status(error.kind),
          _message(error.kind),
        );
      } catch (_) {
        return const RoutineNotesSaveResult(
          RoutineNotesSaveStatus.unavailable,
          'Routine was saved, but Notes could not be saved. Press Save/Update to retry.',
        );
      }
    }
    return const RoutineNotesSaveResult(RoutineNotesSaveStatus.saved);
  }

  Future<RoutineNotesSaveResult?> _checkQuota() async {
    final byScope = <RoutineNoteScope, List<_PendingInlineNote>>{};
    for (final item in _pending.values) {
      if (!item.confirmed) {
        byScope.putIfAbsent(item.command.scope, () => []).add(item);
      }
    }
    for (final entry in byScope.entries) {
      try {
        final notes = await _repository.read(entry.key);
        if (!_current()) {
          return const RoutineNotesSaveResult(
            RoutineNotesSaveStatus.unauthorized,
            'Session changed. Routine was saved, but Notes need verification.',
          );
        }
        if (notes.any(
            (note) => note.userId != _ownerId || note.scope != entry.key)) {
          return const RoutineNotesSaveResult(
            RoutineNotesSaveStatus.unknown,
            'Notes readback was not owner-scoped. Press Save/Update again to refresh.',
          );
        }
        final pendingNotReadBack = entry.value.where(
          (pending) => !notes.any((note) => note.id == pending.command.id),
        );
        if (notes.length + pendingNotReadBack.length >
            routineNotesMaximumCount) {
          return const RoutineNotesSaveResult(
            RoutineNotesSaveStatus.quota,
            'Maximum 5 active Notes reached for this scope.',
          );
        }
      } on RoutineNoteException catch (error) {
        return RoutineNotesSaveResult(
            _status(error.kind), _message(error.kind));
      } catch (_) {
        return const RoutineNotesSaveResult(
          RoutineNotesSaveStatus.unavailable,
          'Routine was saved, but Notes could not be verified. Press Save/Update to retry.',
        );
      }
    }
    return null;
  }

  Future<bool> _reconcile(RoutineNoteCreate command) async {
    try {
      final notes = await _repository.read(command.scope);
      if (!_current()) return false;
      return notes.any((note) =>
          note.userId == _ownerId &&
          note.id == command.id &&
          note.scope == command.scope &&
          note.body == command.body);
    } catch (_) {
      return false;
    }
  }

  bool _current() {
    try {
      return _isSessionCurrent();
    } catch (_) {
      return false;
    }
  }

  static String? _normalize(String body) {
    try {
      return RoutineNote.normalizeBody(body);
    } on ArgumentError {
      return null;
    }
  }

  static RoutineNotesSaveStatus _status(RoutineNoteFailureKind kind) =>
      switch (kind) {
        RoutineNoteFailureKind.unauthorized =>
          RoutineNotesSaveStatus.unauthorized,
        RoutineNoteFailureKind.quotaExceeded => RoutineNotesSaveStatus.quota,
        RoutineNoteFailureKind.invalidRequest => RoutineNotesSaveStatus.invalid,
        _ => RoutineNotesSaveStatus.unavailable,
      };

  static String _message(RoutineNoteFailureKind kind) => switch (kind) {
        RoutineNoteFailureKind.quotaExceeded =>
          'Maximum 5 active Notes reached for this scope.',
        RoutineNoteFailureKind.invalidRequest =>
          'Note must contain between 1 and 500 characters.',
        RoutineNoteFailureKind.unauthorized =>
          'Session changed. Reopen Routine before saving Notes.',
        _ =>
          'Routine was saved, but Notes could not be saved. Press Save/Update to retry.',
      };
}

final class _PendingInlineNote {
  _PendingInlineNote({required this.command});

  final RoutineNoteCreate command;
  var unknown = false;
  var confirmed = false;
}
