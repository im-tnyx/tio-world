import '../../domain/body_setup.dart';

/// A presentation projection of already owner-scoped canonical History.
/// No smoothing, extra queries, or inferred measurements are performed here.
class ProgressWeightTimelineItem {
  const ProgressWeightTimelineItem({
    required this.entry,
    required this.localMeasuredAt,
    required this.isToday,
    required this.isLatestEligible,
    required this.deltaKg,
    required this.isNewLow,
    required this.isNewHigh,
  });

  final BodyWeightEntry entry;
  final DateTime localMeasuredAt;
  final bool isToday;
  /// Only the newest nonfuture entry receives the highlighted outline.
  final bool isLatestEligible;
  final double? deltaKg;
  final bool isNewLow;
  final bool isNewHigh;
}

abstract final class ProgressWeightTimelineProjection {
  static List<ProgressWeightTimelineItem> project({
    required List<BodyWeightEntry> entries,
    required bool hasMore,
    required DateTime capturedAt,
    BodyGoalType? goalType,
  }) {
    final localNow = capturedAt.toLocal();
    final latestEligibleIndex = entries.indexWhere(
      (entry) => !entry.measuredAt.isAfter(capturedAt),
    );
    final result = List<ProgressWeightTimelineItem?>.filled(
      entries.length,
      null,
    );

    // History is canonically ordered measuredAt DESC, id DESC. Traverse
    // timestamp groups oldest-first: each entry is visited a constant number
    // of times, even after many pages have been loaded.
    BodyWeightEntry? nearestOlder;
    double? minimumOlderKg;
    double? maximumOlderKg;
    var groupEnd = entries.length;
    while (groupEnd > 0) {
      final instant = entries[groupEnd - 1].measuredAt;
      var groupStart = groupEnd - 1;
      while (groupStart > 0 &&
          entries[groupStart - 1].measuredAt.isAtSameMomentAs(instant)) {
        groupStart--;
      }

      // Treat all same-instant siblings as one unordered group. A New low
      // requires the current row to be strictly below every sibling as well
      // as every eligible older measurement.
      double? groupMinimumKg;
      var groupMinimumCount = 0;
      double? groupMaximumKg;
      var groupMaximumCount = 0;
      for (var i = groupStart; i < groupEnd; i++) {
        final kg = entries[i].weightKg;
        if (groupMaximumKg == null || kg > groupMaximumKg) {
          groupMaximumKg = kg;
          groupMaximumCount = 1;
        } else if (kg == groupMaximumKg) {
          groupMaximumCount++;
        }
        if (groupMinimumKg == null || kg < groupMinimumKg) {
          groupMinimumKg = kg;
          groupMinimumCount = 1;
        } else if (kg == groupMinimumKg) {
          groupMinimumCount++;
        }
      }

      final eligible = !instant.isAfter(capturedAt);
      for (var i = groupStart; i < groupEnd; i++) {
        final entry = entries[i];
        final local = instant.toLocal();
        result[i] = ProgressWeightTimelineItem(
          entry: entry,
          localMeasuredAt: local,
          isToday: eligible &&
              local.year == localNow.year &&
              local.month == localNow.month &&
              local.day == localNow.day,
          isLatestEligible: eligible && i == latestEligibleIndex,
          // Never compare two records from the same instant as before/after.
          deltaKg: eligible && nearestOlder != null
              ? entry.weightKg - nearestOlder.weightKg
              : null,
          // Incomplete pagination or a future measurement cannot establish
          // an all-history low. The oldest timestamp has no older baseline.
          isNewLow: goalType == BodyGoalType.loseWeight &&
              i == latestEligibleIndex &&
              eligible &&
              !hasMore &&
              nearestOlder != null &&
              minimumOlderKg != null &&
              entry.weightKg < minimumOlderKg &&
              groupMinimumCount == 1 &&
              entry.weightKg == groupMinimumKg,
          isNewHigh: goalType == BodyGoalType.gainWeight &&
              i == latestEligibleIndex &&
              eligible &&
              !hasMore &&
              nearestOlder != null &&
              maximumOlderKg != null &&
              entry.weightKg > maximumOlderKg &&
              groupMaximumCount == 1 &&
              entry.weightKg == groupMaximumKg,
        );
      }

      if (eligible) {
        // The canonical first entry in this group is the closest strictly
        // older predecessor for every measurement in the next newer group.
        nearestOlder = entries[groupStart];
        if (minimumOlderKg == null ||
            groupMinimumKg! < minimumOlderKg) {
          minimumOlderKg = groupMinimumKg;
        }
        if (maximumOlderKg == null || groupMaximumKg! > maximumOlderKg) {
          maximumOlderKg = groupMaximumKg;
        }
      }
      groupEnd = groupStart;
    }

    return List<ProgressWeightTimelineItem>.unmodifiable(
      result.cast<ProgressWeightTimelineItem>(),
    );
  }
}
