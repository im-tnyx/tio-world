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
      entries: rows, hasMore: false, capturedAt: now,
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
      entries: rows, hasMore: true, capturedAt: now,
    );
    expect(pending[0].isNewLow, isFalse);
    expect(pending[0].deltaKg, -2);
    final complete = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now,
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
      entries: rows, hasMore: false, capturedAt: now,
    );
    expect(items[0].deltaKg, closeTo(-0.8, 0.001));
    expect(items[0].isNewLow, isFalse);
    expect(items[1].isNewLow, isTrue);
    expect(items[1].deltaKg, -1);
  });

  test('Today cannot be inferred for a future-dated measurement', () {
    final rows = [
      row('future', 68, now.add(const Duration(minutes: 5))),
      row('current', 70, now.subtract(const Duration(minutes: 5))),
    ];
    final result = ProgressWeightTimelineProjection.project(
      entries: rows, hasMore: false, capturedAt: now,
    );
    expect(result[0].isToday, isFalse);
    expect(result[0].deltaKg, isNull);
    expect(result[0].isNewLow, isFalse);
    expect(result[1].isToday, isTrue);
  });
}
