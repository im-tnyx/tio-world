import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_progress/src/presentation/weight/progress_weight_timeline_projection.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26, 10);
  BodyWeightEntry row(String id, double kg, DateTime instant) =>
      BodyWeightEntry(id: id, weightKg: kg, measuredAt: instant);

  test('strictly older real entry drives signed delta; no phantom zero', () {
    final rows = [
      row('a', 73, now.subtract(const Duration(days: 1))),
      row('b', 74, now.subtract(const Duration(days: 5))),
      row('c', 74, now.subtract(const Duration(days: 5))),
      row('d', 74, now.subtract(const Duration(days: 10))),
    ];
    final items = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(items[0].deltaKg, -1);
    expect(items[1].deltaKg, 0); // Compare to strictly older timestamp.
    expect(items[2].deltaKg, 0);
    expect(items[3].deltaKg, isNull); // No earlier record available.
    expect(items[0].isNewLow, isTrue);
    expect(items[1].isNewLow, isFalse);
  });

  test('incomplete paginated history cannot claim an all-time new low', () {
    final rows = [
      row('a', 72, now.subtract(const Duration(days: 1))),
      row('b', 74, now.subtract(const Duration(days: 4))),
    ];
    final pending = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: true, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(pending[0].isNewLow, isFalse);
    expect(pending[0].deltaKg, -2);
    final complete = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(complete[0].isNewLow, isTrue);
  });

  test('same-instant siblings cannot both claim a strict new low', () {
    final stamp = now.subtract(const Duration(days: 1));
    final rows = [
      row('a', 73.2, stamp),
      row('b', 73, stamp),
      row('c', 74, now.subtract(const Duration(days: 2))),
    ];
    final items = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(items[0].deltaKg, closeTo(-0.8, 0.001));
    expect(items[0].isNewLow, isFalse);
    expect(items[1].isNewLow, isFalse);
    expect(items[1].deltaKg, -1);
  });

  test('tied same-instant minima cannot claim a strict new low', () {
    final stamp = now.subtract(const Duration(days: 1));
    final rows = [
      row('a', 73, stamp),
      row('b', 73, stamp),
      row('older', 74, now.subtract(const Duration(days: 2))),
    ];
    final items = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(items[0].deltaKg, -1);
    expect(items[1].deltaKg, -1);
    expect(items[0].isNewLow, isFalse);
    expect(items[1].isNewLow, isFalse);
  });

  test('large grouped History preserves order, low and future semantics', () {
    // 6,000 timestamp groups and same-instant siblings guard the linear
    // projection path used after repeated History pagination.
    const groupCount = 6000;
    final rows = <BodyWeightEntry>[
      row('future', 1, now.add(const Duration(minutes: 1))),
      for (var i = 0; i < groupCount; i++) ...[
        row('first-$i', 70 + i * 0.01,
            now.subtract(Duration(minutes: i + 1))),
        row('sibling-$i', 70.1 + i * 0.01,
            now.subtract(Duration(minutes: i + 1))),
      ],
    ];
    final items = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(items, hasLength(1 + groupCount * 2));
    expect(items.first.entry.id, 'future');
    expect(items.first.deltaKg, isNull);
    expect(items.first.isNewLow, isFalse);
    expect(items[1].entry.id, 'first-0');
    expect(items[1].deltaKg, closeTo(-0.01, 0.000001));
    expect(items[1].isNewLow, isTrue);
    expect(items[2].entry.id, 'sibling-0');
    expect(items[2].deltaKg, closeTo(0.09, 0.000001));
    expect(items[2].isNewLow, isFalse);
    expect(items.last.deltaKg, isNull);
    expect(items.last.isNewLow, isFalse);

    final pending = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: true, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(pending, hasLength(items.length));
    expect(pending[1].isNewLow, isFalse);
    expect(pending[1].deltaKg, closeTo(-0.01, 0.000001));
  });

  test('only latest eligible row gets a goal-directed record badge', () {
    final rows = [
      row('latest', 76, now.subtract(const Duration(hours: 1))),
      row('older-low', 72, now.subtract(const Duration(hours: 2))),
      row('oldest', 74, now.subtract(const Duration(days: 3))),
    ];
    final lose = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now,
      goalType: BodyGoalType.loseWeight,
    );
    expect(lose.where((r) => r.isNewLow), isEmpty);
    final gain = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now,
      goalType: BodyGoalType.gainWeight,
    );
    expect(gain.where((r) => r.isNewHigh).map((r) => r.entry.id), ['latest']);
    final noGoal = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now,
    );
    expect(noGoal.any((r) => r.isNewLow || r.isNewHigh), isFalse);
  });

  test('only latest eligible measurement gets highlighted, not entire day',
      () {
    final rows = [
      row('future', 70, now.add(const Duration(minutes: 5))),
      row('latest', 73, now.subtract(const Duration(minutes: 10))),
      row('earlier-today', 74, now.subtract(const Duration(hours: 1))),
      row('earlier-this-month', 75, now.subtract(const Duration(days: 2))),
    ];
    final items = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now,
    );
    expect(items.map((item) => item.isLatestEligible).toList(),
        [false, true, false, false]);
    expect(items[1].isToday, isTrue);
    expect(items[2].isToday, isTrue);
    expect(items[0].isToday, isFalse);
  });

  test('Today cannot be inferred for a future-dated measurement', () {
    final rows = [
      row('future', 68, now.add(const Duration(minutes: 5))),
      row('current', 70, now.subtract(const Duration(minutes: 5))),
    ];
    final result = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now, goalType: BodyGoalType.loseWeight,
    );
    expect(result[0].isToday, isFalse);
    expect(result[0].deltaKg, isNull);
    expect(result[0].isNewLow, isFalse);
    expect(result[1].isToday, isTrue);
  });
}
