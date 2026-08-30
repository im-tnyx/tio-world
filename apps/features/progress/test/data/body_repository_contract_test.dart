import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  test('weight provenance values are stable domain semantics', () {
    expect(BodyWeightSources.onboardingSetup, 'onboarding_setup');
    expect(BodyWeightSources.profileSettings, 'profile_settings');
    expect(BodyWeightSources.bodyWeightSettings, 'body_weight_settings');
  });

  test('post-onboarding history command cannot impersonate onboarding retry',
      () async {
    final repository = InMemoryBodySetupRepository();

    await expectLater(
      () => repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 79,
          measuredAt: DateTime.utc(2026, 8, 21, 18),
          source: BodyWeightSources.onboardingSetup,
        ),
      ),
      throwsArgumentError,
    );

    expect(repository.weightEntries, isEmpty);
  });

  test('profile settings provenance records a new post-onboarding history row',
      () async {
    final repository = InMemoryBodySetupRepository(
      now: () => DateTime.utc(2026, 8, 21, 10),
    );

    await repository.saveBodySetup(
      const BodySetupData(currentWeightKg: 80),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 79,
        measuredAt: DateTime.utc(2026, 8, 21, 18),
        source: BodyWeightSources.profileSettings,
      ),
    );

    expect(repository.weightEntries, hasLength(2));
    final state = await repository.getBodyState();
    expect(state.latestWeight?.weightKg, 79);
    expect(state.latestWeight?.source, BodyWeightSources.profileSettings);
  });

  group('setActiveBodyGoal lifecycle', () {
    InMemoryBodySetupRepository buildWithWeight({
      required double weightKg,
      required DateTime measuredAt,
      DateTime Function()? now,
    }) {
      final repository = InMemoryBodySetupRepository(now: now);
      repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: weightKg,
          measuredAt: measuredAt,
          source: BodyWeightSources.profileSettings,
        ),
      );
      return repository;
    }

    test('same active goal type update preserves identity/start/rank',
        () async {
      var now = DateTime.utc(2026, 4, 2, 9);
      final repository = buildWithWeight(
        weightKg: 71,
        measuredAt: DateTime.utc(2026, 4, 1),
        now: () => now,
      );

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 66,
          weeklyWeightChangeKg: 0.5,
        ),
      );
      final firstGoal = (await repository.getBodyState()).activeGoal!;
      expect(firstGoal.startingWeightKg, 71);
      expect(firstGoal.startedAt, now);

      now = DateTime.utc(2026, 5, 1, 9);
      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 65,
          weeklyWeightChangeKg: 0.4,
        ),
      );

      final updated = (await repository.getBodyState()).activeGoal!;
      expect(updated.goalType, BodyGoalType.loseWeight);
      expect(updated.targetWeightKg, 65);
      expect(updated.weeklyWeightChangeKg, 0.4);
      // Preserved exactly, not backfilled from today's later transition time.
      expect(updated.startingWeightKg, 71);
      expect(updated.startedAt, DateTime.utc(2026, 4, 2, 9));
      expect(repository.supersededGoals, isEmpty);
    });

    test('same active Gain update preserves identity/start', () async {
      final repository = buildWithWeight(
        weightKg: 60,
        measuredAt: DateTime.utc(2026, 4, 1),
        now: () => DateTime.utc(2026, 4, 2),
      );

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.gainWeight,
          targetWeightKg: 65,
          weeklyWeightChangeKg: 0.3,
        ),
      );
      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.gainWeight,
          targetWeightKg: 68,
          weeklyWeightChangeKg: 0.5,
        ),
      );

      final goal = (await repository.getBodyState()).activeGoal!;
      expect(goal.goalType, BodyGoalType.gainWeight);
      expect(goal.targetWeightKg, 68);
      expect(goal.startingWeightKg, 60);
      expect(repository.supersededGoals, isEmpty);
    });

    test('same active Maintain update is a no-op churn of null target/pace',
        () async {
      final repository = buildWithWeight(
        weightKg: 70,
        measuredAt: DateTime.utc(2026, 4, 1),
        now: () => DateTime.utc(2026, 4, 2),
      );

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.maintainWeight),
      );
      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.maintainWeight),
      );

      final goal = (await repository.getBodyState()).activeGoal!;
      expect(goal.goalType, BodyGoalType.maintainWeight);
      expect(goal.targetWeightKg, isNull);
      expect(goal.weeklyWeightChangeKg, isNull);
      expect(repository.supersededGoals, isEmpty);
    });

    test('Lose to Gain transition supersedes old and snapshots latest weight',
        () async {
      final repository = InMemoryBodySetupRepository(
        now: () => DateTime.utc(2026, 4, 2),
      );
      await repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 71,
          measuredAt: DateTime.utc(2026, 4, 1),
          source: BodyWeightSources.profileSettings,
        ),
      );
      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 66,
          weeklyWeightChangeKg: 0.5,
        ),
      );

      // A newer canonical weight arrives before the goal changes.
      await repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 69,
          measuredAt: DateTime.utc(2026, 4, 15),
          source: BodyWeightSources.profileSettings,
        ),
      );

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.gainWeight,
          targetWeightKg: 74,
          weeklyWeightChangeKg: 0.3,
        ),
      );

      expect(repository.supersededGoals, hasLength(1));
      expect(repository.supersededGoals.single.goalType, BodyGoalType.loseWeight);

      final active = (await repository.getBodyState()).activeGoal!;
      expect(active.goalType, BodyGoalType.gainWeight);
      expect(active.startingWeightKg, 69); // latest canonical weight, not 71
      expect(active.startedAt, DateTime.utc(2026, 4, 2));
    });

    test('directional to Maintain transition nulls target and pace', () async {
      final repository = buildWithWeight(
        weightKg: 71,
        measuredAt: DateTime.utc(2026, 4, 1),
        now: () => DateTime.utc(2026, 4, 2),
      );
      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 66,
          weeklyWeightChangeKg: 0.5,
        ),
      );

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.maintainWeight),
      );

      final active = (await repository.getBodyState()).activeGoal!;
      expect(active.goalType, BodyGoalType.maintainWeight);
      expect(active.targetWeightKg, isNull);
      expect(active.weeklyWeightChangeKg, isNull);
      expect(repository.supersededGoals, hasLength(1));
    });

    test('legacy Recomposition transitions to an explicit supported goal',
        () async {
      final repository = buildWithWeight(
        weightKg: 71,
        measuredAt: DateTime.utc(2026, 4, 1),
        now: () => DateTime.utc(2026, 4, 2),
      );
      // Simulate a legacy active Recomposition goal from a prior onboarding.
      await repository.saveBodySetup(
        const BodySetupData(
          activeGoal: BodyGoalSetupData(goalType: BodyGoalType.recomposition),
        ),
      );
      expect(
        (await repository.getBodyState()).activeGoal?.goalType,
        BodyGoalType.recomposition,
      );

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 66,
          weeklyWeightChangeKg: 0.5,
        ),
      );

      final active = (await repository.getBodyState()).activeGoal!;
      expect(active.goalType, BodyGoalType.loseWeight);
      expect(active.startingWeightKg, 71);
      expect(repository.supersededGoals.single.goalType, BodyGoalType.recomposition);
    });

    test('explicit Body Goal edit rejects Recomposition as a target value',
        () async {
      final repository = InMemoryBodySetupRepository();
      await expectLater(
        () => repository.setActiveBodyGoal(
          const BodyGoalUpdate(goalType: BodyGoalType.recomposition),
        ),
        throwsArgumentError,
      );
    });

    test('historical null Starting Weight remains null on same-goal update',
        () async {
      final repository = InMemoryBodySetupRepository(
        now: () => DateTime.utc(2026, 4, 2),
      );
      // No weight history at all: a same-goal update must not backfill.
      await repository.saveBodySetup(
        const BodySetupData(
          activeGoal: BodyGoalSetupData(goalType: BodyGoalType.maintainWeight),
        ),
      );
      expect(
        (await repository.getBodyState()).activeGoal?.startingWeightKg,
        isNull,
      );

      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(goalType: BodyGoalType.maintainWeight),
      );

      expect(
        (await repository.getBodyState()).activeGoal?.startingWeightKg,
        isNull,
      );
    });

    test('no canonical Current Weight rejects a new directional goal',
        () async {
      final repository = InMemoryBodySetupRepository();

      await expectLater(
        () => repository.setActiveBodyGoal(
          const BodyGoalUpdate(
            goalType: BodyGoalType.loseWeight,
            targetWeightKg: 66,
            weeklyWeightChangeKg: 0.5,
          ),
        ),
        throwsStateError,
      );
      expect((await repository.getBodyState()).activeGoal, isNull);
    });

    test(
        'retrying the same transition after a prior supersede converges to '
        'exactly one consistent active goal (compensation/self-healing check)',
        () async {
      // Models the real Supabase adapter's non-atomic supersede-then-insert
      // sequence: if the process dies after the old goal is superseded but
      // before the new active row is inserted, the user is left with zero
      // active goals -- never two, and never a corrupted historical row
      // (the superseded row's own fields are untouched). Retrying the exact
      // same setActiveBodyGoal call must then converge to a single correct
      // active goal rather than compounding the inconsistency.
      final repository = buildWithWeight(
        weightKg: 71,
        measuredAt: DateTime.utc(2026, 4, 1),
        now: () => DateTime.utc(2026, 4, 2),
      );
      await repository.setActiveBodyGoal(
        const BodyGoalUpdate(
          goalType: BodyGoalType.loseWeight,
          targetWeightKg: 66,
          weeklyWeightChangeKg: 0.5,
        ),
      );

      const retryUpdate = BodyGoalUpdate(
        goalType: BodyGoalType.gainWeight,
        targetWeightKg: 74,
        weeklyWeightChangeKg: 0.3,
      );
      await repository.setActiveBodyGoal(retryUpdate);
      // Simulated retry of the identical command (e.g. after a transient
      // failure the caller could not distinguish from a lost response).
      await repository.setActiveBodyGoal(retryUpdate);

      final state = await repository.getBodyState();
      expect(state.activeGoal?.goalType, BodyGoalType.gainWeight);
      expect(state.activeGoal?.targetWeightKg, 74);
      // Retrying the same goal type is a same-goal update, not another
      // transition -- no duplicate supersede/history entries.
      expect(repository.supersededGoals, hasLength(1));
    });
  });
}
