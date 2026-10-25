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

  double? get rangeChangeKg {
    if (chartEntries.length < 2) return null;
    return chartEntries.first.weightKg - chartEntries.last.weightKg;
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
