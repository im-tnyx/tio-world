import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/program_delete_repository.dart';

abstract interface class ProgramDeleteGateway {
  Future<Object?> delete({
    required String sourceProgramId,
    required List<String> expectedRoutineIds,
    required String clientMutationId,
  });
}

final class SupabaseProgramDeleteGateway implements ProgramDeleteGateway {
  const SupabaseProgramDeleteGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> delete({
    required String sourceProgramId,
    required List<String> expectedRoutineIds,
    required String clientMutationId,
  }) =>
      _client
          .rpc<Object?>(
            'delete_user_workout_program_preserving_routines',
            params: {
              'p_source_program_id': sourceProgramId,
              'p_expected_routine_ids': expectedRoutineIds,
              'p_client_mutation_id': clientMutationId,
            },
          )
          .retry(enabled: false);
}

typedef ProgramDeleteCurrentValue = String? Function();
typedef _Session = ({String owner, String cycle});

/// Process-local one-use/UNKNOWN guard shared by the app composition owner.
/// An ambiguous Program Delete has no client-side release path because a
/// later missing-source read cannot prove that this mutation committed.
final class ProgramDeleteAttemptGate {
  final Set<String> _inFlight = {};
  final Set<String> _consumed = {};
  final Set<String> _unknown = {};

  bool isUnknown(String owner, ProgramId sourceProgramId) =>
      _unknown.contains(_key(owner, sourceProgramId));

  bool isInFlight(String owner, ProgramId sourceProgramId) =>
      _inFlight.contains(_key(owner, sourceProgramId));

  bool isConsumed(String owner, ProgramId sourceProgramId) =>
      _consumed.contains(_key(owner, sourceProgramId));

  bool tryStart(String owner, ProgramId sourceProgramId) {
    final key = _key(owner, sourceProgramId);
    if (_inFlight.contains(key) ||
        _consumed.contains(key) ||
        _unknown.contains(key)) {
      return false;
    }
    _inFlight.add(key);
    _consumed.add(key);
    return true;
  }

  void markUnknown(String owner, ProgramId sourceProgramId) {
    final key = _key(owner, sourceProgramId);
    if (_inFlight.contains(key)) _unknown.add(key);
  }

  void finish(String owner, ProgramId sourceProgramId) {
    _inFlight.remove(_key(owner, sourceProgramId));
  }

  static String _key(String owner, ProgramId sourceProgramId) =>
      '$owner/${sourceProgramId.value}';
}

final class SupabaseProgramDeleteRepository
    implements ProgramDeleteRepository {
  SupabaseProgramDeleteRepository({
    required ProgramDeleteGateway gateway,
    required ProgramDeleteAttemptGate attemptGate,
    required ProgramDeleteCurrentValue currentUserId,
    required ProgramDeleteCurrentValue currentLoginCycleId,
    Duration timeout = const Duration(seconds: 15),
  })  : _gateway = gateway,
        _attemptGate = attemptGate,
        _currentUserId = currentUserId,
        _currentLoginCycleId = currentLoginCycleId,
        _timeout = timeout {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout');
    }
  }

  factory SupabaseProgramDeleteRepository.fromClient({
    required SupabaseClient client,
    required ProgramDeleteAttemptGate attemptGate,
    required ProgramDeleteCurrentValue currentLoginCycleId,
  }) =>
      SupabaseProgramDeleteRepository(
        gateway: SupabaseProgramDeleteGateway(client),
        attemptGate: attemptGate,
        currentUserId: () => client.auth.currentUser?.id,
        currentLoginCycleId: currentLoginCycleId,
      );

  final ProgramDeleteGateway _gateway;
  final ProgramDeleteAttemptGate _attemptGate;
  final ProgramDeleteCurrentValue _currentUserId;
  final ProgramDeleteCurrentValue _currentLoginCycleId;
  final Duration _timeout;

  @override
  Future<ProgramDeleteResult> delete({
    required ProgramDeleteTarget target,
    required String clientMutationId,
  }) async {
    final session = _session();
    if (session.owner != target.ownerId ||
        session.cycle != target.loginCycleId) {
      throw const ProgramDeleteException(
        ProgramDeleteFailureKind.unauthorized,
      );
    }

    final mutationId = clientMutationId.trim().toLowerCase();
    if (!_isUuid(mutationId)) {
      throw const ProgramDeleteException(
        ProgramDeleteFailureKind.invalidRequest,
      );
    }

    if (_attemptGate.isUnknown(session.owner, target.sourceProgramId)) {
      throw const ProgramDeleteOutcomeUnknown();
    }
    if (_attemptGate.isInFlight(session.owner, target.sourceProgramId)) {
      throw const ProgramDeleteException(ProgramDeleteFailureKind.inProgress);
    }
    if (_attemptGate.isConsumed(session.owner, target.sourceProgramId) ||
        !_attemptGate.tryStart(session.owner, target.sourceProgramId)) {
      throw const ProgramDeleteException(
        ProgramDeleteFailureKind.staleMembership,
      );
    }

    try {
      Object? response;
      try {
        response = await _gateway
            .delete(
              sourceProgramId: target.sourceProgramId.value,
              expectedRoutineIds: [
                for (final id in target.expectedRoutineIds) id.value,
              ],
              clientMutationId: mutationId,
            )
            .timeout(_timeout);
      } on PostgrestException catch (error) {
        final failure = _definite(error);
        if (failure != null) throw failure;
        throw _unknown(session);
      } catch (_) {
        throw _unknown(session);
      }

      if (!_sameSession(session)) {
        throw const ProgramDeleteOutcomeUnknown(
          reason: ProgramDeleteUncertainty.sessionChanged,
        );
      }
      try {
        return _decodeResult(response, target);
      } on FormatException {
        throw const ProgramDeleteOutcomeUnknown(
          reason: ProgramDeleteUncertainty.malformedResponse,
        );
      }
    } on ProgramDeleteOutcomeUnknown {
      _attemptGate.markUnknown(session.owner, target.sourceProgramId);
      rethrow;
    } finally {
      _attemptGate.finish(session.owner, target.sourceProgramId);
    }
  }

  ProgramDeleteOutcomeUnknown _unknown(_Session session) =>
      ProgramDeleteOutcomeUnknown(
        reason: _sameSession(session)
            ? ProgramDeleteUncertainty.unconfirmed
            : ProgramDeleteUncertainty.sessionChanged,
      );

  ProgramDeleteResult _decodeResult(
    Object? response,
    ProgramDeleteTarget target,
  ) {
    if (response is! Map ||
        response.length != 3 ||
        !response.containsKey('deleted_program_id') ||
        !response.containsKey('destination_program_id') ||
        !response.containsKey('moved_routine_count')) {
      throw const FormatException('Malformed Program Delete response.');
    }

    final deletedValue = response['deleted_program_id'];
    final destinationValue = response['destination_program_id'];
    final movedValue = response['moved_routine_count'];
    if (deletedValue is! String ||
        destinationValue != null && destinationValue is! String ||
        movedValue is! int ||
        movedValue < 0 ||
        movedValue != target.expectedRoutineIds.length) {
      throw const FormatException('Malformed Program Delete response.');
    }

    final deletedId = _parseProgramId(deletedValue);
    if (deletedId != target.sourceProgramId) {
      throw const FormatException('Unexpected deleted Program identity.');
    }

    final destinationId = destinationValue == null
        ? null
        : _parseProgramId(destinationValue as String);
    if (movedValue == 0 && destinationId != null ||
        movedValue > 0 &&
            (destinationId == null || destinationId == target.sourceProgramId)) {
      throw const FormatException('Invalid Program Delete destination.');
    }

    return ProgramDeleteResult(
      deletedProgramId: deletedId,
      destinationProgramId: destinationId,
      movedRoutineCount: movedValue,
    );
  }

  static ProgramId _parseProgramId(String value) {
    try {
      return ProgramId(value);
    } on ArgumentError {
      throw const FormatException('Invalid Program identity.');
    }
  }

  _Session _session() {
    final owner = _currentUserId()?.trim().toLowerCase();
    final cycle = _currentLoginCycleId()?.trim();
    if (owner == null ||
        !_isUuid(owner) ||
        cycle == null ||
        cycle.isEmpty) {
      throw const ProgramDeleteException(
        ProgramDeleteFailureKind.unauthorized,
      );
    }
    return (owner: owner, cycle: cycle);
  }

  bool _sameSession(_Session session) =>
      _currentUserId()?.trim().toLowerCase() == session.owner &&
      _currentLoginCycleId()?.trim() == session.cycle;

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
      ).hasMatch(value);

  static ProgramDeleteException? _definite(PostgrestException error) {
    final code = error.code;
    final parsed = int.tryParse(code ?? '');
    final status = parsed != null && parsed >= 100 && parsed <= 599
        ? parsed
        : null;
    if (code == null ||
        code.isEmpty ||
        code.startsWith('08') ||
        status == 408 ||
        status == 499 ||
        status != null && (status >= 500 || status >= 200 && status < 300)) {
      return null;
    }
    if (RegExp(r'^40[0-9A-Z]{3}$').hasMatch(code)) {
      return const ProgramDeleteException(
        ProgramDeleteFailureKind.transactionAborted,
      );
    }
    if (RegExp(r'^(22|23)[0-9A-Z]{3}$').hasMatch(code)) {
      return const ProgramDeleteException(
        ProgramDeleteFailureKind.invalidRequest,
      );
    }
    return switch (code) {
      '28000' || '28P01' || '401' || 'PGRST301' || 'PGRST302' || 'PGRST303' =>
        const ProgramDeleteException(ProgramDeleteFailureKind.unauthorized),
      '42501' || '403' || 'PGRST202' || 'PGRST203' =>
        const ProgramDeleteException(
          ProgramDeleteFailureKind.permissionUnavailable,
        ),
      'P0002' when error.message == 'program_delete_not_found' =>
        const ProgramDeleteException(ProgramDeleteFailureKind.notFound),
      'P0001' when error.message == 'program_delete_default_forbidden' ||
          error.message == 'program_delete_default_conflict' =>
        const ProgramDeleteException(
          ProgramDeleteFailureKind.defaultProtected,
        ),
      'P0001' when error.message == 'program_delete_membership_conflict' ||
          error.message == 'program_delete_revision_conflict' ||
          error.message == 'program_delete_source_conflict' =>
        const ProgramDeleteException(
          ProgramDeleteFailureKind.staleMembership,
        ),
      'P0001' when error.message == 'program_delete_unreviewed_dependency' =>
        const ProgramDeleteException(
          ProgramDeleteFailureKind.invalidRequest,
        ),
      '22023' || '25001' =>
        const ProgramDeleteException(ProgramDeleteFailureKind.invalidRequest),
      'PGRST000' || 'PGRST001' || 'PGRST002' || 'PGRST003' =>
        const ProgramDeleteException(ProgramDeleteFailureKind.unavailable),
      _ when status != null && status >= 400 && status < 500 =>
        const ProgramDeleteException(ProgramDeleteFailureKind.invalidRequest),
      _ => null,
    };
  }
}
