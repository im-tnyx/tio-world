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

  test('in-memory fallback preserves the exact canonical setup data', () async {
    final repository = InMemoryBodySetupRepository();
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
    throw StateError('Database access was not expected for validation test: $table');
  }
}

class _AuthOnlyGoTrueClient extends Fake implements GoTrueClient {
  _AuthOnlyGoTrueClient(this.currentUser);

  @override
  final User? currentUser;
}
