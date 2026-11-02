import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/routine_notes_repository.dart';

const routineNotesMaximumCount = 5;
const _pendingCreateRefreshNotice =
    'The save result could not be confirmed. Refresh to verify.';

typedef RoutineNotesSessionIsCurrent = bool Function();

enum RoutineNotesStatus { loading, ready, failed }

final class RoutineNotesState {
  const RoutineNotesState.loading()
      : status = RoutineNotesStatus.loading,
        notes = const [],
        failure = null,
        actionNotice = null;

  RoutineNotesState.ready(
    List<RoutineNote> notes, {
    this.actionNotice,
    this.failure,
  })  : status = RoutineNotesStatus.ready,
        notes = List.unmodifiable(notes);

  const RoutineNotesState.failed(this.failure, {this.actionNotice})
      : status = RoutineNotesStatus.failed,
        notes = const [];

  final RoutineNotesStatus status;
  final List<RoutineNote> notes;
  final RoutineNoteFailureKind? failure;
  final String? actionNotice;

  bool get isLoading => status == RoutineNotesStatus.loading;
  bool get isReady => status == RoutineNotesStatus.ready;
  bool get canCreate => isReady && notes.length < routineNotesMaximumCount;
}

/// Owns the Routine-scoped Notes read/create/delete lifecycle.
///
/// The caller supplies a live session check because a repository instance can
/// outlive a logout or same-account re-authentication cycle. Results from an
/// old session are never emitted into the current Routine Detail.
final class RoutineNotesController extends ChangeNotifier {
  RoutineNotesController({
    required RoutineId routineId,
    required RoutineNotesRepository repository,
    required String ownerId,
    required RoutineNotesSessionIsCurrent isSessionCurrent,
    String Function()? newUuid,
  }) : this.forScope(
          scope: RoutineNoteScope.routine(routineId),
          repository: repository,
          ownerId: ownerId,
          isSessionCurrent: isSessionCurrent,
          newUuid: newUuid,
        );

  RoutineNotesController.forScope({
    required RoutineNoteScope scope,
    required RoutineNotesRepository repository,
    required String ownerId,
    required RoutineNotesSessionIsCurrent isSessionCurrent,
    String Function()? newUuid,
  })  : _scope = scope,
        _repository = repository,
        _ownerId = ownerId.trim().toLowerCase(),
        _isSessionCurrent = isSessionCurrent,
        _newUuid = newUuid ?? (() => const Uuid().v4()) {
    if (!_isUuid(_ownerId)) {
      throw ArgumentError.value(ownerId, 'ownerId');
    }
  }

  final RoutineNoteScope _scope;
  final RoutineNotesRepository _repository;
  final String _ownerId;
  RoutineNotesSessionIsCurrent _isSessionCurrent;
  final String Function() _newUuid;

  RoutineNotesState _state = const RoutineNotesState.loading();
  RoutineNotesState get state => _state;

  var _version = 0;
  var _busy = false;
  var _disposed = false;

  Future<void> load({String? actionNotice}) async {
    final version = ++_version;
    if (!_sessionIsCurrent()) {
      _emit(const RoutineNotesState.failed(
        RoutineNoteFailureKind.unauthorized,
      ));
      return;
    }
    _emit(const RoutineNotesState.loading());
    try {
      final notes = await _repository.read(_scope);
      if (!_active(version)) return;
      final next = _ready(notes, actionNotice: actionNotice);
      if (!next.isReady) {
        _emit(next);
        return;
      }
      final pendingCreate = _pendingCreate;
      if (pendingCreate != null) {
        final confirmed = next.notes.any(
          (note) =>
              note.id == pendingCreate.noteId &&
              note.body == pendingCreate.body,
        );
        if (confirmed) {
          _pendingCreate = null;
          _emit(_ready(notes, actionNotice: 'Note save confirmed.'));
        } else {
          _emit(_ready(
            notes,
            actionNotice: actionNotice ??
                'A previous save is still unconfirmed. Refresh before retrying.',
            failure: RoutineNoteFailureKind.unavailable,
          ));
        }
        return;
      }
      final pendingTransfer = _pendingTransfer;
      if (pendingTransfer != null) {
        final stillPresent = next.notes.any(
          (note) => note.id == pendingTransfer.noteId,
        );
        if (!stillPresent) {
          _pendingTransfer = null;
          _emit(_ready(notes, actionNotice: 'Note type change confirmed.'));
        } else {
          _emit(_ready(
            notes,
            actionNotice: actionNotice ??
                'A previous Note type change is still unconfirmed. Refresh before retrying.',
            failure: RoutineNoteFailureKind.unavailable,
          ));
        }
        return;
      }
      _emit(next);
    } on RoutineNoteException catch (error) {
      if (!_active(version)) return;
      _emit(RoutineNotesState.failed(_safeFailure(error.kind)));
    } on RoutineNoteOutcomeUnknown {
      if (!_active(version)) return;
      _emit(const RoutineNotesState.failed(
        RoutineNoteFailureKind.unavailable,
        actionNotice: 'The Notes result could not be confirmed. Try again.',
      ));
    } catch (_) {
      if (!_active(version)) return;
      _emit(const RoutineNotesState.failed(
        RoutineNoteFailureKind.unavailable,
      ));
    }
  }

  Future<bool> create(String body) async {
    if (_busy || _pendingTransfer != null || !_sessionIsCurrent()) {
      _fail(RoutineNoteFailureKind.unauthorized);
      return false;
    }
    if (_pendingCreate != null) {
      _emit(_ready(
        _state.notes,
        actionNotice:
            'A previous save is still unconfirmed. Refresh before retrying.',
        failure: RoutineNoteFailureKind.unavailable,
      ));
      return false;
    }
    if (!_state.isReady) return false;
    if (_state.notes.length >= routineNotesMaximumCount) {
      _fail(RoutineNoteFailureKind.quotaExceeded);
      return false;
    }

    final normalizedBody = _normalizeBody(body);
    if (normalizedBody == null) {
      _fail(RoutineNoteFailureKind.invalidRequest);
      return false;
    }
    final noteId = _newUuid();
    final mutationId = _newUuid();
    final version = ++_version;
    _busy = true;
    notifyListeners();
    try {
      final created = await _repository.create(
        RoutineNoteCreate(
          id: noteId,
          scope: _scope,
          body: normalizedBody,
          mutationId: mutationId,
        ),
      );
      if (!_active(version)) return false;
      if (created.userId != _ownerId || created.scope != _scope) {
        _emit(const RoutineNotesState.failed(
          RoutineNoteFailureKind.malformedData,
        ));
        return false;
      }
      _emit(_ready([..._state.notes, created]));
      return true;
    } on RoutineNoteOutcomeUnknown {
      if (!_active(version)) return false;
      _pendingCreate = _PendingCreate(
        noteId: noteId,
        mutationId: mutationId,
        body: normalizedBody,
      );
      await load(
        actionNotice: _pendingCreateRefreshNotice,
      );
      return _pendingCreate == null;
    } on RoutineNoteException catch (error) {
      if (!_active(version)) return false;
      _emit(_ready(
        _state.notes,
        failure: _safeFailure(error.kind),
      ));
      return false;
    } catch (_) {
      if (!_active(version)) return false;
      _emit(_ready(
        _state.notes,
        failure: RoutineNoteFailureKind.unavailable,
      ));
      return false;
    } finally {
      _finishBusy();
    }
  }

  Future<bool> transfer(
    RoutineNote note,
    RoutineNoteScope destination,
  ) async {
    if (_busy ||
        _pendingCreate != null ||
        _pendingTransfer != null ||
        !_sessionIsCurrent()) {
      _fail(RoutineNoteFailureKind.unauthorized);
      return false;
    }
    if (!_state.isReady ||
        note.userId != _ownerId ||
        note.scope != _scope ||
        destination == _scope ||
        !_state.notes.any((current) => current.id == note.id)) {
      _fail(RoutineNoteFailureKind.unauthorized);
      return false;
    }

    final mutationId = _newUuid();
    final version = ++_version;
    _busy = true;
    notifyListeners();
    try {
      final transferred = await _repository.transfer(
        RoutineNoteTransfer(
          id: note.id,
          destination: destination,
          expectedRevision: note.revision,
          mutationId: mutationId,
        ),
      );
      if (!_active(version)) return false;
      if (transferred.userId != _ownerId ||
          transferred.id != note.id ||
          transferred.scope != destination) {
        _emit(const RoutineNotesState.failed(
          RoutineNoteFailureKind.malformedData,
        ));
        return false;
      }
      _emit(_ready(
        _state.notes.where((current) => current.id != note.id).toList(),
      ));
      return true;
    } on RoutineNoteOutcomeUnknown {
      if (!_active(version)) return false;
      _pendingTransfer = _PendingTransfer(
        noteId: note.id,
        mutationId: mutationId,
        destination: destination,
      );
      await load(
        actionNotice:
            'The Note type change could not be confirmed. Refresh to verify.',
      );
      return _pendingTransfer == null;
    } on RoutineNoteException catch (error) {
      if (!_active(version)) return false;
      _fail(_safeFailure(error.kind));
      return false;
    } catch (_) {
      if (!_active(version)) return false;
      _fail(RoutineNoteFailureKind.unavailable);
      return false;
    } finally {
      _finishBusy();
    }
  }

  Future<bool> delete(RoutineNote note) async {
    if (_busy || _pendingTransfer != null || !_sessionIsCurrent()) {
      _fail(RoutineNoteFailureKind.unauthorized);
      return false;
    }
    if (!_state.isReady ||
        note.userId != _ownerId ||
        note.scope != _scope ||
        !_state.notes.any((current) => current.id == note.id)) {
      _fail(RoutineNoteFailureKind.unauthorized);
      return false;
    }

    final version = ++_version;
    _busy = true;
    notifyListeners();
    try {
      await _repository.delete(
        RoutineNoteDelete(
          id: note.id,
          expectedRevision: note.revision,
          mutationId: _newUuid(),
        ),
      );
      if (!_active(version)) return false;
      final pending = _pendingCreate;
      _emit(_ready(
        _state.notes.where((current) => current.id != note.id).toList(),
        actionNotice: pending == null ? null : _pendingCreateRefreshNotice,
      ));
      return true;
    } on RoutineNoteOutcomeUnknown {
      if (!_active(version)) return false;
      await load(
        actionNotice:
            'The delete result could not be confirmed. Refresh to verify.',
      );
      return false;
    } on RoutineNoteException catch (error) {
      if (!_active(version)) return false;
      _fail(_safeFailure(error.kind));
      return false;
    } catch (_) {
      if (!_active(version)) return false;
      _fail(RoutineNoteFailureKind.unavailable);
      return false;
    } finally {
      _finishBusy();
    }
  }

  bool get isBusy => _busy;

  /// Provider rebuilds may recreate the callback closure without changing the
  /// authenticated owner or canonical Note scope. Keep the live guard current
  /// without discarding the controller and its draft lifecycle.
  void updateSessionIsCurrent(RoutineNotesSessionIsCurrent callback) {
    _isSessionCurrent = callback;
  }
  bool get canCreate =>
      !_busy &&
      _pendingCreate == null &&
      _pendingTransfer == null &&
      _state.canCreate &&
      _sessionIsCurrent();
  bool get hasPendingMutation =>
      _pendingCreate != null || _pendingTransfer != null;

  _PendingCreate? _pendingCreate;
  _PendingTransfer? _pendingTransfer;

  RoutineNotesState _ready(
    List<RoutineNote> notes, {
    String? actionNotice,
    RoutineNoteFailureKind? failure,
  }) {
    final valid = notes.length <= routineNotesMaximumCount &&
        notes.every(
          (note) => note.userId == _ownerId && note.scope == _scope,
        );
    if (!valid) {
      return const RoutineNotesState.failed(
        RoutineNoteFailureKind.malformedData,
      );
    }
    final ordered = [...notes]..sort((a, b) {
        final created = a.createdAt.compareTo(b.createdAt);
        return created != 0 ? created : a.id.compareTo(b.id);
      });
    return RoutineNotesState.ready(
      ordered,
      actionNotice: actionNotice,
      failure: failure,
    );
  }

  bool _sessionIsCurrent() {
    try {
      return _isSessionCurrent();
    } catch (_) {
      return false;
    }
  }

  bool _active(int version) =>
      !_disposed && version == _version && _sessionIsCurrent();

  void _fail(RoutineNoteFailureKind failure) {
    if (_disposed) return;
    _version++;
    if (_state.isReady) {
      _emit(_ready(
        _state.notes,
        failure: _safeFailure(failure),
      ));
    } else {
      _emit(RoutineNotesState.failed(_safeFailure(failure)));
    }
  }

  void _finishBusy() {
    if (_disposed) return;
    _busy = false;
    notifyListeners();
  }

  void _emit(RoutineNotesState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  RoutineNoteFailureKind _safeFailure(RoutineNoteFailureKind failure) {
    if (!_sessionIsCurrent()) return RoutineNoteFailureKind.unauthorized;
    return failure;
  }

  static String? _normalizeBody(String value) {
    try {
      return RoutineNote.normalizeBody(value);
    } on ArgumentError {
      return null;
    }
  }

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      ).hasMatch(value);

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}

final class _PendingCreate {
  const _PendingCreate({
    required this.noteId,
    required this.mutationId,
    required this.body,
  });

  final String noteId;
  final String mutationId;
  final String body;
}

final class _PendingTransfer {
  const _PendingTransfer({
    required this.noteId,
    required this.mutationId,
    required this.destination,
  });

  final String noteId;
  final String mutationId;
  final RoutineNoteScope destination;
}
