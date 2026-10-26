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
      // A same-instant sibling cannot be ordered temporally, but it does
      // compete for an all-history minimum. Compare it without inventing a
      // before/after sequence; exclude only this exact row by list index.
      final priorOrConcurrentWeights = <double>[];
      var hasStrictlyOlder = false;
      for (var j = 0; j < entries.length; j++) {
        if (j == i) continue;
        final other = entries[j];
        if (other.measuredAt.isAfter(entry.measuredAt) ||
            other.measuredAt.isAfter(capturedAt)) {
          continue;
        }
        if (other.measuredAt.isBefore(entry.measuredAt)) {
          hasStrictlyOlder = true;
        }
        priorOrConcurrentWeights.add(other.weightKg);
      }
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
              hasStrictlyOlder &&
              priorOrConcurrentWeights.every((kg) => entry.weightKg < kg),
        ),
      );
    }
    return List<ProgressWeightTimelineItem>.unmodifiable(result);
  }
}
