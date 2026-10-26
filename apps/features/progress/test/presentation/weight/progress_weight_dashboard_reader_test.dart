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

  test('no comparable points gives unknown change, not zero', () async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(weight(70, now.subtract(const Duration(days: 3))));
    final snapshot = await ProgressWeightDashboardReader(repo, now: () => now)
        .load(ProgressWeightRange.days30);
    expect(snapshot.rangeChangeKg, isNull);
    expect(snapshot.current?.weightKg, 70);
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
