import '../../domain/body_setup.dart';

/// A presentation projection of already owner-scoped canonical History.
/// No smoothing, extra queries, or inferred measurements are performed here.
class ProgressWeightTimelineItem {
  const ProgressWeightTimelineItem({
    required this.entry,
    required this.localMeasuredAt,
    required this.isToday,
    required this.deltaKg,
    required this.isNewLow,
  });

  final BodyWeightEntry entry;
  final DateTime localMeasuredAt;
  final bool isToday;
  final double? deltaKg;
  final bool isNewLow;
}

abstract final class ProgressWeightTimelineProjection {
  static List<ProgressWeightTimelineItem> project({
    required List<BodyWeightEntry> entries,
    required bool hasMore,
    required DateTime capturedAt,
  }) {
    final localNow = capturedAt.toLocal();
    final result = <ProgressWeightTimelineItem>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final local = entry.measuredAt.toLocal();
      final eligible = !entry.measuredAt.isAfter(capturedAt);
      final earlier = i + 1 < entries.length ? entries[i + 1] : null;
      final comparable = earlier != null &&
          earlier.measuredAt.isBefore(entry.measuredAt) &&
          !earlier.measuredAt.isAfter(capturedAt);
      final olderWeights = entries
          .skip(i + 1)
          .where((e) =>
              e.measuredAt.isBefore(entry.measuredAt) &&
              !e.measuredAt.isAfter(capturedAt))
          .map((e) => e.weightKg);
      result.add(
        ProgressWeightTimelineItem(
          entry: entry,
          localMeasuredAt: local,
          isToday: eligible &&
              local.year == localNow.year &&
              local.month == localNow.month &&
              local.day == localNow.day,
          deltaKg: eligible && comparable
              ? entry.weightKg - earlier!.weightKg
              : null,
          // An all-history badge is only warranted after pagination ends.
          isNewLow: eligible &&
              !hasMore &&
              olderWeights.isNotEmpty &&
              olderWeights.every((kg) => entry.weightKg < kg),
        ),
      );
    }
    return List<ProgressWeightTimelineItem>.unmodifiable(result);
  }
}
