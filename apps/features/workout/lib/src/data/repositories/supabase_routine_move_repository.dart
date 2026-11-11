import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';
import '../../domain/repositories/routine_move_repository.dart';
import 'routine_move_delete_attempt_gate.dart';

/// Read-only owner snapshot plus the single protected M1 RPC. Never table UPDATE.
abstract interface class RoutineMoveGateway {
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId,
    required String routineId,
  });
  Future<Object?> move({
    required String routineId,
    required String sourceProgramId,
    required String destinationProgramId,
    required int expectedRevision,
    required String mutationId,
  });
  Future<Object?> createAndMove({
    required String routineId,
    required String sourceProgramId,
    required String newProgramId,
    required String newProgramName,
    required int expectedRevision,
    required String mutationId,
  });
  Future<Object?> undoCreateAndMove({
    required String routineId,
    required String originalProgramId,
    required String createdProgramId,
    required String originalMoveMutationId,
    required int expectedRevision,
    required String undoMutationId,
  });
}

final class SupabaseRoutineMoveGateway implements RoutineMoveGateway {
  const SupabaseRoutineMoveGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId,
    required String routineId,
  }) =>
      _client
          .from('user_workout_routines')
          .select(
              'id,user_id,program_id,name,composition_revision,last_composition_mutation_id')
          .eq('user_id', userId)
          .eq('id', routineId)
          .maybeSingle()
          .retry(enabled: false);

  @override
  Future<Object?> move({
    required String routineId,
    required String sourceProgramId,
    required String destinationProgramId,
    required int expectedRevision,
    required String mutationId,
  }) =>
      _client.rpc<Object?>('move_user_workout_routine', params: {
        'p_routine_id': routineId,
        'p_source_program_id': sourceProgramId,
        'p_destination_program_id': destinationProgramId,
        'p_expected_revision': expectedRevision,
        'p_client_mutation_id': mutationId,
      }).retry(enabled: false);

  @override
  Future<Object?> createAndMove({
    required String routineId,
    required String sourceProgramId,
    required String newProgramId,
    required String newProgramName,
    required int expectedRevision,
    required String mutationId,
  }) =>
      _client.rpc<Object?>(
        'create_user_workout_program_and_move_routine',
        params: {
          'p_routine_id': routineId,
          'p_source_program_id': sourceProgramId,
          'p_new_program_id': newProgramId,
          'p_new_program_name': newProgramName,
          'p_expected_revision': expectedRevision,
          'p_client_mutation_id': mutationId,
        },
      ).retry(enabled: false);

  @override
  Future<Object?> undoCreateAndMove({
    required String routineId,
    required String originalProgramId,
    required String createdProgramId,
    required String originalMoveMutationId,
    required int expectedRevision,
    required String undoMutationId,
  }) =>
      _client.rpc<Object?>(
        'undo_create_user_workout_program_and_move_routine',
        params: {
          'p_routine_id': routineId,
          'p_original_program_id': originalProgramId,
          'p_created_program_id': createdProgramId,
          'p_original_move_mutation_id': originalMoveMutationId,
          'p_expected_revision': expectedRevision,
          'p_undo_mutation_id': undoMutationId,
        },
      ).retry(enabled: false);
}

typedef RoutineMoveCurrentValue = String? Function();

/// Checked synchronously before a Move RPC, never after dispatch.
typedef RoutineMovePendingCreateCheck = bool Function(
    String owner, ProgramId programId);
typedef _Session = ({String owner, String cycle});
typedef _Header = ({
  RoutineId id,
  ProgramId program,
  String name,
  int revision,
  String? lastMutationId,
});
typedef _UnknownAttempt = ({
  RoutineMoveTarget target,
  ProgramId destination,
  String mutationId,
});
typedef _CreateMoveUndoAttempt = ({
  RoutineCreateMoveUndoReceipt receipt,
  String mutationId,
});

/// One gate must be shared by all Move repository instances in the app.
/// Not durable across a process restart; no ambiguous write replay.
final class RoutineMoveAttemptGate {
  final Map<String, RoutineMoveTarget> _prepared = {};
  final Map<String, int> _inspectGeneration = {};
  final Map<String, int> _dispatchGeneration = {};
  final Map<String, int> _uncertainRevision = {};
  final Map<String, _UnknownAttempt> _unknownAttempts = {};
  final Map<String, _CreateMoveUndoAttempt> _createMoveUndoAttempts = {};
  final Map<String, int> _crossGeneration = {};
  final Set<String> _inFlight = {};
}

final class SupabaseRoutineMoveRepository
    implements
        RoutineMoveRepository,
        RoutineCreateMoveRepository,
        RoutineMoveUnknownVerifier,
        RoutineCreateMoveUndoRepository,
        RoutineCreateMoveUndoUnknownVerifier {
  SupabaseRoutineMoveRepository({
    required RoutineMoveGateway gateway,
    required RoutineMoveAttemptGate attemptGate,
    RoutineMoveDeleteAttemptGate? crossOperationGate,
    RoutineMovePendingCreateCheck? pendingCreateForProgram,
    required RoutineMoveCurrentValue currentUserId,
    required RoutineMoveCurrentValue currentLoginCycleId,
    Duration timeout = const Duration(seconds: 15),
  })  : _gateway = gateway,
        _gate = attemptGate,
        _crossOperationGate = crossOperationGate,
        _pendingCreateForProgram = pendingCreateForProgram,
        _user = currentUserId,
        _cycle = currentLoginCycleId,
        _timeout = timeout {
    if (timeout <= Duration.zero) throw ArgumentError.value(timeout, 'timeout');
  }

  factory SupabaseRoutineMoveRepository.fromClient({
    required SupabaseClient client,
    required RoutineMoveAttemptGate attemptGate,
    required RoutineMoveDeleteAttemptGate crossOperationGate,
    required RoutineMovePendingCreateCheck pendingCreateForProgram,
    required RoutineMoveCurrentValue currentLoginCycleId,
  }) =>
      SupabaseRoutineMoveRepository(
        gateway: SupabaseRoutineMoveGateway(client),
        attemptGate: attemptGate,
        crossOperationGate: crossOperationGate,
        pendingCreateForProgram: pendingCreateForProgram,
        currentUserId: () => client.auth.currentUser?.id,
        currentLoginCycleId: currentLoginCycleId,
      );

  final RoutineMoveGateway _gateway;
  final RoutineMoveAttemptGate _gate;
  final RoutineMoveDeleteAttemptGate? _crossOperationGate;
  final RoutineMovePendingCreateCheck? _pendingCreateForProgram;
  final RoutineMoveCurrentValue _user;
  final RoutineMoveCurrentValue _cycle;
  final Duration _timeout;

  /// An unresolved Create can commit after login-cycle or route changes.
  /// Do not expose its private command; deny only the affected Program.
  /// A failed callback must fail closed, before dispatching a Move RPC.
  bool _blockedByCreate(String owner, ProgramId source, ProgramId target) {
    final check = _pendingCreateForProgram;
    if (check == null) return false; // Optional only in isolated tests.
    try {
      return check(owner, source) || check(owner, target);
    } catch (_) {
      return true;
    }
  }

  @override
  Future<RoutineMoveTarget?> inspect({
    required ProgramId sourceProgramId,
    required RoutineId routineId,
  }) async {
    final session = _session();
    final key = _ownerKey(session, routineId);
    final cycleKey = _cycleKey(session, routineId);
    final crossGeneration =
        _crossOperationGate?.generation(session.owner, routineId);
    if (_crossOperationGate?.inFlight(session.owner, routineId) == true ||
        _gate._inFlight.contains(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    final seq = (_gate._inspectGeneration[cycleKey] ?? 0) + 1;
    _gate._inspectGeneration[cycleKey] = seq;
    _gate._prepared.remove(cycleKey);
    final dispatched = _gate._dispatchGeneration[key] ?? 0;
    final header = await _read(session, routineId);
    if (_crossOperationGate?.inFlight(session.owner, routineId) == true ||
        _gate._inFlight.contains(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    if (_crossOperationGate?.generation(session.owner, routineId) !=
            crossGeneration ||
        _gate._inspectGeneration[cycleKey] != seq ||
        _gate._dispatchGeneration[key] != null &&
            _gate._dispatchGeneration[key] != dispatched) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    if (header != null) {
      _crossOperationGate?.observeRevision(
          session.owner, routineId, header.revision);
    }
    if (header == null || header.program != sourceProgramId) return null;
    final unknown = _gate._uncertainRevision[key];
    if (unknown != null && header.revision > unknown) {
      // An old CAS can no longer commit at the original revision.
      _gate._uncertainRevision.remove(key);
      _gate._unknownAttempts.remove(key);
      _gate._createMoveUndoAttempts.remove(key);
    }
    final target = RoutineMoveTarget(
      routineId: header.id,
      sourceProgramId: header.program,
      name: header.name,
      expectedRevision: header.revision,
      ownerId: session.owner,
      loginCycleId: session.cycle,
    );
    _gate._prepared[cycleKey] = target;
    _gate._crossGeneration[cycleKey] =
        _crossOperationGate?.generation(session.owner, routineId) ?? 0;
    return target;
  }

  @override
  Future<RoutineMoveResult> move({
    required RoutineMoveTarget target,
    required ProgramId destinationProgramId,
    required String mutationId,
  }) async {
    final session = _session();
    if (session.owner != target.ownerId ||
        session.cycle != target.loginCycleId) {
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
    if (destinationProgramId == target.sourceProgramId ||
        target.expectedRevision == 9223372036854775807 ||
        !_isUuid(mutationId)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.invalidRequest);
    }
    final key = _ownerKey(session, target.routineId);
    final cycleKey = _cycleKey(session, target.routineId);
    if (_gate._uncertainRevision.containsKey(key)) {
      throw const RoutineMoveOutcomeUnknown();
    }
    if (_gate._inFlight.contains(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    if (!identical(_gate._prepared[cycleKey], target)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    final cross = _crossOperationGate;
    if (cross != null) {
      if (cross.uncertain(session.owner, target.routineId)) {
        throw const RoutineMoveOutcomeUnknown();
      }
      if (cross.inFlight(session.owner, target.routineId)) {
        throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
      }
      if (_gate._crossGeneration[cycleKey] !=
          cross.generation(session.owner, target.routineId)) {
        throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
      }
    }
    // Preserve same-Routine UNKNOWN/stale-target error precedence before
    // checking a different Routine's pending Create in these Programs.
    if (_blockedByCreate(
        session.owner, target.sourceProgramId, destinationProgramId)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    if (cross != null) {
      if (!cross.tryStart(session.owner, target.routineId)) {
        throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
      }
    }
    _gate._prepared.remove(cycleKey);
    _gate._inFlight.add(key);
    _gate._dispatchGeneration[key] = (_gate._dispatchGeneration[key] ?? 0) + 1;
    try {
      Object? response;
      try {
        response = await _gateway
            .move(
              routineId: target.routineId.value,
              sourceProgramId: target.sourceProgramId.value,
              destinationProgramId: destinationProgramId.value,
              expectedRevision: target.expectedRevision,
              mutationId: mutationId.toLowerCase(),
            )
            .timeout(_timeout);
      } on PostgrestException catch (e) {
        // A definitive database rejection still belongs to the frozen owner
        // session. Never surface stale-cycle results after an awaited RPC.
        if (!_sameSession(session)) {
          throw const RoutineMoveOutcomeUnknown(
            reason: RoutineMoveUncertainty.sessionChanged,
          );
        }
        final known = _definite(e);
        if (known != null) throw RoutineMoveException(known);
        return await _unknown(target, session);
      } catch (_) {
        return await _unknown(target, session);
      }
      if (!_sameSession(session)) {
        throw const RoutineMoveOutcomeUnknown(
            reason: RoutineMoveUncertainty.sessionChanged);
      }
      if (response is int && response == target.expectedRevision + 1) {
        return RoutineMoveResult.confirmed;
      }
      return await _unknown(target, session);
    } on RoutineMoveOutcomeUnknown {
      _gate._uncertainRevision[key] = target.expectedRevision;
      // Freeze only the attempt that may have reached the server. A later
      // readback must match THIS token, not just destination membership.
      _gate._unknownAttempts[key] = (
        target: target,
        destination: destinationProgramId,
        mutationId: mutationId.toLowerCase(),
      );
      _crossOperationGate?.markUncertain(
          session.owner, target.routineId, target.expectedRevision);
      rethrow;
    } finally {
      _gate._inFlight.remove(key);
      _crossOperationGate?.finish(session.owner, target.routineId);
    }
  }

  /// One atomic RPC, with the SAME process-shared gate as existing Move.
  /// An unknown outcome blocks further moves at this Routine revision.
  @override
  Future<RoutineMoveResult> createAndMove({
    required RoutineMoveTarget target,
    required ProgramId newProgramId,
    required String newProgramName,
    required String mutationId,
  }) async {
    final session = _session();
    if (session.owner != target.ownerId ||
        session.cycle != target.loginCycleId) {
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
    if (newProgramId == target.sourceProgramId ||
        !_isUuid(newProgramId.value) ||
        !_isUuid(mutationId) ||
        newProgramName.trim().isEmpty ||
        target.expectedRevision == 9223372036854775807) {
      throw const RoutineMoveException(RoutineMoveFailureKind.invalidRequest);
    }
    final key = _ownerKey(session, target.routineId);
    final cycleKey = _cycleKey(session, target.routineId);
    if (_gate._uncertainRevision.containsKey(key)) {
      throw const RoutineMoveOutcomeUnknown();
    }
    if (_gate._inFlight.contains(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    if (!identical(_gate._prepared[cycleKey], target)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    final cross = _crossOperationGate;
    if (cross != null) {
      if (cross.uncertain(session.owner, target.routineId)) {
        throw const RoutineMoveOutcomeUnknown();
      }
      if (cross.inFlight(session.owner, target.routineId)) {
        throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
      }
      if (_gate._crossGeneration[cycleKey] !=
          cross.generation(session.owner, target.routineId)) {
        throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
      }
    }
    // Preserve same-Routine UNKNOWN/stale-target error precedence before
    // checking a different Routine's pending Create in these Programs.
    if (_blockedByCreate(session.owner, target.sourceProgramId, newProgramId)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    if (cross != null) {
      if (!cross.tryStart(session.owner, target.routineId)) {
        throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
      }
    }
    _gate._prepared.remove(cycleKey);
    _gate._inFlight.add(key);
    _gate._dispatchGeneration[key] = (_gate._dispatchGeneration[key] ?? 0) + 1;
    try {
      Object? response;
      try {
        response = await _gateway
            .createAndMove(
              routineId: target.routineId.value,
              sourceProgramId: target.sourceProgramId.value,
              newProgramId: newProgramId.value,
              newProgramName: newProgramName,
              expectedRevision: target.expectedRevision,
              mutationId: mutationId.toLowerCase(),
            )
            .timeout(_timeout);
      } on PostgrestException catch (e) {
        // A definitive database rejection still belongs to the frozen owner
        // session. Never surface stale-cycle results after an awaited RPC.
        if (!_sameSession(session)) {
          throw const RoutineMoveOutcomeUnknown(
            reason: RoutineMoveUncertainty.sessionChanged,
          );
        }
        final known = _definite(e);
        if (known != null) throw RoutineMoveException(known);
        return await _unknown(target, session);
      } catch (_) {
        return await _unknown(target, session);
      }
      if (!_sameSession(session)) {
        throw const RoutineMoveOutcomeUnknown(
            reason: RoutineMoveUncertainty.sessionChanged);
      }
      if (response is int && response == target.expectedRevision + 1) {
        return RoutineMoveResult.confirmed;
      }
      return await _unknown(target, session);
    } on RoutineMoveOutcomeUnknown {
      _gate._uncertainRevision[key] = target.expectedRevision;
      // Freeze only the attempt that may have reached the server. A later
      // readback must match THIS token, not just destination membership.
      _gate._unknownAttempts[key] = (
        target: target,
        destination: newProgramId,
        mutationId: mutationId.toLowerCase(),
      );
      _crossOperationGate?.markUncertain(
          session.owner, target.routineId, target.expectedRevision);
      rethrow;
    } finally {
      _gate._inFlight.remove(key);
      _crossOperationGate?.finish(session.owner, target.routineId);
    }
  }

  /// Full M5B Undo is one server-authoritative transaction. Shared process
  /// and cross-operation gates prevent overlapping commands; the RPC remains
  /// the owner/provenance/CAS authority.
  @override
  Future<RoutineMoveResult> undoCreateAndMove({
    required RoutineCreateMoveUndoReceipt receipt,
    required String undoMutationId,
  }) async {
    final session = _session();
    if (session.owner != receipt.ownerId ||
        session.cycle != receipt.loginCycleId) {
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
    final frozenMutationId = undoMutationId.toLowerCase();
    if (receipt.originalProgramId == receipt.createdProgramId ||
        !_isUuid(receipt.originalMoveMutationId) ||
        !_isUuid(undoMutationId) ||
        receipt.originalMoveMutationId.toLowerCase() == frozenMutationId ||
        receipt.expectedRevision < 1 ||
        receipt.expectedRevision == 9223372036854775807) {
      throw const RoutineMoveException(RoutineMoveFailureKind.invalidRequest);
    }

    final key = _ownerKey(session, receipt.routineId);
    if (_gate._uncertainRevision.containsKey(key)) {
      throw const RoutineMoveOutcomeUnknown();
    }
    if (_gate._inFlight.contains(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    final cross = _crossOperationGate;
    if (cross != null) {
      if (cross.uncertain(session.owner, receipt.routineId)) {
        throw const RoutineMoveOutcomeUnknown();
      }
      if (cross.inFlight(session.owner, receipt.routineId)) {
        throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
      }
    }
    if (_blockedByCreate(
        session.owner, receipt.originalProgramId, receipt.createdProgramId)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    if (cross != null && !cross.tryStart(session.owner, receipt.routineId)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }

    _gate._prepared.remove(_cycleKey(session, receipt.routineId));
    _gate._inFlight.add(key);
    _gate._dispatchGeneration[key] = (_gate._dispatchGeneration[key] ?? 0) + 1;
    try {
      Object? response;
      try {
        response = await _gateway
            .undoCreateAndMove(
              routineId: receipt.routineId.value,
              originalProgramId: receipt.originalProgramId.value,
              createdProgramId: receipt.createdProgramId.value,
              originalMoveMutationId:
                  receipt.originalMoveMutationId.toLowerCase(),
              expectedRevision: receipt.expectedRevision,
              undoMutationId: frozenMutationId,
            )
            .timeout(_timeout);
      } on PostgrestException catch (e) {
        if (!_sameSession(session)) {
          throw const RoutineMoveOutcomeUnknown(
            reason: RoutineMoveUncertainty.sessionChanged,
          );
        }
        final known = _definite(e);
        if (known != null) throw RoutineMoveException(known);
        return await _unknownCreateMoveUndo(receipt, session);
      } catch (_) {
        return await _unknownCreateMoveUndo(receipt, session);
      }
      if (!_sameSession(session)) {
        throw const RoutineMoveOutcomeUnknown(
          reason: RoutineMoveUncertainty.sessionChanged,
        );
      }
      if (response is int && response == receipt.expectedRevision + 1) {
        return RoutineMoveResult.confirmed;
      }
      return await _unknownCreateMoveUndo(receipt, session);
    } on RoutineMoveOutcomeUnknown {
      _gate._uncertainRevision[key] = receipt.expectedRevision;
      _gate._createMoveUndoAttempts[key] = (
        receipt: receipt,
        mutationId: frozenMutationId,
      );
      cross?.markUncertain(
          session.owner, receipt.routineId, receipt.expectedRevision);
      rethrow;
    } finally {
      _gate._inFlight.remove(key);
      cross?.finish(session.owner, receipt.routineId);
    }
  }

  Future<RoutineMoveResult> _unknownCreateMoveUndo(
    RoutineCreateMoveUndoReceipt receipt,
    _Session session,
  ) async {
    if (!_sameSession(session)) {
      throw const RoutineMoveOutcomeUnknown(
        reason: RoutineMoveUncertainty.sessionChanged,
      );
    }
    _Header? header;
    try {
      header = await _read(session, receipt.routineId);
    } catch (_) {
      throw RoutineMoveOutcomeUnknown(
        reason: _sameSession(session)
            ? RoutineMoveUncertainty.unconfirmed
            : RoutineMoveUncertainty.sessionChanged,
      );
    }
    if (!_sameSession(session)) {
      throw const RoutineMoveOutcomeUnknown(
        reason: RoutineMoveUncertainty.sessionChanged,
      );
    }
    throw RoutineMoveOutcomeUnknown(
      reason: header == null
          ? RoutineMoveUncertainty.absentOnRead
          : RoutineMoveUncertainty.stillPresent,
      observedRevision: header?.revision,
      observedProgramId: header?.program,
    );
  }

  @override
  Future<RoutineMoveReadback> verifyUnknownCreateMoveUndo({
    required RoutineCreateMoveUndoReceipt receipt,
    required String undoMutationId,
  }) async {
    final session = _session();
    final key = _ownerKey(session, receipt.routineId);
    if (_gate._inFlight.contains(key) ||
        _crossOperationGate?.inFlight(session.owner, receipt.routineId) ==
            true) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    final pending = _gate._createMoveUndoAttempts[key];
    if (pending == null ||
        !_gate._uncertainRevision.containsKey(key) ||
        !identical(pending.receipt, receipt)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    if (receipt.ownerId != session.owner ||
        receipt.loginCycleId != session.cycle) {
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
    if (!_isUuid(undoMutationId) ||
        pending.mutationId != undoMutationId.toLowerCase()) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }

    final generation = _gate._dispatchGeneration[key];
    _Header? observed;
    try {
      observed = await _read(session, receipt.routineId);
    } on RoutineMoveException catch (e) {
      if (e.kind == RoutineMoveFailureKind.unauthorized) rethrow;
      return const RoutineMoveReadback(
        kind: RoutineMoveReadbackKind.readUnavailable,
      );
    }
    _checkSession(session);
    if (!identical(_gate._createMoveUndoAttempts[key], pending) ||
        !_gate._uncertainRevision.containsKey(key) ||
        _gate._dispatchGeneration[key] != generation ||
        _gate._inFlight.contains(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    if (observed == null) {
      return const RoutineMoveReadback(
        kind: RoutineMoveReadbackKind.absentOnRead,
      );
    }

    final expected = receipt.expectedRevision;
    final exactCommit = observed.revision == expected + 1 &&
        observed.program == receipt.originalProgramId &&
        observed.lastMutationId == pending.mutationId;
    if (observed.revision > expected) {
      _gate._uncertainRevision.remove(key);
      _gate._unknownAttempts.remove(key);
      _gate._createMoveUndoAttempts.remove(key);
      _crossOperationGate?.observeRevision(
          session.owner, receipt.routineId, observed.revision);
    }
    return RoutineMoveReadback(
      kind: exactCommit
          ? RoutineMoveReadbackKind.confirmedLatestMutation
          : observed.revision > expected
              ? RoutineMoveReadbackKind.superseded
              : RoutineMoveReadbackKind.notConfirmed,
      observedProgramId: observed.program,
      observedRevision: observed.revision,
    );
  }

  /// Recheck only the frozen UNKNOWN attempt from this authenticated cycle.
  /// No RPC dispatch, no optimistic inference from Program membership alone.
  /// A latest matching server-side mutation token + Program + revision
  /// identifies this request; a later unrelated write does not.
  @override
  Future<RoutineMoveReadback> verifyUnknown({
    required RoutineId routineId,
    required String mutationId,
  }) async {
    final session = _session();
    final key = _ownerKey(session, routineId);
    if (_gate._inFlight.contains(key) ||
        _crossOperationGate?.inFlight(session.owner, routineId) == true) {
      throw const RoutineMoveException(RoutineMoveFailureKind.inProgress);
    }
    final pending = _gate._unknownAttempts[key];
    if (pending == null || !_gate._uncertainRevision.containsKey(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    // A new login cycle cannot adopt an old callback's recovery capability.
    if (pending.target.loginCycleId != session.cycle) {
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
    // A later command may have been denied by the UNKNOWN hold before any
    // write. Never mistake an earlier command's server receipt for this one.
    // Reject mismatched tokens BEFORE an owner read or hold mutation.
    if (!_isUuid(mutationId) ||
        pending.mutationId != mutationId.toLowerCase()) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    final generation = _gate._dispatchGeneration[key];
    _Header? observed;
    try {
      observed = await _read(session, routineId);
    } on RoutineMoveException catch (e) {
      if (e.kind == RoutineMoveFailureKind.unauthorized) rethrow;
      return const RoutineMoveReadback(
        kind: RoutineMoveReadbackKind.readUnavailable,
      );
    }
    _checkSession(session);
    if (!identical(_gate._unknownAttempts[key], pending) ||
        !_gate._uncertainRevision.containsKey(key) ||
        _gate._dispatchGeneration[key] != generation ||
        _gate._inFlight.contains(key)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    if (observed == null) {
      return const RoutineMoveReadback(
        kind: RoutineMoveReadbackKind.absentOnRead,
      );
    }
    final expected = pending.target.expectedRevision;
    final exactCommit = observed.revision == expected + 1 &&
        observed.program == pending.destination &&
        observed.lastMutationId == pending.mutationId;

    // Only a later owner-verified revision rules out another commit of
    // the frozen original CAS; an unchanged/absent read never unlocks it.
    if (observed.revision > expected) {
      _gate._uncertainRevision.remove(key);
      _gate._unknownAttempts.remove(key);
      _gate._createMoveUndoAttempts.remove(key);
      _crossOperationGate?.observeRevision(
          session.owner, routineId, observed.revision);
    }
    return RoutineMoveReadback(
      kind: exactCommit
          ? RoutineMoveReadbackKind.confirmedLatestMutation
          : observed.revision > expected
              ? RoutineMoveReadbackKind.superseded
              : RoutineMoveReadbackKind.notConfirmed,
      observedProgramId: observed.program,
      observedRevision: observed.revision,
    );
  }

  Future<RoutineMoveResult> _unknown(
    RoutineMoveTarget target,
    _Session session,
  ) async {
    if (!_sameSession(session)) {
      throw const RoutineMoveOutcomeUnknown(
          reason: RoutineMoveUncertainty.sessionChanged);
    }
    _Header? header;
    try {
      header = await _read(session, target.routineId);
    } catch (_) {
      throw RoutineMoveOutcomeUnknown(
          reason: _sameSession(session)
              ? RoutineMoveUncertainty.unconfirmed
              : RoutineMoveUncertainty.sessionChanged);
    }
    if (!_sameSession(session)) {
      throw const RoutineMoveOutcomeUnknown(
          reason: RoutineMoveUncertainty.sessionChanged);
    }
    if (header == null) {
      throw const RoutineMoveOutcomeUnknown(
          reason: RoutineMoveUncertainty.absentOnRead);
    }
    throw RoutineMoveOutcomeUnknown(
      reason: RoutineMoveUncertainty.stillPresent,
      observedRevision: header.revision,
      observedProgramId: header.program,
    );
  }

  Future<_Header?> _read(_Session s, RoutineId id) async {
    _checkSession(s);
    Map<String, dynamic>? row;
    try {
      row = await _gateway
          .readOwnedHeader(
            userId: s.owner,
            routineId: id.value,
          )
          .timeout(_timeout);
    } on PostgrestException catch (e) {
      _checkSession(s);
      throw RoutineMoveException(
          _definite(e) ?? RoutineMoveFailureKind.unavailable);
    } catch (_) {
      _checkSession(s);
      throw const RoutineMoveException(RoutineMoveFailureKind.unavailable);
    }
    _checkSession(s);
    if (row == null) return null;
    try {
      if (row['id'] != id.value ||
          row['user_id'] != s.owner ||
          row['name'] is! String ||
          (row['name'] as String).trim().isEmpty ||
          row['composition_revision'] is! int ||
          (row['composition_revision'] as int) < 0) {
        throw const FormatException('Malformed Routine Move row');
      }
      final lastMutation = row['last_composition_mutation_id'];
      if (lastMutation != null &&
          (lastMutation is! String || !_isUuid(lastMutation))) {
        throw const FormatException('Malformed Routine mutation ID');
      }
      return (
        id: RoutineId(row['id'] as String),
        program: ProgramId(row['program_id'] as String),
        name: row['name'] as String,
        revision: row['composition_revision'] as int,
        lastMutationId: (lastMutation as String?)?.toLowerCase(),
      );
    } catch (_) {
      throw const RoutineMoveException(RoutineMoveFailureKind.malformedData);
    }
  }

  _Session _session() {
    final owner = _user()?.trim().toLowerCase();
    final cycle = _cycle()?.trim();
    if (owner == null || !_isUuid(owner) || cycle == null || cycle.isEmpty) {
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
    return (owner: owner, cycle: cycle);
  }

  bool _sameSession(_Session s) =>
      _user()?.trim().toLowerCase() == s.owner && _cycle()?.trim() == s.cycle;
  void _checkSession(_Session s) {
    if (!_sameSession(s)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
  }

  static String _ownerKey(_Session s, RoutineId id) => '${s.owner}/${id.value}';
  static String _cycleKey(_Session s, RoutineId id) =>
      '${s.owner}/${s.cycle}/${id.value}';
  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);

  static RoutineMoveFailureKind? _definite(PostgrestException e) {
    final code = e.code;
    final n = int.tryParse(code ?? '');
    final status = n != null && n >= 100 && n <= 599 ? n : null;
    if (code == null ||
        code.isEmpty ||
        code.startsWith('08') ||
        status == 408 ||
        status == 499 ||
        (status != null && status >= 500)) {
      return null;
    }
    // SQLSTATE 40003 means statement_completion_unknown; a write may commit.
    if (code == '40003') return null;
    if (RegExp(r'^40[0-9A-Z]{3}$').hasMatch(code)) {
      return RoutineMoveFailureKind.transactionAborted;
    }
    if (RegExp(r'^(22|23)[0-9A-Z]{3}$').hasMatch(code)) {
      return RoutineMoveFailureKind.invalidRequest;
    }
    // Ordinary HTTP 4xx errors from gateway/PostgREST reject this request.
    // 408/499 have already returned UNKNOWN above; never swallow ambiguity.
    if (status != null && status >= 400 && status < 500) {
      if (status == 401) return RoutineMoveFailureKind.unauthorized;
      if (status == 403) return RoutineMoveFailureKind.forbidden;
      return status == 429
          ? RoutineMoveFailureKind.unavailable
          : RoutineMoveFailureKind.invalidRequest;
    }
    return switch (code) {
      // JWT claims failure happens before an RPC can execute.
      '28000' ||
      '28P01' ||
      '401' ||
      'PGRST301' ||
      'PGRST302' ||
      'PGRST303' =>
        RoutineMoveFailureKind.unauthorized,
      '42501' || '403' => RoutineMoveFailureKind.forbidden,
      'P0002' => RoutineMoveFailureKind.notFound,
      'P0001'
          when e.message == 'routine_move_revision_conflict' ||
              e.message == 'routine_create_move_revision_conflict' ||
              e.message == 'routine_create_move_undo_revision_conflict' =>
        RoutineMoveFailureKind.revisionConflict,
      'P0001'
          when e.message == 'routine_move_mutation_conflict' ||
              e.message == 'routine_create_move_mutation_conflict' ||
              e.message == 'routine_create_move_program_conflict' ||
              e.message == 'routine_create_move_undo_mutation_conflict' ||
              e.message == 'routine_create_move_undo_program_modified' ||
              e.message == 'routine_create_move_undo_provenance_conflict' ||
              e.message == 'routine_create_move_undo_delete_conflict' =>
        RoutineMoveFailureKind.mutationConflict,
      'P0001' when e.message == 'routine_create_move_undo_default_program' =>
        RoutineMoveFailureKind.invalidRequest,
      // PostgreSQL Class 53 insufficient resources (including disk full,
      // out of memory, and configuration limit) aborts this RPC transaction.
      // Server-side lock/query cancellation likewise cannot commit.
      '53000' ||
      '53100' ||
      '53200' ||
      '53400' ||
      '55P03' ||
      '57014' =>
        RoutineMoveFailureKind.transactionAborted,
      // Connection rejection/restart before an RPC can acquire a session.
      '53300' || '57P03' => RoutineMoveFailureKind.unavailable,
      '25001' => RoutineMoveFailureKind.invalidRequest,
      // SQLSTATE 25006 rejects writes in read-only database mode.
      '25006' => RoutineMoveFailureKind.unavailable,
      // Connection setup/pool failures (PGRST000-003), RPC routing
      // errors (PGRST106/202/203), and missing JWT secret (PGRST300)
      // all reject before SQL execution, even if HTTP status is 5xx.
      // Transport failures and other SQL 5xx remain UNKNOWN.
      'PGRST000' ||
      'PGRST001' ||
      'PGRST002' ||
      'PGRST003' ||
      'PGRST106' ||
      'PGRST202' ||
      'PGRST203' ||
      'PGRST300' =>
        RoutineMoveFailureKind.unavailable,
      _ => null,
    };
  }
}
