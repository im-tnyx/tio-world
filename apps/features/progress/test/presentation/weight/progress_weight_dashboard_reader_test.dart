import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_progress/src/presentation/weight/progress_weight_dashboard_reader.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26, 10);

  BodyWeightRecord weight(double kg, DateTime date) => BodyWeightRecord(
        weightKg: kg,
        measuredAt: date,
        source: BodyWeightSources.manual,
      );

  test('Current Weight excludes future entries while History retains them',
      () async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(weight(72, now.subtract(const Duration(days: 21))));
    await repo.recordCurrentWeight(weight(73, now.subtract(const Duration(days: 4))));
    await repo.recordCurrentWeight(weight(80, now.add(const Duration(days: 2))));

    final result = await ProgressWeightDashboardReader(repo, now: () => now)
        .load(ProgressWeightRange.days30);
    expect(result.current?.weightKg, 73);
    expect(result.chartEntries.map((e) => e.weightKg), [73, 72]);
    expect(result.rangeChangeKg, 1);
    expect(result.history.entries.map((e) => e.weightKg), [80, 73, 72]);
    expect(result.goal, isNull);
  });

  test('target status is a read-model decision, never guessed by the widget',
      () {
    ProgressWeightSnapshot snapshot(BodyGoalState? goal, double? currentKg) =>
        ProgressWeightSnapshot(
          current: currentKg == null
              ? null
              : BodyWeightEntry(weightKg: currentKg, measuredAt: now),
          goal: goal,
          chartEntries: const [],
          history: const BodyWeightHistoryPage(entries: []),
          range: ProgressWeightRange.days30,
          capturedAt: now,
        );

    const loseGoal = BodyGoalState(
      goalType: BodyGoalType.loseWeight,
      startingWeightKg: 74,
      targetWeightKg: 72,
    );
    expect(snapshot(loseGoal, 75).targetProgress?.status,
        ProgressWeightTargetStatus.progress);
    expect(snapshot(loseGoal, 73).targetProgress?.remainingKg, 1);
    expect(snapshot(loseGoal, 73).targetProgress?.status,
        ProgressWeightTargetStatus.onTrack);
    expect(snapshot(loseGoal, 72).targetProgress?.remainingKg, 0);
    expect(snapshot(loseGoal, 72).targetProgress?.status,
        ProgressWeightTargetStatus.reached);
    expect(snapshot(loseGoal, 71.5).targetProgress?.remainingKg, 0.5);
    expect(snapshot(loseGoal, 71.5).targetProgress?.status,
        ProgressWeightTargetStatus.belowTarget);
    expect(snapshot(loseGoal, 71).targetProgress?.remainingKg, 1);
    expect(snapshot(loseGoal, 71).targetProgress?.status,
        ProgressWeightTargetStatus.belowTarget);
    expect(snapshot(loseGoal, null).targetProgress?.remainingKg, isNull);
    expect(snapshot(loseGoal, null).targetProgress?.status,
        ProgressWeightTargetStatus.progress);

    const gainGoal = BodyGoalState(
      goalType: BodyGoalType.gainWeight,
      startingWeightKg: 70,
      targetWeightKg: 75,
    );
    expect(snapshot(gainGoal, 74).targetProgress?.remainingKg, 1);
    expect(snapshot(gainGoal, 74).targetProgress?.status,
        ProgressWeightTargetStatus.onTrack);
    expect(snapshot(gainGoal, 75).targetProgress?.status,
        ProgressWeightTargetStatus.reached);
    expect(snapshot(gainGoal, 76).targetProgress?.remainingKg, 1);
    expect(snapshot(gainGoal, 76).targetProgress?.status,
        ProgressWeightTargetStatus.aboveTarget);
    // A maintain target is not a direction and must not show a
    // directional overshoot even if historical goal data contains a target.
    expect(
        snapshot(
            const BodyGoalState(
              goalType: BodyGoalType.maintainWeight,
              targetWeightKg: 70,
            ),
            69).targetProgress?.status,
        ProgressWeightTargetStatus.progress);
    expect(snapshot(null, 73).targetProgress, isNull);
    expect(
        snapshot(const BodyGoalState(goalType: BodyGoalType.maintainWeight), 73)
            .targetProgress,
        isNull);
  });

  test('no comparable points gives unknown change, not zero', () async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(weight(70, now.subtract(const Duration(days: 3))));
    final snapshot = await ProgressWeightDashboardReader(repo, now: () => now)
        .load(ProgressWeightRange.days30);
    expect(snapshot.rangeChangeKg, isNull);
    expect(snapshot.current?.weightKg, 70);
  });

  test('same-day deltas do not extrapolate into weekly pace', () async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(
        weight(72, now.subtract(const Duration(hours: 5))));
    await repo.recordCurrentWeight(
        weight(76, now.subtract(const Duration(hours: 1))));
    final snapshot = await ProgressWeightDashboardReader(repo, now: () => now)
        .load(ProgressWeightRange.days30);
    expect(snapshot.rangeChangeKg, 4);
    expect(snapshot.weeklyRateOfChangeKg, isNull);
  });

  test('weekly rate uses real elapsed instants, not selected range length',
      () async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(
      weight(74, now.subtract(const Duration(days: 20))),
    );
    await repo.recordCurrentWeight(
      weight(75, now.subtract(const Duration(days: 6))),
    );
    final snapshot =
        await ProgressWeightDashboardReader(repo, now: () => now)
            .load(ProgressWeightRange.days30);
    expect(snapshot.rangeChangeKg, 1);
    expect(snapshot.weeklyRateOfChangeKg, closeTo(0.5, 0.000001));
  });

  test('same-time or single record cannot produce a weekly rate', () async {
    final repo = InMemoryBodySetupRepository();
    final stamp = now.subtract(const Duration(days: 3));
    await repo.recordCurrentWeight(weight(70, stamp));
    var snapshot = await ProgressWeightDashboardReader(repo, now: () => now)
        .load(ProgressWeightRange.days30);
    expect(snapshot.weeklyRateOfChangeKg, isNull);
    await repo.recordCurrentWeight(weight(71, stamp));
    snapshot = await ProgressWeightDashboardReader(repo, now: () => now)
        .load(ProgressWeightRange.days30);
    expect(snapshot.weeklyRateOfChangeKg, isNull);
  });

  test('same-instant records survive and History pages by stable ID',
      () async {
    final repo = InMemoryBodySetupRepository();
    final measuredAt = now.subtract(const Duration(days: 2));
    for (var i = 0; i < 35; i++) {
      await repo.recordCurrentWeight(weight(70 + i / 10, measuredAt));
    }
    final reader = ProgressWeightDashboardReader(repo, now: () => now);
    final first = await reader.load(ProgressWeightRange.days30);
    expect(first.chartEntries.length, 35);
    expect(first.rangeChangeKg, isNull); // Same instant is not a time trend.
    expect(first.current?.weightKg, 73.4);
    expect(first.history.entries.length, 30);
    final cursor = first.history.nextCursor;
    expect(cursor, isNotNull);
    final more = await reader.loadMore(cursor!);
    final whole = first.appendHistory(more);
    expect(whole.history.entries.length, 35);
    expect(whole.history.nextCursor, isNull);
    expect(
      whole.history.entries.map((e) => e.id).toSet().length,
      35,
    );
  });
}
