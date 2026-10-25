import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  final start = DateTime.utc(2026, 10, 25);
  final end = DateTime.utc(2026, 10, 26);
  BodyWeightHistoryQuery query({
    int limit = 30,
    BodyWeightHistoryCursor? before,
    DateTime? from,
    DateTime? to,
  }) =>
      BodyWeightHistoryQuery(
        fromInclusive: from ?? start,
        toExclusive: to ?? end,
        limit: limit,
        before: before,
      );

  BodyWeightRecord record(double kg, DateTime at, {String source = 'manual'}) =>
      BodyWeightRecord(weightKg: kg, measuredAt: at, source: source);

  test('empty history is honest and has no fabricated cursor', () async {
    final repo = InMemoryBodySetupRepository();
    final result = await repo.getWeightHistory(query());
    expect(result.entries, isEmpty);
    expect(result.nextCursor, isNull);
    expect((await repo.getBodyState()).latestWeight, isNull);
  });

  test('same-day and identical-instant rows have distinct ordered IDs', () async {
    final repo = InMemoryBodySetupRepository();
    final at = DateTime.utc(2026, 10, 25, 9);
    await repo.recordCurrentWeight(record(80, at));
    await repo.recordCurrentWeight(record(79.5, at));
    await repo.recordCurrentWeight(record(79, at.subtract(const Duration(hours: 1))));
    final first = await repo.getWeightHistory(query(limit: 1));
    expect(first.entries, hasLength(1));
    expect(first.entries.single.weightKg, 79.5);
    expect(first.nextCursor?.id, first.entries.single.id);

    final second = await repo.getWeightHistory(
      query(limit: 1, before: first.nextCursor),
    );
    expect(second.entries.single.weightKg, 80);
    expect(second.entries.single.id, isNot(first.entries.single.id));
    expect(second.nextCursor, isNotNull);

    final third = await repo.getWeightHistory(
      query(limit: 1, before: second.nextCursor),
    );
    expect(third.entries.single.weightKg, 79);
    expect(third.nextCursor, isNull);
    expect(
      {
        first.entries.single.id,
        second.entries.single.id,
        third.entries.single.id,
      },
      hasLength(3),
    );
    expect(() => first.entries.clear(), throwsUnsupportedError);
  });

  test('history range is inclusive start, exclusive end, with absolute instants',
      () async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(record(70, DateTime.utc(2026, 10, 25, 2, 30)));
    await repo.recordCurrentWeight(record(71, DateTime.utc(2026, 10, 26)));
    await repo.recordCurrentWeight(record(69, DateTime.utc(2026, 10, 25)));
    final localBoundary = DateTime.parse('2026-10-25T08:00:00+05:30');
    final page = await repo.getWeightHistory(query(from: localBoundary));
    expect(page.entries.map((e) => e.weightKg).toList(), [70]);
    expect(page.entries.single.measuredAt, localBoundary.toUtc());
  });

  test('edit preserves exact ID/source and reorders history and latest state',
      () async {
    final now = DateTime.utc(2026, 10, 24, 8);
    final repo = InMemoryBodySetupRepository(now: () => now);
    await repo.saveBodySetup(const BodySetupData(currentWeightKg: 80));
    await repo.setActiveBodyGoal(
      const BodyGoalUpdate(
        goalType: BodyGoalType.loseWeight,
        targetWeightKg: 75,
        weeklyWeightChangeKg: 0.5,
      ),
    );
    await repo.recordCurrentWeight(
      record(79, DateTime.utc(2026, 10, 25, 9), source: 'profile_settings'),
    );
    final original = (await repo.getWeightHistory(query())).entries.single;
    final changed = await repo.updateWeightLog(
      BodyWeightLogEdit(
        id: original.id!,
        weightKg: 77,
        measuredAt: DateTime.utc(2026, 10, 25, 10),
      ),
    );
    expect(changed, isTrue);
    final after = (await repo.getWeightHistory(query())).entries.single;
    expect(after.id, original.id);
    expect(after.source, 'profile_settings');
    expect(after.weightKg, 77);
    expect(after.measuredAt, DateTime.utc(2026, 10, 25, 10));
    final state = await repo.getBodyState();
    expect(state.latestWeight?.weightKg, 77);
    expect(state.activeGoal?.startingWeightKg, 80);
    expect(await repo.deleteWeightLog(original.id!), isTrue);
    expect(await repo.deleteWeightLog(original.id!), isFalse);
    expect((await repo.getWeightHistory(query())).entries, isEmpty);
    final restored = await repo.getBodyState();
    expect(restored.latestWeight?.weightKg, 80);
    expect(restored.activeGoal?.startingWeightKg, 80);
  });

  test('edit/delete affect exactly one of two same-timestamp records', () async {
    final repo = InMemoryBodySetupRepository();
    final at = DateTime.utc(2026, 10, 25, 18);
    await repo.recordCurrentWeight(record(80, at));
    await repo.recordCurrentWeight(record(81, at));
    final before = (await repo.getWeightHistory(query())).entries;
    expect(before, hasLength(2));
    expect(await repo.deleteWeightLog(before.first.id!), isTrue);
    final after = (await repo.getWeightHistory(query())).entries;
    expect(after.single.id, before.last.id);
    expect(after.single.weightKg, before.last.weightKg);
  });

  test('onboarding reconciliation retains original row ID', () async {
    var now = DateTime.utc(2026, 10, 25, 8);
    final repo = InMemoryBodySetupRepository(now: () => now);
    await repo.saveBodySetup(const BodySetupData(currentWeightKg: 80));
    final first = (await repo.getWeightHistory(query())).entries.single;
    now = now.add(const Duration(minutes: 5));
    await repo.saveBodySetup(const BodySetupData(currentWeightKg: 79));
    final second = (await repo.getWeightHistory(query())).entries.single;
    expect(second.id, first.id);
    expect(second.weightKg, 79);
    expect(second.source, BodyWeightSources.onboardingSetup);
  });

  test('invalid ranges, cursors, IDs and weights reject before mutation',
      () async {
    final repo = InMemoryBodySetupRepository();
    expect(
      () => repo.getWeightHistory(query(from: end, to: start)),
      throwsArgumentError,
    );
    expect(() => repo.getWeightHistory(query(limit: 0)), throwsArgumentError);
    expect(() => repo.getWeightHistory(query(limit: 101)), throwsArgumentError);
    expect(
      () => repo.getWeightHistory(
        query(before: BodyWeightHistoryCursor(measuredAt: end, id: 'bad')),
      ),
      throwsArgumentError,
    );
    await expectLater(() => repo.deleteWeightLog('1'), throwsArgumentError);
    await expectLater(
      () => repo.updateWeightLog(
        BodyWeightLogEdit(
          id: 'bad',
          weightKg: 70,
          measuredAt: start,
        ),
      ),
      throwsArgumentError,
    );
    for (final badWeight in <double>[0, -1, double.nan, double.infinity]) {
      await expectLater(
        () => repo.updateWeightLog(
          BodyWeightLogEdit(
            id: '00000000-0000-4000-8000-000000000001',
            weightKg: badWeight,
            measuredAt: start,
          ),
        ),
        throwsArgumentError,
      );
    }
    expect(
      await repo.deleteWeightLog('00000000-0000-4000-8000-999999999999'),
      isFalse,
    );
    expect(
      await repo.updateWeightLog(
        BodyWeightLogEdit(
          id: '00000000-0000-4000-8000-999999999999',
          weightKg: 70,
          measuredAt: start,
        ),
      ),
      isFalse,
    );
    expect(repo.weightEntries, isEmpty);
  });
}
