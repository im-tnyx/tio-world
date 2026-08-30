import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  final fakeUser = User(
    id: 'usr-body-1',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2026, 8, 21).toIso8601String(),
  );

  test('storage values match canonical Supabase Body Goal contract', () {
    expect(BodyGoalType.loseWeight.storageValue, 'lose_weight');
    expect(BodyGoalType.gainWeight.storageValue, 'gain_weight');
    expect(BodyGoalType.maintainWeight.storageValue, 'maintain_weight');
    expect(BodyGoalType.recomposition.storageValue, 'recomposition');
  });

  test('saveBodySetup requires authenticated user', () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: null),
    );

    await expectLater(
      () => repository.saveBodySetup(const BodySetupData()),
      throwsStateError,
    );
  });

  test('signed-out canonical Body read returns unknown without database access',
      () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: null),
    );

    final state = await repository.getBodyState();
    expect(state.latestWeight, isNull);
    expect(state.activeGoal, isNull);
  });

  test('recordCurrentWeight requires authenticated user', () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: null),
    );

    await expectLater(
      () => repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 79,
          measuredAt: DateTime.utc(2026, 8, 21, 16),
          source: 'profile_settings',
        ),
      ),
      throwsStateError,
    );
  });

  test('rejects non-positive current weight before database access', () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.saveBodySetup(
        const BodySetupData(currentWeightKg: 0),
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid Body intent rank before database access', () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.saveBodySetup(
        const BodySetupData(
          activeGoal: BodyGoalSetupData(
            goalType: BodyGoalType.loseWeight,
            intentRank: 3,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects negative Goal Pace before database access', () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.saveBodySetup(
        const BodySetupData(
          activeGoal: BodyGoalSetupData(
            goalType: BodyGoalType.gainWeight,
            weeklyWeightChangeKg: -0.1,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('Maintain cannot carry Target Weight or Goal Pace', () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.saveBodySetup(
        const BodySetupData(
          activeGoal: BodyGoalSetupData(
            goalType: BodyGoalType.maintainWeight,
            targetWeightKg: 70,
            weeklyWeightChangeKg: 0.5,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('recordCurrentWeight rejects invalid payload before database access',
      () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 0,
          measuredAt: DateTime.utc(2026, 8, 21, 16),
          source: 'profile_settings',
        ),
      ),
      throwsArgumentError,
    );

    await expectLater(
      () => repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 79,
          measuredAt: DateTime.utc(2026, 8, 21, 16),
          source: '   ',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('setActiveBodyGoal requires authenticated user', () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: null),
    );

    await expectLater(
      () => repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.maintainWeight),
      ),
      throwsStateError,
    );
  });

  test('setActiveBodyGoal rejects Recomposition before database access',
      () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.recomposition),
      ),
      throwsArgumentError,
    );
  });

  test(
      'setActiveBodyGoal rejects Maintain carrying Target/Pace before database access',
      () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.maintainWeight,
          targetWeightKg: 70,
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
      'setActiveBodyGoal rejects a directional goal missing Target/Pace before database access',
      () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.loseWeight),
      ),
      throwsArgumentError,
    );
  });

  test(
      'setActiveBodyGoal rejects non-positive Target Weight before database access',
      () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 0,
          weeklyWeightChangeKg: 0.5,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('setActiveBodyGoal rejects negative Goal Pace before database access',
      () async {
    final repository = SupabaseBodySetupRepository(
      client: _AuthOnlySupabaseClient(currentUser: fakeUser),
    );

    await expectLater(
      () => repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.gainWeight,
          targetWeightKg: 74,
          weeklyWeightChangeKg: -0.1,
        ),
      ),
      throwsArgumentError,
    );
  });

  group('setActiveBodyGoal RPC cutover (TNYX-136)', () {
    test(
        'calls the atomic RPC with exact canonical params, not direct table access',
        () async {
      final client = _RpcCapturingSupabaseClient(currentUser: fakeUser);
      final repository = SupabaseBodySetupRepository(client: client);

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 65,
          weeklyWeightChangeKg: 0.5,
        ),
      );

      expect(client.capturedFunction, 'set_active_body_goal');
      expect(client.capturedParams, {
        'p_goal_type': 'lose_weight',
        'p_target_weight_kg': 65.0,
        'p_weekly_weight_change_kg': 0.5,
      });
      // _RpcCapturingSupabaseClient.from() throws if ever called; reaching
      // this point with no exception proves setActiveBodyGoal issued no
      // direct table update/insert -- neither a same-goal update, nor an
      // old-goal supersede, nor a new-goal insert remain in this method.
    });

    test('Maintain sends null target and pace to the RPC', () async {
      final client = _RpcCapturingSupabaseClient(currentUser: fakeUser);
      final repository = SupabaseBodySetupRepository(client: client);

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.maintainWeight),
      );

      expect(client.capturedFunction, 'set_active_body_goal');
      expect(client.capturedParams, {
        'p_goal_type': 'maintain_weight',
        'p_target_weight_kg': null,
        'p_weekly_weight_change_kg': null,
      });
    });

    test('RPC failure surfaces as failure without any compensation write',
        () async {
      final client = _RpcCapturingSupabaseClient(
        currentUser: fakeUser,
        rpcError: const PostgrestException(
          message: 'target_weight_must_be_below_current_for_lose',
          code: 'P0001',
        ),
      );
      final repository = SupabaseBodySetupRepository(client: client);

      await expectLater(
        () => repository.setActiveBodyGoal(
          const BodyGoalUpdate(
            goalType: BodyGoalType.loseWeight,
            targetWeightKg: 90,
            weeklyWeightChangeKg: 0.5,
          ),
        ),
        throwsA(isA<PostgrestException>()),
      );

      // The fake's from() throws unconditionally, so if the repository had
      // attempted any compensating table write after the RPC failure, this
      // test would fail with a different exception type than the RPC's own.
      expect(client.capturedFunction, 'set_active_body_goal');
    });
  });

  test('in-memory setup exposes canonical Body state without defaults',
      () async {
    var now = DateTime.utc(2026, 8, 21, 10);
    final repository = InMemoryBodySetupRepository(now: () => now);

    final initialState = await repository.getBodyState();
    expect(initialState.latestWeight, isNull);
    expect(initialState.activeGoal, isNull);

    const data = BodySetupData(
      currentWeightKg: 80,
      activeGoal: BodyGoalSetupData(
        goalType: BodyGoalType.loseWeight,
        targetWeightKg: 76,
        weeklyWeightChangeKg: 0.4,
        intentRank: 1,
      ),
    );

    await repository.saveBodySetup(data);
    expect(identical(repository.data, data), isTrue);

    final state = await repository.getBodyState();
    expect(state.latestWeight?.weightKg, 80);
    expect(state.latestWeight?.measuredAt, now);
    expect(state.latestWeight?.source, 'onboarding_setup');
    expect(state.activeGoal?.goalType, BodyGoalType.loseWeight);
    expect(state.activeGoal?.startingWeightKg, 80);
    expect(state.activeGoal?.targetWeightKg, 76);
    expect(state.activeGoal?.weeklyWeightChangeKg, 0.4);
    expect(state.activeGoal?.intentRank, 1);
  });

  test('in-memory onboarding retry updates one setup snapshot', () async {
    var now = DateTime.utc(2026, 8, 21, 10);
    final repository = InMemoryBodySetupRepository(now: () => now);

    await repository.saveBodySetup(
      const BodySetupData(currentWeightKg: 80),
    );
    now = DateTime.utc(2026, 8, 21, 10, 30);
    await repository.saveBodySetup(
      const BodySetupData(currentWeightKg: 79.5),
    );

    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.weightKg, 79.5);
    expect(repository.weightEntries.single.measuredAt, now);
    expect(repository.weightEntries.single.source, 'onboarding_setup');
  });

  test(
      'post-onboarding weight command appends history and latest timestamp wins',
      () async {
    final repository = InMemoryBodySetupRepository(
      now: () => DateTime.utc(2026, 8, 21, 10),
    );

    await repository.saveBodySetup(
      const BodySetupData(currentWeightKg: 80),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 79.2,
        measuredAt: DateTime.utc(2026, 8, 21, 18),
        source: 'profile_settings',
      ),
    );

    expect(repository.weightEntries, hasLength(2));
    final state = await repository.getBodyState();
    expect(state.latestWeight?.weightKg, 79.2);
    expect(state.latestWeight?.source, 'profile_settings');
    expect(
      state.latestWeight?.measuredAt,
      DateTime.utc(2026, 8, 21, 18),
    );
  });
}

class _AuthOnlySupabaseClient extends Fake implements SupabaseClient {
  _AuthOnlySupabaseClient({required User? currentUser})
      : _auth = _AuthOnlyGoTrueClient(currentUser);

  final _AuthOnlyGoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    throw StateError(
        'Database access was not expected for validation test: $table');
  }
}

class _AuthOnlyGoTrueClient extends Fake implements GoTrueClient {
  _AuthOnlyGoTrueClient(this.currentUser);

  @override
  final User? currentUser;
}

/// Captures the exact function/params passed to `.rpc(...)` and, like
/// [_AuthOnlySupabaseClient], throws on any direct `.from(table)` access --
/// proving setActiveBodyGoal's TNYX-136 cutover issues one RPC call and no
/// direct table read/write.
class _RpcCapturingSupabaseClient extends Fake implements SupabaseClient {
  _RpcCapturingSupabaseClient({required User? currentUser, this.rpcError})
      : _auth = _AuthOnlyGoTrueClient(currentUser);

  final _AuthOnlyGoTrueClient _auth;
  final Object? rpcError;
  String? capturedFunction;
  Map<String, dynamic>? capturedParams;

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    throw StateError(
      'Direct table access was not expected: $table. '
      'setActiveBodyGoal must persist through the set_active_body_goal RPC only.',
    );
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    dynamic get = false,
  }) {
    capturedFunction = fn;
    capturedParams = params;
    return _FakeRpcCall<T>(error: rpcError);
  }
}

/// A minimal fake of the awaitable value `SupabaseClient.rpc(...)` returns.
/// `PostgrestFilterBuilder<T>` (via `PostgrestBuilder<T, S, R>`) implements
/// `Future<T>` by resolving through `then(...)`, so overriding just `then`
/// is sufficient to make `await client.rpc(...)` behave like a real
/// success/failure response without needing a live HTTP layer.
class _FakeRpcCall<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeRpcCall({this.error});
  final Object? error;

  @override
  Future<U> then<U>(FutureOr<U> Function(T value) onValue,
      {Function? onError}) {
    if (error != null) {
      return Future<T>.error(error!).then(onValue, onError: onError);
    }
    return Future<T>.value(null).then(onValue, onError: onError);
  }
}
