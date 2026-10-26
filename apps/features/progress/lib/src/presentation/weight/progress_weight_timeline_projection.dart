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
      // Same-instant siblings are not a temporal comparison. Find the first
      // strictly older actual measurement, skipping equal timestamps.
      BodyWeightEntry? earlier;
      for (var j = i + 1; j < entries.length; j++) {
        final candidate = entries[j];
        if (candidate.measuredAt.isBefore(entry.measuredAt) &&
            !candidate.measuredAt.isAfter(capturedAt)) {
          earlier = candidate;
          break;
        }
      }
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
          deltaKg: eligible && earlier != null
              ? entry.weightKg - earlier.weightKg
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
