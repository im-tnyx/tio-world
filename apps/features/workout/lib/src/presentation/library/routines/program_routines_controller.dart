import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/routine_composition_repository.dart';
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
  final Map<RoutineId, int> _loadedRevisions = {};

  /// A revision must come from the same owner-scoped list as the Routine.
  /// Plain metadata-only fakes may list, but cannot authorize Rename.
  Future<({List<Routine> routines, Map<RoutineId, int> revisions})>
      _readOwnedRoutines() async {
    final versioned = repository is RoutineVersionedRenameRepository
        ? await (repository as RoutineVersionedRenameRepository)
            .listVersioned(program.id)
        : null;
    final routines = versioned == null
        ? await repository.list(program.id)
        : [for (final item in versioned) item.routine];
    if (routines.any((routine) => routine.programId != program.id)) {
      throw const FormatException('Routine ownership mismatch.');
    }
    if (routines.map((routine) => routine.id).toSet().length !=
        routines.length) {
      throw const FormatException('Duplicate Routine identity.');
    }
    return (
      routines: routines,
      revisions: {
        if (versioned != null)
          for (final item in versioned) item.routine.id: item.revision,
      },
    );
  }

  void _acceptRead(
      ({List<Routine> routines, Map<RoutineId, int> revisions}) read) {
    _loadedRevisions
      ..clear()
      ..addAll(read.revisions);
    _publish(ProgramRoutinesState.ready(routines: read.routines));
  }

  Future<void> load() async {
    if (_state.saving) return;
    final version = ++_loadVersion;
    _publish(const ProgramRoutinesState.loading());
    try {
      final read = await _readOwnedRoutines();
      if (_disposed || version != _loadVersion) return;
      if (_pendingCreateId != null &&
          read.routines.any((r) => r.id.value == _pendingCreateId)) {
        _pendingCreateId = null;
      }
      _acceptRead(read);
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
        _acceptRead(reconciled);
        return true;
      }
      _publish(ProgramRoutinesState.ready(
        routines: current.routines,
        error: _errorMessage(error, creating: true),
      ));
      return false;
    }
  }

  /// Only list-time owner/Program/revision context may authorize a rename.
  /// The composed RPC validates one frozen CAS token; read-back without an
  /// RPC-confirmed revision is NOT evidence of this client's write.
  Future<String?> rename({required Routine routine, required String name}) async {
    final current = _state;
    final guarded = repository;
    final expectedRevision = _loadedRevisions[routine.id];
    if (current.status != ProgramRoutinesStatus.ready ||
        current.saving ||
        guarded is! RoutineVersionedRenameRepository ||
        expectedRevision == null ||
        routine.programId != program.id ||
        !current.routines.any((item) => item == routine)) {
      return 'Could not edit routine. Please try again.';
    }
    if (name.trim().isEmpty) return 'Enter a routine name.';
    if (name == routine.name) return null;

    final command = RoutineAggregateUpdate(
      routineId: routine.id,
      programId: program.id,
      expectedRevision: expectedRevision,
      expectedName: routine.name,
      mutationId: _uuidV4(),
      name: name,
    );
    _publish(ProgramRoutinesState.ready(
      routines: current.routines,
      saving: true,
    ));
    int? confirmedRevision;
    Object? error;
    try {
      confirmedRevision = await guarded.renameVersioned(command);
    } catch (caught) {
      error = caught;
    }
    try {
      final read = await _readOwnedRoutines();
      if (_disposed) return 'Could not edit routine. Please try again.';
      _acceptRead(read);
      if (confirmedRevision == expectedRevision + 1 &&
          read.revisions[routine.id] == confirmedRevision &&
          read.routines.any((item) =>
              item.id == routine.id &&
              item.programId == program.id &&
              item.name == name)) {
        return null;
      }
    } catch (_) {
      // Unknown outcome: do not retry with a fresh token or claim success.
      if (_disposed) return 'Could not edit routine. Please try again.';
      _loadedRevisions.clear();
      _publish(ProgramRoutinesState.ready(routines: current.routines));
    }
    return error is StateError &&
            error.message.toString() == 'Please sign in to save Routines.'
        ? 'Please sign in to save Routines.'
        : 'Could not confirm the routine name. Please try again.';
  }

  Future<({List<Routine> routines, Map<RoutineId, int> revisions})?>
      _reconcileCreate(Routine attempted) async {
    try {
      final read = await _readOwnedRoutines();
      final matches = read.routines.where((r) => r.id == attempted.id);
      if (matches.length != 1) return null;
      if (matches.single.name == attempted.name) return read;
      // A committed Create with a different current name may have a later
      // owner edit. Never blindly Rename or reuse its UUID as a new identity.
    } catch (_) {
      // Preserve the frozen pending UUID until explicit editor abandonment.
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
