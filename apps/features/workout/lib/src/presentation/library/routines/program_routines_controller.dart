import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/routine_repository.dart';

enum ProgramRoutinesStatus { loading, ready, loadFailed }

/// A Program-owned Routine collection; never a standalone Library collection.
final class ProgramRoutinesState {
  const ProgramRoutinesState.loading()
      : status = ProgramRoutinesStatus.loading,
        routines = const [],
        error = null,
        saving = false;

  ProgramRoutinesState.ready({
    required List<Routine> routines,
    this.error,
    this.saving = false,
  })  : status = ProgramRoutinesStatus.ready,
        routines = List.unmodifiable(routines);

  const ProgramRoutinesState.loadFailed()
      : status = ProgramRoutinesStatus.loadFailed,
        routines = const [],
        error = 'Could not load routines. Please try again.',
        saving = false;

  final ProgramRoutinesStatus status;
  final List<Routine> routines;
  final String? error;
  final bool saving;
}

/// Owns loaded metadata and uncertain-create reconciliation for exactly one Program.
/// RLS and the Program/owner FK remain the persistence security boundary.
final class ProgramRoutinesController extends ChangeNotifier {
  ProgramRoutinesController({
    required this.program,
    required this.repository,
    String Function()? newRoutineUuid,
  }) : _newRoutineUuid = newRoutineUuid ?? _uuidV4;

  final Program program;
  final RoutineRepository repository;
  final String Function() _newRoutineUuid;

  static String _uuidV4() => const Uuid().v4();

  ProgramRoutinesState _state = const ProgramRoutinesState.loading();
  ProgramRoutinesState get state => _state;
  String? _pendingCreateId;
  var _loadVersion = 0;
  var _disposed = false;

  Future<List<Routine>> _readOwnedRoutines() async {
    final routines = await repository.list(program.id);
    if (routines.any((routine) => routine.programId != program.id)) {
      throw const FormatException('Routine ownership mismatch.');
    }
    if (routines.map((routine) => routine.id).toSet().length !=
        routines.length) {
      throw const FormatException('Duplicate Routine identity.');
    }
    return routines;
  }

  Future<void> load() async {
    if (_state.saving) return;
    final version = ++_loadVersion;
    _publish(const ProgramRoutinesState.loading());
    try {
      final rows = await _readOwnedRoutines();
      if (_disposed || version != _loadVersion) return;
      if (_pendingCreateId != null &&
          rows.any((r) => r.id.value == _pendingCreateId)) {
        _pendingCreateId = null;
      }
      _publish(ProgramRoutinesState.ready(routines: rows));
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      _publish(const ProgramRoutinesState.loadFailed());
    }
  }

  Future<void> retryLoad() => load();

  /// End one Create Routine editor lifetime. Never reuse its uncertain UUID
  /// for a later, independent create action after that sheet is dismissed.
  /// Returns whether a pending uncertain insert needs a fresh owner read.
  bool abandonCreateAttempt() {
    final hadPending = _pendingCreateId != null;
    _pendingCreateId = null;
    return hadPending;
  }

  String suggestedName() {
    final existing = _state.routines
        .map((routine) => routine.name.trim().toLowerCase())
        .toSet();
    var index = 1;
    while (existing.contains('routine $index')) {
      index++;
    }
    return 'Routine $index';
  }

  Future<bool> create(String name) async {
    final current = _state;
    if (current.status != ProgramRoutinesStatus.ready || current.saving) {
      return false;
    }
    if (name.trim().isEmpty) {
      _publish(ProgramRoutinesState.ready(
        routines: current.routines,
        error: 'Enter a routine name.',
      ));
      return false;
    }

    late final Routine attempted;
    try {
      attempted = Routine(
        id: RoutineId(_pendingCreateId ?? _newRoutineUuid()),
        programId: program.id,
        name: name,
      );
      _pendingCreateId ??= attempted.id.value;
    } catch (_) {
      _publish(ProgramRoutinesState.ready(
        routines: current.routines,
        error: 'Could not create routine. Please try again.',
      ));
      return false;
    }

    _publish(ProgramRoutinesState.ready(
      routines: current.routines,
      saving: true,
    ));
    try {
      await repository.create(attempted);
      if (_disposed) return false;
      _pendingCreateId = null;
      _publish(ProgramRoutinesState.ready(
        routines: [...current.routines, attempted],
      ));
      return true;
    } catch (error) {
      final reconciled = await _reconcileCreate(attempted);
      if (_disposed) return false;
      if (reconciled != null) {
        _pendingCreateId = null;
        _publish(ProgramRoutinesState.ready(routines: reconciled));
        return true;
      }
      _publish(ProgramRoutinesState.ready(
        routines: current.routines,
        error: _errorMessage(error, creating: true),
      ));
      return false;
    }
  }

  /// A rename result is confirmed by an owner-filtered read, even when the
  /// Data API returns success with zero affected rows.
  Future<String?> rename({required Routine routine, required String name}) async {
    final current = _state;
    if (current.status != ProgramRoutinesStatus.ready ||
        current.saving ||
        routine.programId != program.id ||
        !current.routines.any((item) => item.id == routine.id)) {
      return 'Could not edit routine. Please try again.';
    }
    if (name.trim().isEmpty) return 'Enter a routine name.';
    if (name == routine.name) return null;

    _publish(ProgramRoutinesState.ready(
      routines: current.routines,
      saving: true,
    ));
    Object? error;
    try {
      await repository.rename(id: routine.id, name: name);
    } catch (caught) {
      error = caught;
    }
    List<Routine>? authoritativeRows;
    try {
      final rows = await _readOwnedRoutines();
      if (_disposed) return 'Could not edit routine. Please try again.';
      authoritativeRows = rows;
      if (rows.any((r) => r.id == routine.id && r.name == name)) {
        _publish(ProgramRoutinesState.ready(routines: rows));
        return null;
      }
    } catch (_) {
      // The durable write result is unknown; never advertise a false success.
    }
    if (!_disposed) {
      // Do not keep stale or concurrently deleted rows when the owner read
      // succeeded, even if this particular rename was not confirmed.
      _publish(ProgramRoutinesState.ready(
        routines: authoritativeRows ?? current.routines,
      ));
    }
    return error == null
        ? 'Could not confirm the routine name. Please try again.'
        : _errorMessage(error, creating: false);
  }

  Future<List<Routine>?> _reconcileCreate(Routine attempted) async {
    try {
      var rows = await _readOwnedRoutines();
      Routine? existing;
      for (final row in rows) {
        if (row.id == attempted.id) {
          existing = row;
          break;
        }
      }
      if (existing == null) return null;
      if (existing.name == attempted.name) return rows;
      // The original POST may have committed before its response was lost;
      // keep its UUID and reconcile the user's latest edited name.
      await repository.rename(id: attempted.id, name: attempted.name);
      rows = await _readOwnedRoutines();
      if (rows.any((r) => r.id == attempted.id && r.name == attempted.name)) {
        return rows;
      }
    } catch (_) {
      // Retain pending UUID across retries; never create a second identity.
    }
    return null;
  }

  static String _errorMessage(Object error, {required bool creating}) {
    if (error is StateError &&
        error.message.toString() == 'Please sign in to save Routines.') {
      return 'Please sign in to save Routines.';
    }
    return creating
        ? 'Could not create routine. Please try again.'
        : 'Could not edit routine. Please try again.';
  }

  void _publish(ProgramRoutinesState next) {
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
