import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_delete_repository.dart';

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

/// Authenticated owner/cycle-bound adapter for the deployed #526 boolean RPC.
/// Does not assume a successful client-side HTTP call proves authorization.
final class SupabaseRoutineDeleteRepository implements RoutineDeleteRepository {
  SupabaseRoutineDeleteRepository({
    required RoutineDeleteGateway gateway,
    required RoutineDeleteCurrentValue currentUserId,
    required RoutineDeleteCurrentValue currentLoginCycleId,
    Duration timeout = const Duration(seconds: 15),
  })  : _gateway = gateway,
        _currentUserId = currentUserId,
        _currentLoginCycleId = currentLoginCycleId,
        _timeout = timeout {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout');
    }
  }

  factory SupabaseRoutineDeleteRepository.fromClient({
    required SupabaseClient client,
    required RoutineDeleteCurrentValue currentLoginCycleId,
  }) => SupabaseRoutineDeleteRepository(
    gateway: SupabaseRoutineDeleteGateway(client),
    currentUserId: () => client.auth.currentUser?.id,
    currentLoginCycleId: currentLoginCycleId,
  );

  final RoutineDeleteGateway _gateway;
  final RoutineDeleteCurrentValue _currentUserId;
  final RoutineDeleteCurrentValue _currentLoginCycleId;
  final Duration _timeout;

  // A failed/unknown write must not be started again against the same frozen
  // target until an explicit fresh, successful owner read via inspect().
  final Set<String> _unconfirmed = {};
  final Set<String> _inFlight = {};

  @override
  Future<RoutineDeleteTarget?> inspect({
    required ProgramId programId,
    required RoutineId routineId,
  }) async {
    final session = _session();
    final row = await _read(session, routineId);
    if (row == null || row.program != programId) return null;
    _unconfirmed.remove(_key(session, routineId));
    return RoutineDeleteTarget(
      routineId: row.id,
      programId: row.program,
      name: row.name,
      expectedRevision: row.revision,
      ownerId: session.owner,
      loginCycleId: session.cycle,
    );
  }

  @override
  Future<RoutineDeleteResult> delete(RoutineDeleteTarget target) async {
    final session = _session();
    if (session.owner != target.ownerId ||
        session.cycle != target.loginCycleId) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.unauthorized);
    }
    final key = _key(session, target.routineId);
    if (_unconfirmed.contains(key)) {
      throw const RoutineDeleteOutcomeUnknown();
    }
    if (!_inFlight.add(key)) {
      throw const RoutineDeleteException(RoutineDeleteFailureKind.inProgress);
    }

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
      _unconfirmed.add(key);
      rethrow;
    } finally {
      _inFlight.remove(key);
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
      return RoutineDeleteResult.absentAfterUncertain;
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

  static String _key(_Session session, RoutineId id) =>
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
    return switch (code) {
      '28000' || '28P01' || '401' ||
      'PGRST301' || 'PGRST302' || 'PGRST303' =>
        RoutineDeleteFailureKind.unauthorized,
      '42501' || '403' => RoutineDeleteFailureKind.forbidden,
      'P0002' when e.message == 'routine_delete_not_found' =>
        RoutineDeleteFailureKind.notFound,
      'P0001' when e.message == 'routine_delete_revision_conflict' =>
        RoutineDeleteFailureKind.revisionConflict,
      '22023' || '22P02' || '22003' || '23514' ||
      '23503' || '23505' || 'P0001' || 'P0002' =>
        RoutineDeleteFailureKind.invalidRequest,
      'PGRST202' || 'PGRST203' => RoutineDeleteFailureKind.unavailable,
      _ when status != null && status >= 400 && status < 500 =>
        RoutineDeleteFailureKind.invalidRequest,
      _ => null,
    };
  }
}
