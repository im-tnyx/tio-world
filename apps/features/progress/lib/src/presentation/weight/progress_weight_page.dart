import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/body_setup.dart';
import 'progress_weight_dashboard_reader.dart';
import 'progress_weight_log_sheet.dart';
import 'progress_weight_timeline_projection.dart';

// Core primary button at its standard 46dp height, plus the 24dp insets.
const double _logWeightActionClearance = TioButtonTokens.height + 2 * TioSpacing.xl;

/// Weight-only A2 Progress surface. Ownership, authentication, persistence and
/// the global unit preference are resolved by the app composition root.
class ProgressWeightPage extends StatefulWidget {
  const ProgressWeightPage({
    required this.repository,
    required this.unit,
    required this.sessionKey,
    this.onWeightLogged,
    this.now,
    super.key,
  });

  final BodyRepository repository;
  final WeightUnit unit;
  final String sessionKey;

  /// App-composition invalidation of the existing Settings/Body read caches.
  /// Progress never imports app providers or owns Body Goal semantics.
  final VoidCallback? onWeightLogged;

  final DateTime Function()? now;

  @override
  State<ProgressWeightPage> createState() => _ProgressWeightPageState();
}

class _ProgressWeightPageState extends State<ProgressWeightPage> {
  ProgressWeightRange _range = ProgressWeightRange.days30;
  bool _rangeSelectedByUser = false;
  ProgressWeightSnapshot? _snapshot;
  Object? _error;
  Object? _historyError;
  bool _loading = true;
  bool _loadingMore = false;
  int _generation = 0;
  ValueNotifier<bool> _sessionActive = ValueNotifier<bool>(true);

  ProgressWeightDashboardReader get _reader =>
      ProgressWeightDashboardReader(widget.repository, now: widget.now);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ProgressWeightPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionKey != widget.sessionKey ||
        !identical(oldWidget.repository, widget.repository)) {
      _sessionActive.value = false;
      _sessionActive = ValueNotifier<bool>(true);
      // A new owner starts with a fresh, non-user-selected chart range.
      _range = ProgressWeightRange.days30;
      _rangeSelectedByUser = false;
      // Invalidate all prior async completions, including page fetches.
      _reload();
    }
  }

  @override
  void dispose() {
    _generation++;
    _sessionActive.value = false;
    super.dispose();
  }

  Future<void> _openLogWeight() async {
    final snapshot = _snapshot;
    if (snapshot == null || _loading) return;
    final active = _sessionActive;
    final repository = widget.repository;
    final result = await showProgressWeightLogSheet(
      context: context,
      unit: widget.unit,
      currentWeightKg: snapshot.current?.weightKg,
      sessionActive: active,
      now: widget.now,
      onSubmit: (record) {
        if (!mounted || !active.value) {
          throw StateError('Weight session is no longer active.');
        }
        return repository.recordCurrentWeight(record);
      },
    );
    if (!mounted || !active.value || result != true) return;
    widget.onWeightLogged?.call();
    await _reload();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _snapshot = null;
      _error = null;
      _historyError = null;
    });
    try {
      var selectedRange = _range;
      var snapshot = await _reader.load(selectedRange);
      if (!mounted || generation != _generation) return;

      // Initial/default 30-day selection can be empty even while older,
      // owner-scoped History contains real measurements. Widen only to the
      // first range with actual points; never manufacture today's weight or
      // override a range explicitly chosen by the user.
      if (!_rangeSelectedByUser &&
          selectedRange == ProgressWeightRange.days30 &&
          snapshot.chartEntries.isEmpty &&
          snapshot.history.entries.isNotEmpty) {
        for (final fallback in [
          ProgressWeightRange.days90,
          ProgressWeightRange.days365,
        ]) {
          ProgressWeightSnapshot extended;
          try {
            extended = await _reader.load(fallback);
          } catch (_) {
            // Widening is optional: retain the valid baseline summary,
            // Timeline and Log Weight action on a transient read failure.
            // Never expose owner-owned data or transport details in logs.
            if (!mounted || generation != _generation) return;
            break;
          }
          if (!mounted || generation != _generation) return;
          if (extended.chartEntries.isNotEmpty) {
            selectedRange = fallback;
            snapshot = extended;
            break;
          }
        }
      }

      if (!mounted || generation != _generation) return;
      setState(() {
        _range = selectedRange;
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      // Never log health measurements, tokens or user-owned row identifiers.
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = const _WeightLoadFailure();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final snapshot = _snapshot;
    final cursor = snapshot?.history.nextCursor;
    if (snapshot == null || cursor == null || _loadingMore) return;
    final generation = _generation;
    setState(() {
      _historyError = null;
      _loadingMore = true;
    });
    try {
      final next = await _reader.loadMore(cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        _snapshot = snapshot.appendHistory(next);
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loadingMore = false;
        _historyError = const _WeightLoadFailure();
      });
    }
  }

  void _setRange(ProgressWeightRange range) {
    _rangeSelectedByUser = true;
    if (range == _range) return;
    setState(() => _range = range);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final typography = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const ValueKey('progress-weight-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          TioSpacing.lg,
          TioSpacing.md,
          TioSpacing.lg,
          _logWeightActionClearance + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // The shell owns the Progress title. The body begins with the
          // actual Weight summary instead of repeating a page heading.
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(TioSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            TioCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weight could not be loaded.'),
                  const SizedBox(height: TioSpacing.sm),
                  TioButton.secondary(label: 'Retry', onPressed: _reload),
                ],
              ),
            )
          else if (_snapshot != null) ...[
            _summary(context, _snapshot!),
            const SizedBox(height: TioSpacing.xl),
            Text('Timeline', style: typography.titleLarge),
            const SizedBox(height: TioSpacing.sm),
            if (_snapshot!.history.entries.isEmpty)
              const TioCard(
                child: Text(
                  'No weight measurements yet. Use Log Weight to add your first measurement.',
                ),
              )
            else
              ..._timelineEntries(context, _snapshot!),
            if (_historyError != null) ...[
              Text(
                'More history could not be loaded.',
                style: typography.bodyMedium?.copyWith(color: colors.danger),
              ),
              const SizedBox(height: TioSpacing.xs),
            ],
            if (_snapshot!.history.nextCursor != null ||
                _historyError != null)
              Center(
                child: TioButton.supporting(
                  key: const ValueKey('progress-weight-load-more'),
                  label: _historyError == null ? 'Load more' : 'Retry history',
                  loading: _loadingMore,
                  onPressed: _loadMore,
                ),
              ),
          ],
          const SizedBox(height: TioSpacing.xl),
        ],
      ),
        ),
        if (!_loading && _error == null && _snapshot != null)
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsets.all(TioSpacing.xl),
                  child: SizedBox(
                    height: TioButtonTokens.height,
                    child: TioButton.primary(
                      key: const ValueKey('progress-weight-log-action'),
                      label: 'Log Weight',
                      onPressed: _openLogWeight,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _summary(BuildContext context, ProgressWeightSnapshot snapshot) {
    final colors = context.tioColors;
    final typography = Theme.of(context).textTheme;
    final current = snapshot.current;
    final delta = snapshot.rangeChangeKg;
    final weeklyRate = snapshot.weeklyRateOfChangeKg;
    final target = snapshot.goal?.targetWeightKg;
    final chart = snapshot.chartEntries;
    final scale = chart.isEmpty
        ? null
        : _WeightChartScale.fromEntries(chart, target);

    final statistics = <Widget>[
      _summaryStatCard(
        context,
        'progress-weight-stat-current',
        'CURRENT',
        current == null
            ? '—'
            : UnitFormatters.formatWeight(current.weightKg, widget.unit),
      ),
      _summaryStatCard(
        context,
        'progress-weight-stat-change',
        '${_range.days} DAY CHANGE',
        delta == null ? 'Not enough history' : _formatChange(delta),
      ),
      _summaryStatCard(
        context,
        'progress-weight-stat-rate',
        'RATE OF CHANGE',
        weeklyRate == null ? '—' : _formatWeeklyRate(weeklyRate),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Weight summary', style: typography.titleLarge),
            ),
            MenuAnchor(
              consumeOutsideTap: true,
              style: const MenuStyle(
                backgroundColor:
                    WidgetStatePropertyAll(TioPalette.transparent),
                elevation: WidgetStatePropertyAll(TioElevation.none),
                shadowColor:
                    WidgetStatePropertyAll(TioPalette.transparent),
                surfaceTintColor:
                    WidgetStatePropertyAll(TioPalette.transparent),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    horizontal: TioSpacing.sm,
                    vertical: TioSpacing.xs,
                  ),
                ),
              ),
              menuChildren: [
                TioCard(
                  key: const ValueKey('progress-weight-range-menu-card'),
                  variant: TioCardVariant.elevated,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final range in ProgressWeightRange.values)
                        MenuItemButton(
                          key: ValueKey('progress-weight-range-option-${range.days}'),
                          trailingIcon: range == _range
                              ? const Icon(Icons.check_rounded,
                                  size: TioSize.dp20)
                              : const SizedBox(width: TioSize.dp20),
                          onPressed: () => _setRange(range),
                          child: Text(range.label),
                        ),
                    ],
                  ),
                ),
              ],
              builder: (context, controller, child) => MergeSemantics(
                child: Semantics(
                  button: true,
                  expanded: controller.isOpen,
                  label: 'Select weight chart range',
                  child: InkWell(
                    key: const ValueKey('progress-weight-range'),
                    borderRadius: BorderRadius.circular(TioRadius.md),
                    onTap: controller.isOpen
                        ? controller.close
                        : controller.open,
                    child: Padding(
                      padding: const EdgeInsets.all(TioSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_range.label, style: typography.labelMedium),
                          const SizedBox(width: TioSpacing.xs),
                          const Icon(Icons.keyboard_arrow_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TioSpacing.md),
        TioCard(
          key: const ValueKey('progress-weight-graph-card'),
          variant: TioCardVariant.normal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chart.isEmpty)
                Padding(
                  key: const ValueKey('progress-weight-chart-empty'),
                  padding: const EdgeInsets.symmetric(
                    vertical: TioSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No measurements in this range'),
                      const SizedBox(height: TioSpacing.xs),
                      Text(
                        'Choose another range or Log Weight to see a trend.',
                        style: typography.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Semantics(
                  label: 'Weight trend with ${chart.length} actual measurements '
                      'in ${_range.label}, scale in '
                      '${widget.unit == WeightUnit.kg ? 'kilograms' : 'pounds'}. '
                      'Individual measurements are available in Timeline.',
                  child: SizedBox(
                    height: TioSize.dp120,
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox.expand(
                            child: CustomPaint(
                              key: const ValueKey('progress-weight-chart'),
                              painter: _RecordedWeightPainter(
                                entries: chart,
                                scale: scale!,
                                targetKg: target,
                                lineColor: colors.progress,
                                gridColor: colors.outlineStrong,
                                targetColor: colors.success,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: TioSpacing.xs),
                        SizedBox(
                          key: const ValueKey('progress-weight-chart-axis'),
                          width: TioSize.dp48,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: TioSpacing.xxs,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final value in [
                                  scale.high,
                                  (scale.low + scale.high) / 2,
                                  scale.low,
                                ])
                                  Text(
                                    scale.axisLabel(value, widget.unit),
                                    maxLines: 1,
                                    style: typography.labelSmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TioSpacing.xs),
                if (chart.length == 1)
                  Center(
                    child: Text(
                      key: const ValueKey('progress-weight-single-date'),
                      _dateLabel(context, chart.first.measuredAt),
                      style: typography.bodySmall,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _dateLabel(context, chart.last.measuredAt),
                          style: typography.bodySmall,
                        ),
                      ),
                      const SizedBox(width: TioSpacing.xs),
                      Flexible(
                        child: Text(
                          _dateLabel(context, chart.first.measuredAt),
                          textAlign: TextAlign.end,
                          style: typography.bodySmall,
                        ),
                      ),
                    ],
                  ),
              ],
              if (target != null) ...[
                const SizedBox(height: TioSpacing.md),
                Text(
                  'Your target: ${UnitFormatters.formatWeight(target, widget.unit)}',
                  style: typography.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TioSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            // Two compact cards + a full-width third on phones. One column
            // for narrow/text-scaled screens; three columns on wide layouts.
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final singleColumn =
                constraints.maxWidth < TioSize.dp320 || scale > 1.5;
            if (singleColumn) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < statistics.length; i++) ...[
                    if (i > 0) const SizedBox(height: TioSpacing.sm),
                    statistics[i],
                  ],
                ],
              );
            }
            final showThreeColumns = constraints.maxWidth >=
                TioSize.dp480 + TioSize.dp120;
            return Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: statistics[0]),
                      const SizedBox(width: TioSpacing.sm),
                      Expanded(child: statistics[1]),
                      if (showThreeColumns) ...[
                        const SizedBox(width: TioSpacing.sm),
                        Expanded(child: statistics[2]),
                      ],
                    ],
                  ),
                ),
                if (!showThreeColumns) ...[
                  const SizedBox(height: TioSpacing.sm),
                  statistics[2],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _summaryStatCard(
    BuildContext context,
    String key,
    String label,
    String value,
  ) =>
      TioCard(
        key: ValueKey(key),
        variant: TioCardVariant.normal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TioSize.dp56),
          child: _stat(context, label, value),
        ),
      );

  Widget _stat(BuildContext context, String label, String value) {
    final colors = context.tioColors;
    final typography = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: typography.labelSmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: TioSpacing.xs),
        Text(
          value,
          style: typography.titleMedium?.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }

  String _formatChange(double kilograms) {
    if (kilograms == 0) return 'No change';
    final value = UnitFormatters.formatWeight(kilograms, widget.unit);
    return kilograms > 0 ? '+$value' : value;
  }

  String _formatWeeklyRate(double kilogramsPerWeek) {
    final displayValue = widget.unit == WeightUnit.kg
        ? kilogramsPerWeek
        : UnitConverters.kgToLb(kilogramsPerWeek);
    final unit = widget.unit == WeightUnit.kg ? 'kg' : 'lb';
    // Sign the rounded visible number, not a tiny value displayed as zero.
    if (displayValue.abs() < 0.05) return '0 $unit/week';
    final magnitude =
        UnitFormatters.formatWeight(kilogramsPerWeek.abs(), widget.unit);
    return '${kilogramsPerWeek > 0 ? '+' : '-'}$magnitude/week';
  }



  List<Widget> _timelineEntries(
    BuildContext context,
    ProgressWeightSnapshot snapshot,
  ) {
    final rows = ProgressWeightTimelineProjection.project(
      entries: snapshot.history.entries,
      hasMore: snapshot.history.nextCursor != null,
      capturedAt: snapshot.capturedAt,
    );
    final colors = context.tioColors;
    final typography = Theme.of(context).textTheme;
    final localization = MaterialLocalizations.of(context);
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (i == 0 ||
          rows[i - 1].localMeasuredAt.month != row.localMeasuredAt.month ||
          rows[i - 1].localMeasuredAt.year != row.localMeasuredAt.year) {
        result.add(const SizedBox(height: TioSpacing.md));
        result.add(
          Text(
            localization.formatMonthYear(row.localMeasuredAt).toUpperCase(),
            key: ValueKey(
              'progress-weight-timeline-month-'
              '${row.localMeasuredAt.year}-${row.localMeasuredAt.month}',
            ),
            style: typography.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        );
        result.add(const SizedBox(height: TioSpacing.sm));
      }
      result.add(_historyEntry(context, row, snapshot.goal?.goalType));
      result.add(const SizedBox(height: TioSpacing.xs));
    }
    return result;
  }

  Widget _historyEntry(
    BuildContext context,
    ProgressWeightTimelineItem item,
    BodyGoalType? goalType,
  ) {
    final colors = context.tioColors;
    final typography = Theme.of(context).textTheme;
    final entry = item.entry;
    final local = item.localMeasuredAt;
    final date = item.isToday
        ? 'Today'
        : MaterialLocalizations.of(context).formatShortMonthDay(local);
    final displayedWeight = widget.unit == WeightUnit.kg
        ? entry.weightKg
        : UnitConverters.kgToLb(entry.weightKg);
    final unitText = widget.unit == WeightUnit.kg ? 'kg' : 'lb';
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final largerText = textScale > 1.15;
    bool stackTimelineBadges(double effectiveContentWidth) =>
        largerText ||
        effectiveContentWidth < (TioSize.dp320 - TioSize.dp40);

    final dateColumn = SizedBox(
      width: largerText ? TioSize.dp110 : TioSize.dp76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // One date line instead of a separate dot row keeps the card
          // compact without dropping the Today indicator or recorded time.
          Row(
            children: [
              Icon(
                Icons.circle,
                size: TioSize.dp8,
                color: item.isToday ? colors.progress : colors.textMuted,
              ),
              const SizedBox(width: TioSpacing.xs),
              Expanded(
                child: Text(
                  date,
                  key: item.isToday
                      ? ValueKey('progress-weight-timeline-today-${entry.id}')
                      : null,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.labelMedium?.copyWith(
                    color: item.isToday
                        ? colors.progress
                        : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.xxs),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: TioSpacing.md),
            child: Text(
              TimeOfDay.fromDateTime(local).format(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
    final weightColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${displayedWeight.toStringAsFixed(1)} $unitText',
          maxLines: largerText ? 2 : 1,
          overflow: largerText ? TextOverflow.visible : TextOverflow.ellipsis,
          style: typography.titleLarge?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (entry.note != null) ...[
          const SizedBox(height: TioSpacing.xs),
          Tooltip(
            message: entry.note!,
            child: Text(
              entry.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
    final badges = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (item.isNewLow) ...[
          _timelineBadge(
            context,
            label: 'New low',
            key: ValueKey('progress-weight-timeline-new-low-${entry.id}'),
            foreground: colors.success,
            background: colors.success.withValues(alpha: TioOpacity.opacity12),
            semantics: 'New lowest weight compared with all older measurements',
          ),
          if (item.deltaKg != null)
            const SizedBox(height: TioSpacing.xs),
        ],
        if (item.deltaKg != null)
          _timelineChangeBadge(context, item, goalType),
      ],
    );
    final hasBadges = item.isNewLow || item.deltaKg != null;
    final card = TioCard(
      variant: TioCardVariant.normal,
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.md,
        vertical: TioSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On compact screens put badges on their own row rather than
          // squeezing dates, units, or accessibility-scaled weight text.
          if (stackTimelineBadges(
            constraints.maxWidth -
                (item.isToday ? 0 : 2 * TioStroke.width1),
          )) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    dateColumn,
                    const SizedBox(width: TioSpacing.sm),
                    Expanded(child: weightColumn),
                  ],
                ),
                if (hasBadges) ...[
                  const SizedBox(height: TioSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: badges,
                  ),
                ],
              ],
            );
          }
          return Row(
            children: [
              dateColumn,
              const SizedBox(width: TioSpacing.md),
              Expanded(child: weightColumn),
              if (hasBadges) ...[
                const SizedBox(width: TioSpacing.sm),
                badges,
              ],
            ],
          );
        },
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Every row uses one fixed height for the same viewport/text scale,
        // irrespective of notes, Today border or one/two change badges.
        // Expand the shared height at narrow widths or accessibility scales
        // instead of clipping the weight value or its unit.
        // Reserve the Today outline inset for every row so Today and
        // non-Today entries always share the same height breakpoint.
        final stackBadges = stackTimelineBadges(
          constraints.maxWidth - 2 * TioSpacing.md - 2 * TioStroke.width1,
        );
        final height = TioSize.dp80 +
            (stackBadges ? TioSize.dp54 : 0) +
            math.max(0.0, textScale - 1.0) * TioSize.dp80;
        return SizedBox(
          height: height,
          child: DecoratedBox(
            key: ValueKey('progress-weight-history-${entry.id!}'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              border: item.isToday
                  ? Border.all(color: colors.progress, width: TioStroke.width1)
                  : null,
            ),
            // Outline does not increase overall card height for Today.
            child: Padding(
              padding: item.isToday
                  ? const EdgeInsets.all(TioStroke.width1)
                  : EdgeInsets.zero,
              child: card,
            ),
          ),
        );
      },
    );
  }

  Widget _timelineChangeBadge(
    BuildContext context,
    ProgressWeightTimelineItem item,
    BodyGoalType? goalType,
  ) {
    final colors = context.tioColors;
    final delta = item.deltaKg!;
    final value = widget.unit == WeightUnit.kg
        ? delta
        : UnitConverters.kgToLb(delta);
    final improving = switch (goalType) {
      BodyGoalType.loseWeight => delta < 0,
      BodyGoalType.gainWeight => delta > 0,
      _ => false,
    };
    final worsening = switch (goalType) {
      BodyGoalType.loseWeight => delta > 0,
      BodyGoalType.gainWeight => delta < 0,
      _ => false,
    };
    final tint = improving
        ? colors.success
        : worsening
            ? colors.danger
            : colors.textSecondary;
    return _timelineBadge(
      context,
      label: '${delta > 0 ? '+' : ''}${value.toStringAsFixed(1)}',
      key: ValueKey('progress-weight-timeline-change-${item.entry.id}'),
      foreground: tint,
      background: improving || worsening
          ? tint.withValues(alpha: TioOpacity.opacity12)
          : colors.surfaceVariant,
      semantics: 'Change from previous older measurement: '
          '${UnitFormatters.formatWeight(delta.abs(), widget.unit)}, '
          '${delta > 0 ? 'increase' : delta < 0 ? 'decrease' : 'no change'}',
    );
  }

  Widget _timelineBadge(
    BuildContext context, {
    required String label,
    required Key key,
    required Color foreground,
    required Color background,
    required String semantics,
  }) {
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: DecoratedBox(
        key: key,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(TioRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.sm,
            vertical: TioSpacing.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
}

class _WeightLoadFailure {
  const _WeightLoadFailure();
}

/// Draws only real points at their recorded instants, with optional target
/// reference. Connecting recorded neighbours adds no synthetic point/data.
/// A single kg-domain scale is shared by the plot and its visible side axis.
/// Conversion to lb affects labels only; the source-of-truth values stay in kg.
class _WeightChartScale {
  const _WeightChartScale({required this.low, required this.high});

  final double low;
  final double high;

  factory _WeightChartScale.fromEntries(
    List<BodyWeightEntry> entries,
    double? targetKg,
  ) {
    var low = entries.first.weightKg;
    var high = low;
    for (final entry in entries) {
      low = math.min(low, entry.weightKg);
      high = math.max(high, entry.weightKg);
    }
    if (targetKg != null) {
      low = math.min(low, targetKg);
      high = math.max(high, targetKg);
    }
    final pad = (high - low).abs() < 0.01 ? 1.0 : (high - low) * 0.08;
    return _WeightChartScale(low: low - pad, high: high + pad);
  }

  String axisLabel(double kilograms, WeightUnit unit) {
    final weight = unit == WeightUnit.kg
        ? kilograms
        : UnitConverters.kgToLb(kilograms);
    final rounded = weight.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }
}

class _RecordedWeightPainter extends CustomPainter {
  const _RecordedWeightPainter({
    required this.entries,
    required this.scale,
    required this.targetKg,
    required this.lineColor,
    required this.gridColor,
    required this.targetColor,
  });

  final List<BodyWeightEntry> entries;
  final _WeightChartScale scale;
  final double? targetKg;
  final Color lineColor;
  final Color gridColor;
  final Color targetColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || size.width <= 0 || size.height <= 0) return;
    final ordered = entries.reversed.toList(growable: false);

    const left = TioSize.dp8;
    final right = size.width - TioSize.dp8;
    const top = TioSize.dp8;
    final bottom = size.height - TioSize.dp8;
    final oldestUs = ordered.first.measuredAt.microsecondsSinceEpoch;
    final newestUs = ordered.last.measuredAt.microsecondsSinceEpoch;
    final spanUs = newestUs - oldestUs;

    double x(BodyWeightEntry entry) => spanUs == 0
        ? (left + right) / 2
        : left +
            (entry.measuredAt.microsecondsSinceEpoch - oldestUs) /
                spanUs *
                (right - left);
    double y(double weight) =>
        bottom - (weight - scale.low) / (scale.high - scale.low) *
            (bottom - top);

    final grid = Paint()
      ..color = gridColor.withValues(alpha: TioOpacity.opacity30)
      ..strokeWidth = TioStroke.width1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final height = top + (bottom - top) * fraction;
      canvas.drawLine(Offset(left, height), Offset(right, height), grid);
    }
    if (targetKg != null) {
      final goalY = y(targetKg!);
      final goalPaint = Paint()
        ..color = targetColor
        ..strokeWidth = TioStroke.width2;
      for (var position = left; position < right; position += TioSize.dp12) {
        canvas.drawLine(
          Offset(position, goalY),
          Offset(math.min(position + TioSize.dp8, right), goalY),
          goalPaint,
        );
      }
    }

    final points = ordered.map((e) => Offset(x(e), y(e.weightKg))).toList();
    final stroke = Paint()
      ..color = lineColor
      ..strokeWidth = TioStroke.width2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, stroke);
    }
    final dot = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, TioSize.dp3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _RecordedWeightPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.scale.low != scale.low ||
        oldDelegate.scale.high != scale.high ||
        oldDelegate.targetKg != targetKg ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.targetColor != targetColor;
  }
}
