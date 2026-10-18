import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_delete_repository.dart';
import 'routine_move_delete_attempt_gate.dart';

/// Deliberately no table DELETE. Server owns all child cascades and retirement.
abstract interface class RoutineDeleteGateway {
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId,
    required String routineId,
  });

  Future<Object?> delete({
    required String routineId,
    required String programId,
    required int expectedRevision,
  });
}

final class SupabaseRoutineDeleteGateway implements RoutineDeleteGateway {
  const SupabaseRoutineDeleteGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId,
    required String routineId,
  }) async => _client
      .from('user_workout_routines')
      .select('id,user_id,program_id,name,composition_revision')
      .eq('user_id', userId)
      .eq('id', routineId)
      .maybeSingle()
      .retry(enabled: false);

  @override
  Future<Object?> delete({
    required String routineId,
    required String programId,
    required int expectedRevision,
  }) => _client.rpc<Object?>(
    'delete_user_workout_routine',
    params: {
      'p_routine_id': routineId,
      'p_program_id': programId,
      'p_expected_revision': expectedRevision,
    },
  ).retry(enabled: false);
}

typedef RoutineDeleteCurrentValue = String? Function();
typedef _Session = ({String owner, String cycle});
typedef _Header = ({RoutineId id, ProgramId program, int revision, String name});

/// The app composition owner must retain ONE instance across Delete repository
/// recreations, login cycles and UI surfaces for its authenticated runtime.
/// This is deliberately injected rather than silently reinitialized per repo.
/// It is an in-process guard, NOT durable across an OS process restart.
final class RoutineDeleteAttemptGate {
  final Map<String, int> _unconfirmedRevisions = {};
  final Map<String, RoutineDeleteTarget> _preparedTargets = {};
  final Map<String, int> _dispatchGeneration = {};
  final Map<String, int> _inspectionGeneration = {};
  final Map<String, int> _crossGeneration = {};
  final Set<String> _inFlight = {};
}

/// Authenticated owner/cycle-bound adapter for the deployed #526 boolean RPC.
/// Does not assume a successful client-side HTTP call proves authorization.
final class SupabaseRoutineDeleteRepository implements RoutineDeleteRepository {
  SupabaseRoutineDeleteRepository({
    required RoutineDeleteGateway gateway,
    required RoutineDeleteAttemptGate attemptGate,
    RoutineMoveDeleteAttemptGate? crossOperationGate,
    required RoutineDeleteCurrentValue currentUserId,
    required RoutineDeleteCurrentValue currentLoginCycleId,
    Duration timeout = const Duration(seconds: 15),
  })  : _gateway = gateway,
        _gate = attemptGate,
        _crossOperationGate = crossOperationGate,
        _currentUserId = currentUserId,
        _currentLoginCycleId = currentLoginCycleId,
        _timeout = timeout {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout');
    }
  }

  factory SupabaseRoutineDeleteRepository.fromClient({
    required SupabaseClient client,
    required RoutineDeleteAttemptGate attemptGate,
    RoutineMoveDeleteAttemptGate? crossOperationGate,
    required RoutineDeleteCurrentValue currentLoginCycleId,
  }) => SupabaseRoutineDeleteRepository(
    gateway: SupabaseRoutineDeleteGateway(client),
    attemptGate: attemptGate,
    crossOperationGate: crossOperationGate,
    currentUserId: () => client.auth.currentUser?.id,
    currentLoginCycleId: currentLoginCycleId,
  );

  final RoutineDeleteGateway _gateway;
  final RoutineDeleteAttemptGate _gate;
  final RoutineMoveDeleteAttemptGate? _crossOperationGate;
  final RoutineDeleteCurrentValue _currentUserId;
  final RoutineDeleteCurrentValue _currentLoginCycleId;
  final Duration _timeout;

  @override
  Future<RoutineDeleteTarget?> inspect({
    required ProgramId programId,
    required RoutineId routineId,
  }) async {
    final session = _session();
    final ownerKey = _ownerKey(session, routineId);
    final cycleKey = _cycleKey(session, routineId);
    final crossGeneration =
        _crossOperationGate?.generation(session.owner, routineId);
    if (_crossOperationGate?.inFlight(session.owner, routineId) == true ||
        _gate._inFlight.contains(ownerKey)) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.inProgress);
    }
    // Each inspection supersedes the prior destructive capability even if
    // this read fails or discovers a moved/missing Routine.
    final inspection = (_gate._inspectionGeneration[cycleKey] ?? 0) + 1;
    _gate._inspectionGeneration[cycleKey] = inspection;
    _gate._preparedTargets.remove(cycleKey);
    final startGeneration = _gate._dispatchGeneration[ownerKey] ?? 0;
    final row = await _read(session, routineId);
    // A Delete could have started while this read awaited the server, then
    // already committed by the time its old header arrived. Such a read is
    // never valid evidence for a new destructive confirmation.
    if (_crossOperationGate?.inFlight(session.owner, routineId) == true ||
        _gate._inFlight.contains(ownerKey)) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.inProgress);
    }
    if (_crossOperationGate?.generation(session.owner, routineId) !=
            crossGeneration ||
        (_gate._dispatchGeneration[ownerKey] ?? 0) != startGeneration ||
        _gate._inspectionGeneration[cycleKey] != inspection) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.staleTarget);
    }
    if (row != null) {
      _crossOperationGate?.observeRevision(
          session.owner, routineId, row.revision);
    }
    if (row == null || row.program != programId) return null;
    final unresolvedRevision = _gate._unconfirmedRevisions[ownerKey];
    if (unresolvedRevision != null && row.revision > unresolvedRevision) {
      // The old CAS cannot commit at the newly observed revision.
      _gate._unconfirmedRevisions.remove(ownerKey);
    }
    final target = RoutineDeleteTarget(
      routineId: row.id,
      programId: row.program,
      name: row.name,
      expectedRevision: row.revision,
      ownerId: session.owner,
      loginCycleId: session.cycle,
    );
    _gate._preparedTargets[cycleKey] = target;
    _gate._crossGeneration[cycleKey] =
        _crossOperationGate?.generation(session.owner, routineId) ?? 0;
    return target;
  }

  @override
  Future<RoutineDeleteResult> delete(RoutineDeleteTarget target) async {
    final session = _session();
    if (session.owner != target.ownerId ||
        session.cycle != target.loginCycleId) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.unauthorized);
    }
    final ownerKey = _ownerKey(session, target.routineId);
    final cycleKey = _cycleKey(session, target.routineId);
    if (_gate._unconfirmedRevisions.containsKey(ownerKey)) {
      throw const RoutineDeleteOutcomeUnknown();
    }
    if (_gate._inFlight.contains(ownerKey)) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.inProgress);
    }
    // A target is a ONE-USE capability, not merely a matching revision.
    // A definite server rejection also consumes it: a new attempt requires
    // another owner-scoped inspect/confirmation rather than replaying it.
    if (!identical(_gate._preparedTargets[cycleKey], target)) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.staleTarget);
    }
    final cross = _crossOperationGate;
    if (cross != null) {
      if (cross.uncertain(session.owner, target.routineId)) {
        throw const RoutineDeleteOutcomeUnknown();
      }
      if (cross.inFlight(session.owner, target.routineId)) {
        throw const RoutineDeleteException(RoutineDeleteFailureKind.inProgress);
      }
      if (_gate._crossGeneration[cycleKey] !=
          cross.generation(session.owner, target.routineId)) {
        throw const RoutineDeleteException(RoutineDeleteFailureKind.staleTarget);
      }
      if (!cross.tryStart(session.owner, target.routineId)) {
        throw const RoutineDeleteException(RoutineDeleteFailureKind.inProgress);
      }
    }
    _gate._inFlight.add(ownerKey);
    _gate._dispatchGeneration[ownerKey] = (_gate._dispatchGeneration[ownerKey] ?? 0) + 1;
    _gate._preparedTargets.remove(cycleKey);

    try {
      Object? response;
      try {
        response = await _gateway.delete(
          routineId: target.routineId.value,
          programId: target.programId.value,
          expectedRevision: target.expectedRevision,
        ).timeout(_timeout);
      } on PostgrestException catch (error) {
        // A definitive server rejection means this RPC did not commit even
        // if the account changed while the response was in flight.
        final failure = _definite(error);
        if (failure != null) throw RoutineDeleteException(failure);
        return await _reconcile(target, session);
      } catch (_) {
        return await _reconcile(target, session);
      }
      if (!_sameSession(session)) {
        throw const RoutineDeleteOutcomeUnknown(
          reason: RoutineDeleteUncertainty.sessionChanged,
        );
      }
      if (response == true) return RoutineDeleteResult.confirmed;
      // Malformed/false 2xx is NOT a confirmed deletion.
      return await _reconcile(target, session);
    } on RoutineDeleteOutcomeUnknown {
      _gate._unconfirmedRevisions[ownerKey] = target.expectedRevision;
      _crossOperationGate?.markUncertain(
          session.owner, target.routineId, target.expectedRevision);
      rethrow;
    } finally {
      _gate._inFlight.remove(ownerKey);
      _crossOperationGate?.finish(session.owner, target.routineId);
    }
  }

  Future<RoutineDeleteResult> _reconcile(
    RoutineDeleteTarget target,
    _Session session,
  ) async {
    if (!_sameSession(session)) {
      throw const RoutineDeleteOutcomeUnknown(
        reason: RoutineDeleteUncertainty.sessionChanged,
      );
    }
    _Header? observed;
    try {
      observed = await _read(session, target.routineId);
    } catch (_) {
      throw RoutineDeleteOutcomeUnknown(
        reason: _sameSession(session)
            ? RoutineDeleteUncertainty.unconfirmed
            : RoutineDeleteUncertainty.sessionChanged,
      );
    }
    if (!_sameSession(session)) {
      throw const RoutineDeleteOutcomeUnknown(
        reason: RoutineDeleteUncertainty.sessionChanged,
      );
    }
    if (observed == null) {
      // The owner-filtered Data API read can return no rows due to RLS,
      // and a timed-out RPC may still commit AFTER this observation.
      // No ACK means no claimed success, even if currently invisible.
      throw const RoutineDeleteOutcomeUnknown(
        reason: RoutineDeleteUncertainty.absentOnRead,
      );
    }
    // Reads by Routine ID, NOT old Program: a concurrent move is not Delete.
    throw RoutineDeleteOutcomeUnknown(
      reason: RoutineDeleteUncertainty.stillPresent,
      observedRevision: observed.revision,
      observedProgramId: observed.program,
    );
  }

  Future<_Header?> _read(_Session session, RoutineId id) async {
    _checkSession(session);
    Map<String, dynamic>? row;
    try {
      row = await _gateway.readOwnedHeader(
        userId: session.owner,
        routineId: id.value,
      ).timeout(_timeout);
    } on PostgrestException catch (error) {
      _checkSession(session);
      throw RoutineDeleteException(
        _definite(error) ?? RoutineDeleteFailureKind.unavailable,
      );
    } catch (_) {
      _checkSession(session);
      throw const RoutineDeleteException(RoutineDeleteFailureKind.unavailable);
    }
    _checkSession(session);
    if (row == null) return null;
    try {
      if (row['id'] != id.value || row['user_id'] != session.owner ||
          row['name'] is! String ||
          (row['name'] as String).trim().isEmpty ||
          row['composition_revision'] is! int ||
          (row['composition_revision'] as int) < 0) {
        throw const FormatException('Invalid owner Routine header.');
      }
      return (
        id: RoutineId(row['id'] as String),
        program: ProgramId(row['program_id'] as String),
        revision: row['composition_revision'] as int,
        name: row['name'] as String,
      );
    } catch (_) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.malformedData);
    }
  }

  _Session _session() {
    final owner = _currentUserId()?.trim().toLowerCase();
    final cycle = _currentLoginCycleId()?.trim();
    if (owner == null ||
        !RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
            .hasMatch(owner) ||
        cycle == null || cycle.isEmpty) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.unauthorized);
    }
    return (owner: owner, cycle: cycle);
  }

  bool _sameSession(_Session session) =>
      _currentUserId()?.trim().toLowerCase() == session.owner &&
      _currentLoginCycleId()?.trim() == session.cycle;

  void _checkSession(_Session session) {
    if (!_sameSession(session)) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.unauthorized);
    }
  }

  static String _ownerKey(_Session session, RoutineId id) =>
      '${session.owner}/${id.value}';

  static String _cycleKey(_Session session, RoutineId id) =>
      '${session.owner}/${session.cycle}/${id.value}';

  static RoutineDeleteFailureKind? _definite(PostgrestException e) {
    final code = e.code;
    // Five-digit numeric SQLSTATEs (28000, 42501, 22023) are NOT HTTP
    // statuses. Only a real three-digit HTTP status may be treated as 5xx.
    final parsed = int.tryParse(code ?? '');
    final status = parsed != null && parsed >= 100 && parsed <= 599
        ? parsed
        : null;
    if (code == null || code.isEmpty || code.startsWith('08') ||
        status == 408 || status == 499 ||
        (status != null && ((status >= 200 && status < 300) ||
            status >= 500))) {
      return null;
    }
    // A real PostgreSQL SQLSTATE from a completed error response means the
    // database transaction failed, even if PostgREST encoded it as HTTP 500.
    if (RegExp(r'^40[0-9A-Z]{3}$').hasMatch(code)) {
      return RoutineDeleteFailureKind.transactionAborted;
    }
    if (RegExp(r'^(22|23)[0-9A-Z]{3}$').hasMatch(code)) {
      return RoutineDeleteFailureKind.invalidRequest;
    }
    return switch (code) {
      '28000' || '28P01' || '401' ||
      'PGRST301' || 'PGRST302' || 'PGRST303' =>
        RoutineDeleteFailureKind.unauthorized,
      '42501' || '403' => RoutineDeleteFailureKind.forbidden,
      'P0002' when e.message == 'routine_delete_not_found' =>
        RoutineDeleteFailureKind.notFound,
      'P0001' when e.message == 'routine_delete_revision_conflict' =>
        RoutineDeleteFailureKind.revisionConflict,
      'P0001' || 'P0002' => RoutineDeleteFailureKind.invalidRequest,
      'PGRST202' || 'PGRST203' => RoutineDeleteFailureKind.unavailable,
      _ when status != null && status >= 400 && status < 500 =>
        RoutineDeleteFailureKind.invalidRequest,
      _ => null,
    };
  }
}
