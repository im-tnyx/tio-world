import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_progress/progress.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _other = '22222222-2222-4222-8222-222222222222';
const _measurement = '33333333-3333-4333-8333-333333333333';

User _user(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.utc(2026, 10, 25).toIso8601String(),
    );

BodyWeightHistoryQuery _range() => BodyWeightHistoryQuery(
      fromInclusive: DateTime.utc(2026, 10, 25),
      toExclusive: DateTime.utc(2026, 10, 26),
    );

BodyWeightLogEdit _edit() => BodyWeightLogEdit(
      id: _measurement,
      weightKg: 73.5,
      measuredAt: DateTime.utc(2026, 10, 25, 9),
    );

final class _MutableBodyAuth extends Fake implements GoTrueClient {
  _MutableBodyAuth(this.user);
  User? user;

  @override
  User? get currentUser => user;
}

final class _SessionClient extends Fake implements SupabaseClient {
  _SessionClient(String? owner) : authState = _MutableBodyAuth(
    owner == null ? null : _user(owner),
  );
  final _MutableBodyAuth authState;

  @override
  GoTrueClient get auth => authState;

  @override
  SupabaseQueryBuilder from(String table) =>
      throw StateError('Unexpected database call; use injected transport.');
}

final class _DeferredBodyTransport implements BodyWeightLogTransport {
  final history = Completer<List<Map<String, dynamic>>>();
  final updated = Completer<bool>();
  final deleted = Completer<bool>();

  int historyCalls = 0;
  int editCalls = 0;
  int deleteCalls = 0;
  String? ownerForHistory;
  String? ownerForEdit;
  String? ownerForDelete;

  @override
  Future<List<Map<String, dynamic>>> list({
    required String userId,
    required BodyWeightHistoryQuery query,
  }) {
    historyCalls++;
    ownerForHistory = userId;
    return history.future;
  }

  @override
  Future<bool> update({
    required String userId,
    required BodyWeightLogEdit edit,
  }) {
    editCalls++;
    ownerForEdit = userId;
    return updated.future;
  }

  @override
  Future<bool> delete({
    required String userId,
    required String id,
  }) {
    deleteCalls++;
    ownerForDelete = userId;
    return deleted.future;
  }
}

List<Map<String, dynamic>> _historyRows() => <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _measurement,
        'weight_kg': 73.5,
        'measured_at': '2026-10-25T09:00:00.000Z',
        'source': 'manual',
      },
    ];

void main() {
  test('History rejects old C1 response after same-owner re-login to C2',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    var liveCycle = 'C1';
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => liveCycle,
      weightLogTransport: transport,
    );

    final pending = repo.getWeightHistory(_range());
    expect(transport.historyCalls, 1);
    expect(transport.ownerForHistory, _owner);
    liveCycle = 'C2';
    transport.history.complete(_historyRows());
    await expectLater(pending, throwsStateError);
  });

  test('Edit rejects successful old-C1 completion after same-owner re-login',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    var liveCycle = 'C1';
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => liveCycle,
      weightLogTransport: transport,
    );

    final pending = repo.updateWeightLog(_edit());
    expect(transport.editCalls, 1);
    expect(transport.ownerForEdit, _owner);
    liveCycle = 'C2';
    transport.updated.complete(true); // Server-side write may already commit.
    await expectLater(pending, throwsStateError);
    // A client response guard is not a transaction rollback/cancellation.
  });

  test('Delete rejects successful old-C1 completion after same-owner re-login',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    var liveCycle = 'C1';
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => liveCycle,
      weightLogTransport: transport,
    );

    final pending = repo.deleteWeightLog(_measurement);
    expect(transport.deleteCalls, 1);
    expect(transport.ownerForDelete, _owner);
    liveCycle = 'C2';
    transport.deleted.complete(true); // Cannot undo network-dispatched DELETE.
    await expectLater(pending, throwsStateError);
  });

  test('A to B to A rotation cannot resurrect the old History response',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    var liveCycle = 'C1';
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => liveCycle,
      weightLogTransport: transport,
    );

    final pending = repo.getWeightHistory(_range());
    expect(transport.historyCalls, 1);
    client.authState.user = _user(_other);
    liveCycle = 'B1';
    client.authState.user = _user(_owner);
    liveCycle = 'C2';
    transport.history.complete(_historyRows());
    await expectLater(pending, throwsStateError);
  });

  test('different-owner session switch rejects old Edit completion',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    var liveCycle = 'C1';
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => liveCycle,
      weightLogTransport: transport,
    );

    final pending = repo.updateWeightLog(_edit());
    expect(transport.editCalls, 1);
    client.authState.user = _user(_other);
    liveCycle = 'B1';
    transport.updated.complete(true);
    await expectLater(pending, throwsStateError);
  });

  test('stale repo fails before sending another History/Edit/Delete request',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    var liveCycle = 'C2';
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => liveCycle,
      weightLogTransport: transport,
    );
    await expectLater(() => repo.getWeightHistory(_range()), throwsStateError);
    await expectLater(() => repo.updateWeightLog(_edit()), throwsStateError);
    await expectLater(
      () => repo.deleteWeightLog(_measurement),
      throwsStateError,
    );
    expect(transport.historyCalls, 0);
    expect(transport.editCalls, 0);
    expect(transport.deleteCalls, 0);

    liveCycle = 'C1';
    client.authState.user = null;
    await expectLater(
      repo.getWeightHistory(_range()),
      completion(isA<BodyWeightHistoryPage>()),
    );
    await expectLater(() => repo.updateWeightLog(_edit()), throwsStateError);
  });

  test('missing cycle source fails closed for signed-in A1 calls', () async {
    final transport = _DeferredBodyTransport();
    final repo = SupabaseBodySetupRepository(
      client: _SessionClient(_owner),
      weightLogTransport: transport,
    );
    await expectLater(() => repo.getWeightHistory(_range()), throwsStateError);
    await expectLater(() => repo.updateWeightLog(_edit()), throwsStateError);
    await expectLater(() => repo.deleteWeightLog(_measurement),
        throwsStateError);
    expect(transport.historyCalls + transport.editCalls +
        transport.deleteCalls, 0);
  });

  test('unchanged owner and C1 returns actual History and write results',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => 'C1',
      weightLogTransport: transport,
    );
    final history = repo.getWeightHistory(_range());
    transport.history.complete(_historyRows());
    final page = await history;
    expect(page.entries.single.id, _measurement);

    final update = repo.updateWeightLog(_edit());
    transport.updated.complete(false);
    expect(await update, isFalse);

    final delete = repo.deleteWeightLog(_measurement);
    transport.deleted.complete(true);
    expect(await delete, isTrue);
  });

  test('auth became null before response: old result is never published',
      () async {
    final client = _SessionClient(_owner);
    final transport = _DeferredBodyTransport();
    var liveCycle = 'C1';
    final repo = SupabaseBodySetupRepository(
      client: client,
      weightLoginCycleId: 'C1',
      currentWeightLoginCycleId: () => liveCycle,
      weightLogTransport: transport,
    );
    final pending = repo.getWeightHistory(_range());
    client.authState.user = null;
    liveCycle = '';
    transport.history.complete(_historyRows());
    await expectLater(pending, throwsStateError);
  });
}
