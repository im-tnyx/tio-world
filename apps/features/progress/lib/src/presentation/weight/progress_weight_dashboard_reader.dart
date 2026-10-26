import '../../domain/body_setup.dart';

/// The chart window is relative to an instant, not a synthetic calendar series.
enum ProgressWeightRange {
  days30(30, 'Last 30 days'),
  days90(90, 'Last 90 days'),
  days365(365, 'Last 365 days');

  const ProgressWeightRange(this.days, this.label);

  final int days;
  final String label;
}

/// A display-independent projection of the canonical active Body Goal.
enum ProgressWeightTargetStatus {
  reached,
  belowTarget,
  aboveTarget,
  onTrack,
  progress,
}

class ProgressWeightTargetProgress {
  const ProgressWeightTargetProgress({
    required this.targetKg,
    required this.remainingKg,
    required this.status,
  });

  final double targetKg;
  final double? remainingKg;
  final ProgressWeightTargetStatus status;
}

/// Immutable owner-scoped read model. History and chart have different windows.
class ProgressWeightSnapshot {
  const ProgressWeightSnapshot({
    required this.current,
    required this.goal,
    required this.chartEntries,
    required this.history,
    required this.range,
    required this.capturedAt,
  });

  final BodyWeightEntry? current;
  final BodyGoalState? goal;
  /// All actual recorded measurements in the selected window, newest first.
  final List<BodyWeightEntry> chartEntries;
  final BodyWeightHistoryPage history;
  final ProgressWeightRange range;
  final DateTime capturedAt;

  /// Goal status is a domain projection, not a decision made by the widget.
  /// A missing real measurement remains unknown even with a valid target.
  ProgressWeightTargetProgress? get targetProgress {
    final activeGoal = goal;
    final target = activeGoal?.targetWeightKg;
    if (activeGoal == null || target == null) return null;

    final weight = current?.weightKg;
    // Keep the actual difference on either side of the saved goal. Clamping
    // it to zero previously hid overshoot behind "Target reached".
    final signedDifference = weight == null ? null : weight - target;
    final remaining = signedDifference?.abs();
    final baseline = activeGoal.startingWeightKg;
    final movedCloser = remaining != null &&
        baseline != null &&
        remaining < (baseline - target).abs();
    final status = signedDifference == null
        ? ProgressWeightTargetStatus.progress
        : signedDifference.abs() < 0.0001
            ? ProgressWeightTargetStatus.reached
            : activeGoal.goalType == BodyGoalType.loseWeight &&
                    signedDifference < 0
                ? ProgressWeightTargetStatus.belowTarget
                : activeGoal.goalType == BodyGoalType.gainWeight &&
                        signedDifference > 0
                    ? ProgressWeightTargetStatus.aboveTarget
                    : movedCloser
                        ? ProgressWeightTargetStatus.onTrack
                        : ProgressWeightTargetStatus.progress;
    return ProgressWeightTargetProgress(
      targetKg: target,
      remainingKg: remaining,
      status: status,
    );
  }

  double? get rangeChangeKg {
    if (chartEntries.length < 2 ||
        chartEntries.first.measuredAt.isAtSameMomentAs(
          chartEntries.last.measuredAt,
        )) {
      return null;
    }
    return chartEntries.first.weightKg - chartEntries.last.weightKg;
  }

  /// Signed real change per seven elapsed days, never a prediction or goal pace.
  /// The first and last in-range instants must be distinct, as for rangeChange.
  double? get weeklyRateOfChangeKg {
    final change = rangeChangeKg;
    if (change == null) return null;
    final elapsed = chartEntries.first.measuredAt
        .difference(chartEntries.last.measuredAt)
        .inMicroseconds;
    // A few hours of entries do not establish an honest weekly pace.
    if (elapsed < Duration.microsecondsPerDay * 7) return null;
    return change * (Duration.microsecondsPerDay * 7) / elapsed;
  }

  ProgressWeightSnapshot appendHistory(BodyWeightHistoryPage next) {
    return ProgressWeightSnapshot(
      current: current,
      goal: goal,
      chartEntries: chartEntries,
      history: BodyWeightHistoryPage(
        entries: List<BodyWeightEntry>.unmodifiable([
          ...history.entries,
          ...next.entries,
        ]),
        nextCursor: next.nextCursor,
      ),
      range: range,
      capturedAt: capturedAt,
    );
  }
}

/// Bounded A2 projection over the existing A1 owner-backed repository.
///
/// getBodyState().latestWeight is intentionally NOT used as Current Weight:
/// its pre-existing Settings/Body Goal contract does not yet exclude future
/// rows or tie-break same-time rows. A1 History has both ordering guarantees.
class ProgressWeightDashboardReader {
  ProgressWeightDashboardReader(
    this.repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BodyRepository repository;
  final DateTime Function() _now;

  static final DateTime _historyStart = DateTime.utc(1);
  static final DateTime _historyEnd = DateTime.utc(9999);

  Future<ProgressWeightSnapshot> load(ProgressWeightRange range) async {
    final now = _now().toUtc();
    final eligibleEnd = now.add(const Duration(microseconds: 1));

    // Goal is a reference only; never infer one from numeric weight.
    final goal = (await repository.getBodyState()).activeGoal;
    final currentPage = await repository.getWeightHistory(
      BodyWeightHistoryQuery(
        fromInclusive: _historyStart,
        toExclusive: eligibleEnd,
        limit: 1,
      ),
    );
    final current = currentPage.entries.isEmpty
        ? null
        : currentPage.entries.first;

    final chartEntries = <BodyWeightEntry>[];
    BodyWeightHistoryCursor? before;
    // A hard failure is preferable to a silently incomplete chart/change.
    for (var pageIndex = 0; pageIndex < 1000; pageIndex++) {
      final page = await repository.getWeightHistory(
        BodyWeightHistoryQuery(
          fromInclusive: now.subtract(Duration(days: range.days)),
          toExclusive: eligibleEnd,
          limit: 100,
          before: before,
        ),
      );
      chartEntries.addAll(page.entries);
      final next = page.nextCursor;
      if (next == null) break;
      if (before != null &&
          next.id == before.id &&
          next.measuredAt.isAtSameMomentAs(before.measuredAt)) {
        throw StateError('Weight chart pagination did not advance.');
      }
      before = next;
      if (pageIndex == 999) {
        throw StateError('Weight chart has too many measurements to load.');
      }
    }

    final history = await repository.getWeightHistory(
      BodyWeightHistoryQuery(
        fromInclusive: _historyStart,
        toExclusive: _historyEnd,
      ),
    );
    return ProgressWeightSnapshot(
      current: current,
      goal: goal,
      chartEntries: List<BodyWeightEntry>.unmodifiable(chartEntries),
      history: history,
      range: range,
      capturedAt: now,
    );
  }

  Future<BodyWeightHistoryPage> loadMore(BodyWeightHistoryCursor before) {
    return repository.getWeightHistory(
      BodyWeightHistoryQuery(
        fromInclusive: _historyStart,
        toExclusive: _historyEnd,
        before: before,
      ),
    );
  }
}
