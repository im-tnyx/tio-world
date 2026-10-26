import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
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
  bool _refreshFailed = false;
  // Prevent edits against a stale row after a confirmed write while its
  // canonical History refresh is pending or has failed.
  bool _mutationNeedsReconcile = false;
  String? _editingWeightId;
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
      _editingWeightId = null;
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
    if (snapshot == null || _loading || _mutationNeedsReconcile) return;
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
    if (!mounted || !active.value) return;
    await _reconcileWeightMutation();
  }

  Future<void> _openWeightEditor(BodyWeightEntry entry) async {
    final id = entry.id;
    if (id == null || _editingWeightId != null || _loading ||
        _mutationNeedsReconcile) {
      return;
    }
    final active = _sessionActive;
    final generation = _generation;
    final repository = widget.repository;
    setState(() => _editingWeightId = id);
    bool? changed;
    try {
      changed = await showProgressWeightEditSheet(
        context: context,
        unit: widget.unit,
        entry: entry,
        sessionActive: active,
        now: widget.now,
        onUpdate: (edit) {
          if (!mounted || !active.value || generation != _generation) {
            throw StateError('Weight session is no longer active.');
          }
          return repository.updateWeightLog(edit);
        },
        onDelete: (rowId) {
          if (!mounted || !active.value || generation != _generation) {
            throw StateError('Weight session is no longer active.');
          }
          return repository.deleteWeightLog(rowId);
        },
      );
    } finally {
      if (mounted && active.value && generation == _generation) {
        setState(() => _editingWeightId = null);
      }
    }
    if (!mounted || !active.value ||
        generation != _generation || changed != true) {
      return;
    }
    widget.onWeightLogged?.call();
    if (!mounted || !active.value || generation != _generation) {
      return;
    }
    await _reconcileWeightMutation();
  }

  Future<void> _reconcileWeightMutation() async {
    if (!mounted || !_sessionActive.value || _snapshot == null) return;
    setState(() => _mutationNeedsReconcile = true);
    // The existing chart and Timeline stay mounted until the canonical
    // History read succeeds; failure retains them with an explicit Retry.
    await _reload(preserveContent: true);
  }

  Future<void> _reload({bool preserveContent = false}) async {
    // Pull-to-refresh retains the current owner-scoped screen and the native
    // indicator owns the visible progress. Initial load, filter changes,
    // writes, and account/session changes still use a hard fresh read.
    final keepExisting = preserveContent && _snapshot != null && !_loading;
    final generation = ++_generation;
    setState(() {
      _loading = !keepExisting;
      _loadingMore = false;
      if (!keepExisting) {
        _snapshot = null;
        _mutationNeedsReconcile = false;
      }
      _error = null;
      _historyError = null;
      _refreshFailed = false;
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
        _refreshFailed = false;
        _mutationNeedsReconcile = false;
      });
    } catch (_) {
      // Never log health measurements, tokens or user-owned row identifiers.
      if (!mounted || generation != _generation) return;
      setState(() {
        if (keepExisting) {
          // A transient refresh failure must not wipe previously verified
          // same-owner health data or replace it with a full-page spinner.
          _refreshFailed = true;
        } else {
          _error = const _WeightLoadFailure();
        }
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final snapshot = _snapshot;
    final cursor = snapshot?.history.nextCursor;
    if (snapshot == null || cursor == null || _loadingMore ||
        _mutationNeedsReconcile) {
      return;
    }
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
        CustomScrollView(
          key: const ValueKey('progress-weight-scroll'),
          // The refresh sliver occupies real top overscroll space, moving
          // the graph and Timeline beneath the shell's stationary top bar.
          // Bounce physics enables this on Android and short History too.
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(
              key: const ValueKey('progress-weight-pull-space'),
              onRefresh: () => _reload(preserveContent: true),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.md,
                TioSpacing.lg,
                _logWeightActionClearance + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

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
            if (_refreshFailed) ...[
              Row(
                key: const ValueKey('progress-weight-refresh-failed'),
                children: [
                  Expanded(
                    child: Text(
                      'Could not refresh. Showing the last loaded weights.',
                      style: typography.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  TioButton.supporting(
                    label: 'Retry',
                    onPressed: () => _reload(preserveContent: true),
                  ),
                ],
              ),
              const SizedBox(height: TioSpacing.sm),
            ],
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
                ]),
              ),
            ),
          ],
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
                      onPressed: _mutationNeedsReconcile
                          ? null : _openLogWeight,
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

    final startingKg = snapshot.goal?.startingWeightKg;
    // Separate lifetime change since the active Body Goal's canonical
    // starting baseline from N-day chart change. Never guess a baseline.
    final goalChangeKg = startingKg == null || current == null
        ? null
        : current.weightKg - startingKg;
    Color trendColor(double? changeKg) {
      if (changeKg == null || changeKg == 0) return colors.textPrimary;
      final goalType = snapshot.goal?.goalType;
      final improving = (goalType == BodyGoalType.loseWeight && changeKg < 0) ||
          (goalType == BodyGoalType.gainWeight && changeKg > 0);
      final worsening = (goalType == BodyGoalType.loseWeight && changeKg > 0) ||
          (goalType == BodyGoalType.gainWeight && changeKg < 0);
      return improving ? colors.success
          : worsening ? colors.danger : colors.textPrimary;
    }
    final statistics = <Widget>[
      _summaryStatCard(
        context,
        'progress-weight-stat-starting',
        'STARTING',
        startingKg == null
            ? '—' : UnitFormatters.formatWeight(startingKg, widget.unit),
      ),
      _summaryStatCard(
        context,
        'progress-weight-stat-overall-change',
        'CHANGE',
        goalChangeKg == null ? '—' : _formatChange(goalChangeKg),
        valueColor: trendColor(goalChangeKg),
      ),
      _summaryStatCard(
        context,
        'progress-weight-stat-rate',
        'RATE OF CHANGE',
        weeklyRate == null ? '—' : _formatWeeklyRate(weeklyRate),
        valueColor: trendColor(weeklyRate),
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
          padding: const EdgeInsets.all(TioSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _graphHeaderStat(
                      context,
                      key: 'progress-weight-stat-current',
                      label: 'CURRENT',
                      value: current == null
                          ? '—'
                          : UnitFormatters.formatWeight(
                              current.weightKg, widget.unit),
                    ),
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: _graphHeaderStat(
                      context,
                      key: 'progress-weight-stat-change',
                      label: '${_range.days} DAY CHANGE',
                      value: delta == null
                          ? 'Not enough history' : _formatChange(delta),
                      rightAligned: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TioSpacing.md),
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
                          child: _WeightChartInspector(
                            key: ValueKey('weight-chart-inspect-${widget.sessionKey}-${_range.days}'),
                            entries: chart,
                            scale: scale!,
                            targetKg: target,
                            unit: widget.unit,
                            lineColor: colors.progress,
                            targetColor: colors.success,
                            cursorColor: colors.textPrimary,
                            surfaceColor: colors.primary,
                            textColor: colors.onPrimary,
                            painter: _RecordedWeightPainter(
                              entries: chart,
                              scale: scale,
                              targetKg: target,
                              lineColor: colors.progress,
                              gridColor: colors.outlineStrong,
                              targetColor: colors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: TioSpacing.xxs),
                        // Size the axis to its actual labels, avoiding a
                        // phantom left inset from a fixed 48dp column.
                        IntrinsicWidth(
                          key: const ValueKey('progress-weight-chart-axis'),
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
            ],
          ),
        ),
        const SizedBox(height: TioSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            // Same-size three-column cards at ordinary phone widths. Only
            // narrow accessibility layouts stack to retain complete units.
            final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.5;
            if (enlarged || constraints.maxWidth < (TioSize.dp320 - TioSize.dp40)) {
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
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: statistics[0]),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(child: statistics[1]),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(child: statistics[2]),
                ],
              ),
            );
          },
        ),
        if (target != null && snapshot.goal != null) ...[
          const SizedBox(height: TioSpacing.sm),
          _targetProgressCard(context, current, snapshot.goal!),
        ],
      ],
    );
  }

  Widget _targetProgressCard(
    BuildContext context,
    BodyWeightEntry? current,
    BodyGoalState goal,
  ) {
    final colors = context.tioColors;
    final targetKg = goal.targetWeightKg!;
    final remaining = current == null ? null : switch (goal.goalType) {
      BodyGoalType.loseWeight => math.max(0.0, current.weightKg - targetKg),
      BodyGoalType.gainWeight => math.max(0.0, targetKg - current.weightKg),
      _ => (current.weightKg - targetKg).abs(),
    };
    final beginning = goal.startingWeightKg;
    final movedCloser = remaining != null && beginning != null &&
        remaining < (beginning - targetKg).abs();
    final status = remaining != null && remaining < 0.0001
        ? 'Target reached'
        : movedCloser ? 'On track to target' : 'Target progress';
    return TioCard(
      key: const ValueKey('progress-weight-target-card'),
      variant: TioCardVariant.normal,
      padding: const EdgeInsets.all(TioSpacing.sm),
      child: Row(
        children: [
          Container(
            width: TioSize.dp36,
            height: TioSize.dp36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.progress.withValues(alpha: TioOpacity.opacity12),
              border: Border.all(
                color: colors.progress, width: TioStroke.width075,
              ),
            ),
            child: Icon(
              Icons.flag_outlined, color: colors.progress, size: TioSize.dp20,
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: TioSpacing.xs,
              runSpacing: TioSpacing.xxs,
              children: [
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  remaining == null
                      ? 'Target: ${UnitFormatters.formatWeight(targetKg, widget.unit)}'
                      : remaining < 0.0001
                          ? ''
                          : '${UnitFormatters.formatWeight(remaining, widget.unit)} to go',
                  key: const ValueKey('progress-weight-target-distance'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _graphHeaderStat(
    BuildContext context, {
    required String key,
    required String label,
    required String value,
    bool rightAligned = false,
  }) {
    final typography = Theme.of(context).textTheme;
    final colors = context.tioColors;
    return Column(
      key: ValueKey(key),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: rightAligned
          ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          textAlign: rightAligned ? TextAlign.end : TextAlign.start,
          style: typography.labelSmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: TioSpacing.xxs),
        Text(
          value,
          textAlign: rightAligned ? TextAlign.end : TextAlign.start,
          style: typography.titleMedium?.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }

  Widget _summaryStatCard(
    BuildContext context,
    String key,
    String label,
    String value, {
    Color? valueColor,
  }) =>
      TioCard(
        key: ValueKey(key),
        variant: TioCardVariant.normal,
        padding: const EdgeInsets.all(TioSpacing.xs),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TioSize.dp48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                softWrap: true,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: valueColor ?? context.tioColors.textPrimary,
                ),
              ),
              const SizedBox(height: TioSpacing.xxs),
              Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.tioColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

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
      goalType: snapshot.goal?.goalType,
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
        effectiveContentWidth < (TioSize.dp320 + TioSize.dp32);

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
                color: item.isLatestEligible ? colors.progress : colors.textMuted,
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
                    color: item.isLatestEligible
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
          style: typography.titleMedium?.copyWith(
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
    final recordLabel =
        item.isNewLow ? 'New low' : item.isNewHigh ? 'New high' : null;
    final editAction = IconButton(
      key: ValueKey('progress-weight-edit-${entry.id}'),
      tooltip: 'Edit weight log',
      onPressed: _editingWeightId == null && !_mutationNeedsReconcile
          ? () => _openWeightEditor(entry)
          : null,
      constraints: const BoxConstraints(
        minWidth: TioSize.dp40,
        minHeight: TioSize.dp40,
      ),
      padding: EdgeInsets.zero,
      icon: Container(
        key: ValueKey('progress-weight-edit-circle-${entry.id}'),
        width: TioSize.dp36,
        height: TioSize.dp36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.edit_outlined,
          size: TioSize.dp16,
          color: colors.textSecondary,
        ),
      ),
    );
    // Trailing group must read: New low/high → delta → circular pencil.
    // No status badge is placed before the recorded weight.
    final trailingActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recordLabel != null) ...[
          _timelineBadge(
            context,
            label: recordLabel,
            key: ValueKey('progress-weight-timeline-record-${entry.id}'),
            foreground: colors.success,
            background: colors.success.withValues(alpha: TioOpacity.opacity12),
            semantics: 'Latest goal-directed weight record: $recordLabel',
          ),
          const SizedBox(width: TioSpacing.xs),
        ],
        if (item.deltaKg != null) ...[
          _timelineChangeBadge(context, item, goalType),
          const SizedBox(width: TioSpacing.xs),
        ],
        editAction,
      ],
    );
    final card = TioCard(
      variant: TioCardVariant.normal,
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.sm,
        vertical: TioSpacing.xxs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow layouts place the whole ordered action group on one
          // trailing line, retaining the complete weight and kg/lb units.
          if (stackTimelineBadges(
            constraints.maxWidth - 2 * TioStroke.width05,
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
                const SizedBox(height: TioSpacing.xxs),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailingActions,
                ),
              ],
            );
          }
          return Row(
            children: [
              dateColumn,
              const SizedBox(width: TioSpacing.sm),
              Expanded(child: weightColumn),
              trailingActions,
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
        // Reserve the latest-entry outline inset so highlighted and
        // non-Today entries always share the same height breakpoint.
        final stackBadges = stackTimelineBadges(
          constraints.maxWidth - 2 * TioSpacing.md - 2 * TioStroke.width05,
        );
        final height = TioSize.dp56 +
            (stackBadges ? TioSize.dp44 : 0) +
            math.max(0.0, textScale - 1.0) * TioSize.dp80;
        return SizedBox(
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Long press uses exactly the same guarded editor as the pencil.
            // A short tap and normal vertical scrolling remain unchanged.
            onLongPress: entry.id != null &&
                    _editingWeightId == null &&
                    !_loading &&
                    !_mutationNeedsReconcile
                ? () => _openWeightEditor(entry)
                : null,
            child: DecoratedBox(
              key: ValueKey('progress-weight-history-${entry.id!}'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TioCardTokens.radius),
                border: item.isLatestEligible
                    ? Border.all(color: colors.progress, width: TioStroke.width05)
                    : null,
              ),
              // Outline does not increase overall card height.
              child: Padding(
                padding: item.isLatestEligible
                    ? const EdgeInsets.all(TioStroke.width05)
                    : EdgeInsets.zero,
                child: card,
              ),
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
            horizontal: TioSpacing.xs,
            vertical: TioSpacing.xxs,
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

  // Compact, locale-aware axis dates (e.g. Oct 26, not Mon, Oct 26).
  String _dateLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatShortMonthDay(date.toLocal());
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

/// Chart-local, touch-held inspection of canonical recorded measurements.
/// The selected position is never interpreted as a new/interpolated weight.
class _WeightChartInspector extends StatefulWidget {
  const _WeightChartInspector({
    required this.entries,
    required this.scale,
    required this.targetKg,
    required this.unit,
    required this.lineColor,
    required this.targetColor,
    required this.cursorColor,
    required this.surfaceColor,
    required this.textColor,
    required this.painter,
    super.key,
  });

  final List<BodyWeightEntry> entries; // measuredAt descending
  final _WeightChartScale scale;
  final double? targetKg;
  final WeightUnit unit;
  final Color lineColor;
  final Color targetColor;
  final Color cursorColor;
  final Color surfaceColor;
  final Color textColor;
  final _RecordedWeightPainter painter;

  @override
  State<_WeightChartInspector> createState() => _WeightChartInspectorState();
}

class _WeightChartInspectorState extends State<_WeightChartInspector> {
  int? _selection;

  @override
  void didUpdateWidget(covariant _WeightChartInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entries, widget.entries) ||
        oldWidget.unit != widget.unit ||
        oldWidget.targetKg != widget.targetKg) {
      _selection = null;
    }
  }

  double _xFor(BodyWeightEntry entry, double width) {
    const left = TioSize.dp8;
    final right = width - TioSize.dp8;
    final oldUs = widget.entries.last.measuredAt.microsecondsSinceEpoch;
    final newUs = widget.entries.first.measuredAt.microsecondsSinceEpoch;
    final interval = newUs - oldUs;
    if (interval <= 0 || right <= left) return (left + right) / 2;
    return left +
        (entry.measuredAt.microsecondsSinceEpoch - oldUs) /
            interval * (right - left);
  }

  void _inspect(double localX, double width) {
    final entries = widget.entries;
    if (entries.isEmpty || width <= 2 * TioSize.dp8) return;
    final oldest = entries.last.measuredAt.microsecondsSinceEpoch;
    final newest = entries.first.measuredAt.microsecondsSinceEpoch;
    final fraction = ((localX - TioSize.dp8) /
        (width - 2 * TioSize.dp8)).clamp(0.0, 1.0);
    final us = oldest + ((newest - oldest) * fraction).round();
    // Binary search over descending actual timestamps, O(log n) per move.
    var lo = 0, hi = entries.length;
    while (lo < hi) {
      final mid = lo + (hi - lo) ~/ 2;
      if (entries[mid].measuredAt.microsecondsSinceEpoch > us) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    var closest = lo == 0
        ? 0 : lo == entries.length
            ? entries.length - 1
            : entries[lo - 1].measuredAt.microsecondsSinceEpoch - us <=
                    us - entries[lo].measuredAt.microsecondsSinceEpoch
                ? lo - 1 : lo;
    // Same-instant entries share the same x; prefer canonical newer ID.
    while (closest > 0 &&
        entries[closest - 1].measuredAt.isAtSameMomentAs(
          entries[closest].measuredAt,
        )) {
      closest--;
    }
    if (_selection != closest) setState(() => _selection = closest);
  }

  void _dismiss() {
    if (_selection != null) setState(() => _selection = null);
  }

  Widget _detailChip(
    BuildContext context, {
    required String key,
    required String dateLabel,
    required double valueKg,
    required Color dotColor,
  }) {
    final type = Theme.of(context).textTheme.labelSmall;
    return Container(
      key: ValueKey(key),
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.xs,
        vertical: TioSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(TioRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: TioSize.dp8,
            height: TioSize.dp8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TioSpacing.xs),
          Flexible(
            child: Text(
              '$dateLabel:',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type?.copyWith(color: widget.textColor),
            ),
          ),
          const SizedBox(width: TioSpacing.xs),
          Text(
            UnitFormatters.formatWeight(valueKg, widget.unit),
            maxLines: 1,
            style: type?.copyWith(
              color: widget.textColor,
              fontWeight: TioFontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final picked = _selection != null && _selection! < widget.entries.length
          ? widget.entries[_selection!]
          : null;
      final x = picked == null ? 0.0 : _xFor(picked, width);
      const topInset = TioSize.dp8;
      final bottom = height - topInset;
      final y = picked == null
          ? 0.0
          : bottom - (picked.weightKg - widget.scale.low) /
                (widget.scale.high - widget.scale.low) * (bottom - topInset);
      // Maximum panel width is only a safety bound: the IntrinsicWidth
      // child shrinks to actual chip text instead of occupying 200dp.
      final panelWidth = math.min(
        TioSize.dp200, math.max(0.0, width - 2 * TioSpacing.xs),
      );
      // Actual goal guide geometry matches _RecordedWeightPainter.
      final targetY = widget.targetKg == null
          ? null
          : bottom -
              (widget.targetKg! - widget.scale.low) /
                  (widget.scale.high - widget.scale.low) *
                  (bottom - topInset);
      // Both references share the selected real measurement's date.
      final date = picked == null
          ? ''
          : DateFormat('d MMM', Localizations.localeOf(context).toString())
              .format(picked.measuredAt.toLocal());
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (event) => _inspect(event.localPosition.dx, width),
        onTapUp: (_) => _dismiss(),
        onTapCancel: _dismiss,
        onLongPressStart: (event) =>
            _inspect(event.localPosition.dx, width),
        onLongPressMoveUpdate: (event) =>
            _inspect(event.localPosition.dx, width),
        onLongPressEnd: (_) => _dismiss(),
        onLongPressCancel: _dismiss,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            CustomPaint(
              key: const ValueKey('progress-weight-chart'),
              painter: widget.painter,
            ),
            if (picked != null) ...[
              Positioned(
                top: topInset,
                bottom: topInset,
                left: x,
                child: IgnorePointer(
                  child: Container(
                    key: const ValueKey('progress-weight-chart-cursor'),
                    width: TioStroke.width1,
                    color: widget.cursorColor.withValues(
                      alpha: TioOpacity.opacity70,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x - TioSize.dp4,
                top: y - TioSize.dp4,
                child: IgnorePointer(
                  child: Container(
                    key: const ValueKey('progress-weight-chart-selected-marker'),
                    width: TioSize.dp8,
                    height: TioSize.dp8,
                    decoration: BoxDecoration(
                      color: widget.lineColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Two independently anchored pills: recorded weight at its
              // exact measured point and target at the dashed target guide.
              // Layout uses their real rendered sizes, so the left-flipped
              // pills remain just 8dp from the cursor rather than 200dp.
              Positioned.fill(
                child: IgnorePointer(
                  child: Semantics(
                    liveRegion: true,
                    label: '$date recorded '
                        '${UnitFormatters.formatWeight(picked.weightKg, widget.unit)}'
                        '${widget.targetKg == null ? "" : ", target reference at $date: ${UnitFormatters.formatWeight(widget.targetKg!, widget.unit)}"}',
                    child: CustomMultiChildLayout(
                      delegate: _WeightTooltipLayoutDelegate(
                        cursorX: x,
                        recordedY: y,
                        targetY: targetY,
                        maxWidth: panelWidth,
                      ),
                      children: [
                        LayoutId(
                          id: 'recorded',
                          child: IntrinsicWidth(
                            key: const ValueKey('progress-weight-chart-tooltip'),
                            child: _detailChip(
                              context,
                              key: 'progress-weight-chart-tooltip-recorded',
                              dateLabel: date,
                              valueKg: picked.weightKg,
                              dotColor: widget.lineColor,
                            ),
                          ),
                        ),
                        if (widget.targetKg != null)
                          LayoutId(
                            id: 'target',
                            child: IntrinsicWidth(
                              child: _detailChip(
                                context,
                                key: 'progress-weight-chart-tooltip-target',
                                dateLabel: date,
                                valueKg: widget.targetKg!,
                                dotColor: widget.targetColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Positions tooltip chips against their own actual chart Y coordinates.
/// Exact child widths place either side 8dp from the selected cursor.
/// Closely spaced weight/goal points shift minimally to avoid chip overlap.
class _WeightTooltipLayoutDelegate extends MultiChildLayoutDelegate {
  _WeightTooltipLayoutDelegate({
    required this.cursorX,
    required this.recordedY,
    required this.targetY,
    required this.maxWidth,
  });

  final double cursorX;
  final double recordedY;
  final double? targetY;
  final double maxWidth;

  @override
  void performLayout(Size size) {
    final availableWidth = math.max(
      0.0, math.min(maxWidth, size.width - 2 * TioSpacing.xs),
    );
    final chipConstraints = BoxConstraints.loose(
      Size(availableWidth, size.height),
    );
    final recorded = layoutChild('recorded', chipConstraints);
    final target = hasChild('target')
        ? layoutChild('target', chipConstraints)
        : null;

    double topFor(double center, Size chip) => math.max(
      0.0,
      math.min(center - chip.height / 2, size.height - chip.height),
    );
    var recordedTop = topFor(recordedY, recorded);
    var targetTop = target == null
        ? 0.0
        : topFor(targetY!, target);

    if (target != null) {
      // Keep both centered on their own points when there is room.
      // Otherwise move each by half the collision and translate the pair
      // back into the 120dp plot without swapping their vertical order.
      final recordedAbove = recordedY <= targetY!;
      var firstTop = recordedAbove ? recordedTop : targetTop;
      var secondTop = recordedAbove ? targetTop : recordedTop;
      final first = recordedAbove ? recorded : target;
      final second = recordedAbove ? target : recorded;
      final overlap =
          firstTop + first.height + TioSpacing.xxs - secondTop;
      if (overlap > 0) {
        firstTop -= overlap / 2;
        secondTop += overlap / 2;
        final moveDown = math.max(0.0, -firstTop);
        firstTop += moveDown;
        secondTop += moveDown;
        final moveUp = math.max(
          0.0, secondTop + second.height - size.height,
        );
        firstTop -= moveUp;
        secondTop -= moveUp;
      }
      recordedTop = recordedAbove ? firstTop : secondTop;
      targetTop = recordedAbove ? secondTop : firstTop;
    }

    final widest = math.max(
      recorded.width, target?.width ?? 0,
    );
    final canFitRight =
        cursorX + TioSpacing.sm + widest <= size.width - TioSpacing.xs;
    final canFitLeft =
        cursorX - TioSpacing.sm - widest >= TioSpacing.xs;
    final putRight = canFitRight || !canFitLeft;

    double leftFor(Size child) {
      final desired = putRight
          ? cursorX + TioSpacing.sm
          : cursorX - TioSpacing.sm - child.width;
      return math.max(
        TioSpacing.xs,
        math.min(desired, size.width - child.width - TioSpacing.xs),
      );
    }

    positionChild('recorded', Offset(leftFor(recorded), recordedTop));
    if (target != null) {
      positionChild('target', Offset(leftFor(target), targetTop));
    }
  }

  @override
  bool shouldRelayout(covariant _WeightTooltipLayoutDelegate old) =>
      old.cursorX != cursorX ||
      old.recordedY != recordedY ||
      old.targetY != targetY ||
      old.maxWidth != maxWidth;
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
    // Leave the last measurement dot inset, but extend horizontal guides
    // flush to the numeric Y-axis; points must not be clipped at the edge.
    final right = size.width - TioSize.dp8;
    final guideRight = size.width;
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
      canvas.drawLine(
        Offset(left, height), Offset(guideRight, height), grid,
      );
    }
    if (targetKg != null) {
      final goalY = y(targetKg!);
      final goalPaint = Paint()
        ..color = targetColor
        ..strokeWidth = TioStroke.width2;
      for (var position = left;
          position < guideRight;
          position += TioSize.dp12) {
        canvas.drawLine(
          Offset(position, goalY),
          Offset(math.min(position + TioSize.dp8, guideRight), goalY),
          goalPaint,
        );
      }
      final targetLabel = TextPainter(
        text: TextSpan(
          text: 'YOUR TARGET',
          style: TextStyle(
            color: targetColor,
            fontSize: TioFontSize.size10_5,
            fontWeight: TioFontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      targetLabel.paint(
        canvas,
        Offset(
          math.max(left, right - targetLabel.width - TioSpacing.xs),
          math.max(top, math.min(bottom - targetLabel.height,
              goalY - targetLabel.height - TioSpacing.xs)),
        ),
      );
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
