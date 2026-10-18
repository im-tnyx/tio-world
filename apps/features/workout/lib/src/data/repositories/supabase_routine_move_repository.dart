import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';
import '../../domain/repositories/routine_move_repository.dart';
import 'routine_move_delete_attempt_gate.dart';

/// Read-only owner snapshot plus the single protected M1 RPC. Never table UPDATE.
abstract interface class RoutineMoveGateway {
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId, required String routineId,
  });
  Future<Object?> move({
    required String routineId, required String sourceProgramId,
    required String destinationProgramId, required int expectedRevision,
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
}

final class SupabaseRoutineMoveGateway implements RoutineMoveGateway {
  const SupabaseRoutineMoveGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId, required String routineId,
  }) => _client.from('user_workout_routines')
      .select('id,user_id,program_id,name,composition_revision')
      .eq('user_id', userId).eq('id', routineId)
      .maybeSingle().retry(enabled: false);

  @override
  Future<Object?> move({
    required String routineId, required String sourceProgramId,
    required String destinationProgramId, required int expectedRevision,
    required String mutationId,
  }) => _client.rpc<Object?>('move_user_workout_routine', params: {
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
  }) => _client.rpc<Object?>(
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
}

typedef RoutineMoveCurrentValue = String? Function();
typedef _Session = ({String owner, String cycle});
typedef _Header = ({RoutineId id, ProgramId program, String name, int revision});

/// One gate must be shared by all Move repository instances in the app.
/// Not durable across a process restart; no ambiguous write replay.
final class RoutineMoveAttemptGate {
  final Map<String, RoutineMoveTarget> _prepared = {};
  final Map<String, int> _inspectGeneration = {};
  final Map<String, int> _dispatchGeneration = {};
  final Map<String, int> _uncertainRevision = {};
  final Map<String, int> _crossGeneration = {};
  final Set<String> _inFlight = {};
}

final class SupabaseRoutineMoveRepository
    implements RoutineMoveRepository, RoutineCreateMoveRepository {
  SupabaseRoutineMoveRepository({
    required RoutineMoveGateway gateway,
    required RoutineMoveAttemptGate attemptGate,
    RoutineMoveDeleteAttemptGate? crossOperationGate,
    required RoutineMoveCurrentValue currentUserId,
    required RoutineMoveCurrentValue currentLoginCycleId,
    Duration timeout = const Duration(seconds: 15),
  }) : _gateway = gateway, _gate = attemptGate,
       _crossOperationGate = crossOperationGate,
       _user = currentUserId, _cycle = currentLoginCycleId,
       _timeout = timeout {
    if (timeout <= Duration.zero) throw ArgumentError.value(timeout, 'timeout');
  }

  factory SupabaseRoutineMoveRepository.fromClient({
    required SupabaseClient client,
    required RoutineMoveAttemptGate attemptGate,
    required RoutineMoveDeleteAttemptGate crossOperationGate,
    required RoutineMoveCurrentValue currentLoginCycleId,
  }) => SupabaseRoutineMoveRepository(
    gateway: SupabaseRoutineMoveGateway(client),
    attemptGate: attemptGate,
    crossOperationGate: crossOperationGate,
    currentUserId: () => client.auth.currentUser?.id,
    currentLoginCycleId: currentLoginCycleId,
  );

  final RoutineMoveGateway _gateway;
  final RoutineMoveAttemptGate _gate;
  final RoutineMoveDeleteAttemptGate? _crossOperationGate;
  final RoutineMoveCurrentValue _user;
  final RoutineMoveCurrentValue _cycle;
  final Duration _timeout;

  @override
  Future<RoutineMoveTarget?> inspect({
    required ProgramId sourceProgramId, required RoutineId routineId,
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
    }
    final target = RoutineMoveTarget(
      routineId: header.id, sourceProgramId: header.program,
      name: header.name, expectedRevision: header.revision,
      ownerId: session.owner, loginCycleId: session.cycle,
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
    if (session.owner != target.ownerId || session.cycle != target.loginCycleId) {
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
        response = await _gateway.move(
          routineId: target.routineId.value,
          sourceProgramId: target.sourceProgramId.value,
          destinationProgramId: destinationProgramId.value,
          expectedRevision: target.expectedRevision,
          mutationId: mutationId.toLowerCase(),
        ).timeout(_timeout);
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
        !_isUuid(newProgramId.value) || !_isUuid(mutationId) ||
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
        response = await _gateway.createAndMove(
          routineId: target.routineId.value,
          sourceProgramId: target.sourceProgramId.value,
          newProgramId: newProgramId.value,
          newProgramName: newProgramName,
          expectedRevision: target.expectedRevision,
          mutationId: mutationId.toLowerCase(),
        ).timeout(_timeout);
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
      _crossOperationGate?.markUncertain(
          session.owner, target.routineId, target.expectedRevision);
      rethrow;
    } finally {
      _gate._inFlight.remove(key);
      _crossOperationGate?.finish(session.owner, target.routineId);
    }
  }

  Future<RoutineMoveResult> _unknown(
    RoutineMoveTarget target, _Session session,
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
      row = await _gateway.readOwnedHeader(
        userId: s.owner, routineId: id.value,
      ).timeout(_timeout);
    } on PostgrestException catch (e) {
      _checkSession(s);
      throw RoutineMoveException(_definite(e) ?? RoutineMoveFailureKind.unavailable);
    } catch (_) {
      _checkSession(s);
      throw const RoutineMoveException(RoutineMoveFailureKind.unavailable);
    }
    _checkSession(s);
    if (row == null) return null;
    try {
      if (row['id'] != id.value || row['user_id'] != s.owner ||
          row['name'] is! String || (row['name'] as String).trim().isEmpty ||
          row['composition_revision'] is! int ||
          (row['composition_revision'] as int) < 0) {
        throw const FormatException('Malformed Routine Move row');
      }
      return (
        id: RoutineId(row['id'] as String),
        program: ProgramId(row['program_id'] as String),
        name: row['name'] as String,
        revision: row['composition_revision'] as int,
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
  bool _sameSession(_Session s) => _user()?.trim().toLowerCase() == s.owner &&
      _cycle()?.trim() == s.cycle;
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
    if (code == null || code.isEmpty || code.startsWith('08') ||
        status == 408 || status == 499 ||
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
      '28000' || '28P01' || '401' || 'PGRST301' || 'PGRST302' ||
          'PGRST303' =>
        RoutineMoveFailureKind.unauthorized,
      '42501' || '403' => RoutineMoveFailureKind.forbidden,
      'P0002' => RoutineMoveFailureKind.notFound,
      'P0001' when e.message == 'routine_move_revision_conflict' ||
          e.message == 'routine_create_move_revision_conflict' =>
        RoutineMoveFailureKind.revisionConflict,
      'P0001' when e.message == 'routine_move_mutation_conflict' ||
          e.message == 'routine_create_move_mutation_conflict' ||
          e.message == 'routine_create_move_program_conflict' =>
        RoutineMoveFailureKind.mutationConflict,
      // PostgreSQL Class 53 insufficient resources (including disk full,
      // out of memory, and configuration limit) aborts this RPC transaction.
      // Server-side lock/query cancellation likewise cannot commit.
      '53000' || '53100' || '53200' || '53400' ||
          '55P03' || '57014' =>
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
      'PGRST000' || 'PGRST001' || 'PGRST002' || 'PGRST003' ||
          'PGRST106' || 'PGRST202' || 'PGRST203' || 'PGRST300' =>
        RoutineMoveFailureKind.unavailable,
      _ => null,
    };
  }
}
