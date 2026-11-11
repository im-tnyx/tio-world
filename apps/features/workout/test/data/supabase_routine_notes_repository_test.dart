import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _other = '99999999-9999-4999-8999-999999999999';
const _routine = '22222222-2222-4222-8222-222222222222';
const _note = '33333333-3333-4333-8333-333333333333';
const _mutation = '44444444-4444-4444-8444-444444444444';

void main() {
  test('create sends canonical scope, normalized body and stable mutation ID',
      () async {
    final gateway = _Gateway(result: _appliedNote(body: 'saved'));
    final repository = _repository(gateway);
    final result = await repository.create(
      RoutineNoteCreate(
        id: _note,
        scope: RoutineNoteScope.routine(RoutineId(_routine)),
        body: '  saved  ',
        mutationId: _mutation,
      ),
    );

    expect(result.body, 'saved');
    expect(gateway.mutateCalls, 1);
    expect(gateway.lastParams, {
      'p_operation': 'create',
      'p_note_id': _note,
      'p_routine_id': _routine,
      'p_exercise_ref': null,
      'p_note_type': 'pinned_routine',
      'p_body': 'saved',
      'p_expected_revision': null,
      'p_mutation_id': _mutation,
    });
  });

  test('known quota rejection maps without reconciliation retry', () async {
    final gateway = _Gateway(
      error: const PostgrestException(
        message: 'routine_note_quota_exceeded',
        code: 'P0001',
      ),
    );
    final repository = _repository(gateway);

    await expectLater(
      repository.create(
        RoutineNoteCreate(
          id: _note,
          scope: RoutineNoteScope.routine(RoutineId(_routine)),
          body: 'saved',
          mutationId: _mutation,
        ),
      ),
      throwsA(isA<RoutineNoteException>().having(
        (error) => error.kind,
        'kind',
        RoutineNoteFailureKind.quotaExceeded,
      )),
    );
    expect(gateway.reconcileCalls, 0);
  });

  test('unknown mutation outcome reconciles using the same mutation ID',
      () async {
    final gateway = _Gateway(
      error: TimeoutException('lost response'),
      reconciliation: _appliedNote(body: 'saved'),
    );
    final repository = _repository(gateway);
    final result = await repository.create(
      RoutineNoteCreate(
        id: _note,
        scope: RoutineNoteScope.routine(RoutineId(_routine)),
        body: 'saved',
        mutationId: _mutation,
      ),
    );

    expect(result.id, _note);
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 1);
    expect(gateway.lastReconciledMutationId, _mutation);
  });

  test('reconcile returns the immutable applied receipt snapshot', () async {
    final gateway = _Gateway(reconciliation: _appliedNote(body: 'original'));
    final repository = _repository(gateway);

    final receipt = await repository.reconcile(_mutation);

    expect(receipt.mutationId, _mutation);
    expect(receipt.status, RoutineNoteMutationReceiptStatus.applied);
    expect(receipt.note?.body, 'original');
    expect(receipt.note?.id, _note);
    expect(gateway.reconcileCalls, 1);
    expect(gateway.readCalls, 0);
  });

  test('2xx mutation decode failure reconciles using the same mutation ID',
      () async {
    final gateway = _Gateway(
      error: const PostgrestException(
        message: 'successful response could not be decoded',
        code: '200',
      ),
      reconciliation: _appliedNote(body: 'saved'),
    );
    final repository = _repository(gateway);

    final result = await repository.create(
      RoutineNoteCreate(
        id: _note,
        scope: RoutineNoteScope.routine(RoutineId(_routine)),
        body: 'saved',
        mutationId: _mutation,
      ),
    );

    expect(result.id, _note);
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 1);
    expect(gateway.lastReconciledMutationId, _mutation);
  });

  test('reconciliation auth failure preserves unknown mutation outcome',
      () async {
    final gateway = _Gateway(
      error: TimeoutException('mutation response lost'),
      reconciliationError: const PostgrestException(
        message: 'JWT expired',
        code: '401',
      ),
    );
    final repository = _repository(gateway);

    await expectLater(
      repository.create(
        RoutineNoteCreate(
          id: _note,
          scope: RoutineNoteScope.routine(RoutineId(_routine)),
          body: 'saved',
          mutationId: _mutation,
        ),
      ),
      throwsA(isA<RoutineNoteOutcomeUnknown>().having(
        (error) => error.mutationId,
        'mutationId',
        _mutation,
      )),
    );
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 1);
    expect(gateway.lastReconciledMutationId, _mutation);
  });

  test('definite mutation auth rejection is not reconciled', () async {
    final gateway = _Gateway(
      error: const PostgrestException(message: 'JWT expired', code: '401'),
    );
    final repository = _repository(gateway);

    await expectLater(
      repository.create(
        RoutineNoteCreate(
          id: _note,
          scope: RoutineNoteScope.routine(RoutineId(_routine)),
          body: 'saved',
          mutationId: _mutation,
        ),
      ),
      throwsA(isA<RoutineNoteException>().having(
        (error) => error.kind,
        'kind',
        RoutineNoteFailureKind.unauthorized,
      )),
    );
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 0);
  });

  test('expired reconciliation is a definite result and preserves mutation ID',
      () async {
    final gateway = _Gateway(
      error: TimeoutException('lost response'),
      reconciliation: {
        'status': 'expired',
        'mutation_id': _mutation,
        'operation': 'create',
        'note_id': _note,
        'created_at': '2026-09-30T10:00:00Z',
      },
    );
    final repository = _repository(gateway);

    await expectLater(
      repository.create(
        RoutineNoteCreate(
          id: _note,
          scope: RoutineNoteScope.routine(RoutineId(_routine)),
          body: 'saved',
          mutationId: _mutation,
        ),
      ),
      throwsA(isA<RoutineNoteException>().having(
        (error) => error.kind,
        'kind',
        RoutineNoteFailureKind.expired,
      )),
    );
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 1);
    expect(gateway.lastReconciledMutationId, _mutation);
  });

  test('expired duplicate mutation result is surfaced without re-reconcile',
      () async {
    final gateway = _Gateway(
      result: {
        'status': 'expired',
        'mutation_id': _mutation,
        'operation': 'create',
        'note_id': _note,
      },
    );
    final repository = _repository(gateway);

    await expectLater(
      repository.create(
        RoutineNoteCreate(
          id: _note,
          scope: RoutineNoteScope.routine(RoutineId(_routine)),
          body: 'saved',
          mutationId: _mutation,
        ),
      ),
      throwsA(isA<RoutineNoteException>().having(
        (error) => error.kind,
        'kind',
        RoutineNoteFailureKind.expired,
      )),
    );
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 0);
  });

  test('malformed mutation note runtime types map to malformedData', () async {
    final malformed = _appliedNote();
    (malformed['note'] as Map<String, dynamic>)['last_mutation_id'] = 42;
    final gateway = _Gateway(result: malformed);
    final repository = _repository(gateway);

    await expectLater(
      repository.create(
        RoutineNoteCreate(
          id: _note,
          scope: RoutineNoteScope.routine(RoutineId(_routine)),
          body: 'saved',
          mutationId: _mutation,
        ),
      ),
      throwsA(isA<RoutineNoteException>().having(
        (error) => error.kind,
        'kind',
        RoutineNoteFailureKind.malformedData,
      )),
    );
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 0);
  });

  test('account switch after mutation is reported as unknown', () async {
    var owner = _owner;
    final gateway = _Gateway(
      onMutate: () {
        owner = _other;
      },
      result: _appliedNote(body: 'saved'),
    );
    final repository = SupabaseRoutineNotesRepository(
      gateway: gateway,
      currentUserId: () => owner,
    );

    final mutation = repository.create(
      RoutineNoteCreate(
        id: _note,
        scope: RoutineNoteScope.routine(RoutineId(_routine)),
        body: 'saved',
        mutationId: _mutation,
      ),
    );

    await expectLater(
      mutation,
      throwsA(
        isA<RoutineNoteOutcomeUnknown>()
            .having((error) => error.mutationId, 'mutationId', _mutation)
            .having(
              (error) => error.reason,
              'reason',
              RoutineNoteUncertainty.sessionChanged,
            ),
      ),
    );
    expect(gateway.mutateCalls, 1);
    expect(gateway.reconcileCalls, 0);
  });

  test(
      'ambiguous mutation after account switch is unknown without reconciliation',
      () async {
    var owner = _owner;
    final gateway = _Gateway(
      error: TimeoutException('lost response'),
      onMutate: () {
        owner = _other;
      },
    );
    final repository = SupabaseRoutineNotesRepository(
      gateway: gateway,
      currentUserId: () => owner,
    );

    await expectLater(
      repository.create(
        RoutineNoteCreate(
          id: _note,
          scope: RoutineNoteScope.routine(RoutineId(_routine)),
          body: 'saved',
          mutationId: _mutation,
        ),
      ),
      throwsA(isA<RoutineNoteOutcomeUnknown>().having(
        (error) => error.reason,
        'reason',
        RoutineNoteUncertainty.sessionChanged,
      )),
    );
    expect(gateway.reconcileCalls, 0);
  });

  test('account switch during reconciliation does not return old owner result',
      () async {
    var owner = _owner;
    final reconciliationStarted = Completer<void>();
    final reconciliationResult = Completer<Map<String, dynamic>>();
    final gateway = _Gateway(
      error: TimeoutException('lost response'),
      reconciliationCompleter: reconciliationResult,
      onReconcile: reconciliationStarted.complete,
    );
    final repository = SupabaseRoutineNotesRepository(
      gateway: gateway,
      currentUserId: () => owner,
    );

    final resultFuture = repository.create(
      RoutineNoteCreate(
        id: _note,
        scope: RoutineNoteScope.routine(RoutineId(_routine)),
        body: 'saved',
        mutationId: _mutation,
      ),
    );
    await reconciliationStarted.future;
    owner = _other;
    reconciliationResult.complete(_appliedNote(body: 'old owner result'));

    await expectLater(
      resultFuture,
      throwsA(isA<RoutineNoteOutcomeUnknown>().having(
        (error) => error.reason,
        'reason',
        RoutineNoteUncertainty.sessionChanged,
      )),
    );
    expect(gateway.reconcileCalls, 1);
  });

  test('read rejects a row returned for the wrong owner or scope', () async {
    final mismatchedRow = Map<String, dynamic>.from(
      _appliedNote()['note'] as Map,
    )..['user_id'] = _other;
    final gateway = _Gateway(
      rows: [mismatchedRow],
    );
    final repository = _repository(gateway);

    await expectLater(
      repository.read(RoutineNoteScope.routine(RoutineId(_routine))),
      throwsA(isA<RoutineNoteException>().having(
        (error) => error.kind,
        'kind',
        RoutineNoteFailureKind.malformedData,
      )),
    );
  });

  test('read account switch returns unauthorized without stale data or receipt',
      () async {
    var owner = _owner;
    final gateway = _Gateway(
      rows: [_appliedNote()['note'] as Map<String, dynamic>],
      onRead: () {
        owner = _other;
      },
    );
    final repository = SupabaseRoutineNotesRepository(
      gateway: gateway,
      currentUserId: () => owner,
    );

    await expectLater(
      repository.read(RoutineNoteScope.routine(RoutineId(_routine))),
      throwsA(isA<RoutineNoteException>().having(
        (error) => error.kind,
        'kind',
        RoutineNoteFailureKind.unauthorized,
      )),
    );
    expect(gateway.readCalls, 1);
    expect(gateway.mutateCalls, 0);
    expect(gateway.reconcileCalls, 0);
  });
}

SupabaseRoutineNotesRepository _repository(_Gateway gateway) =>
    SupabaseRoutineNotesRepository(
      gateway: gateway,
      currentUserId: () => _owner,
    );

Map<String, dynamic> _appliedNote({String body = 'saved'}) {
  final note = {
    'id': _note,
    'user_id': _owner,
    'routine_id': _routine,
    'exercise_ref': null,
    'note_type': 'pinned_routine',
    'body': body,
    'created_at': '2026-10-29T10:00:00Z',
    'updated_at': '2026-10-29T10:00:00Z',
    'revision': 0,
    'last_mutation_id': _mutation,
  };
  return {'status': 'applied', 'note': note, 'note_id': _note, 'revision': 0};
}

final class _Gateway implements RoutineNotesGateway {
  _Gateway({
    this.result,
    this.reconciliation,
    this.error,
    this.reconciliationError,
    this.rows = const [],
    this.onRead,
    this.onMutate,
    this.reconciliationCompleter,
    this.onReconcile,
  });

  final Map<String, dynamic>? result;
  final Map<String, dynamic>? reconciliation;
  final Object? error;
  final Object? reconciliationError;
  final List<Map<String, dynamic>> rows;
  final void Function()? onRead;
  final void Function()? onMutate;
  final Completer<Map<String, dynamic>>? reconciliationCompleter;
  final void Function()? onReconcile;
  Map<String, dynamic>? lastParams;
  String? lastReconciledMutationId;
  int readCalls = 0;
  int mutateCalls = 0;
  int reconcileCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> read({
    required String userId,
    required RoutineNoteScope scope,
  }) async {
    readCalls++;
    onRead?.call();
    return rows;
  }

  @override
  Future<Map<String, dynamic>> mutate(Map<String, dynamic> params) async {
    mutateCalls++;
    lastParams = params;
    onMutate?.call();
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<Map<String, dynamic>> reconcile({required String mutationId}) async {
    reconcileCalls++;
    lastReconciledMutationId = mutationId;
    onReconcile?.call();
    if (reconciliationError != null) throw reconciliationError!;
    if (reconciliationCompleter != null) return reconciliationCompleter!.future;
    return reconciliation ?? {'status': 'pending'};
  }
}
