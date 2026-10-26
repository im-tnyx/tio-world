import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/body_setup.dart';
import 'progress_weight_dashboard_reader.dart';
import 'progress_weight_log_sheet.dart';

// Fixed primary action plus 24dp breathing room on both sides.
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
      final snapshot = await _reader.load(_range);
      if (!mounted || generation != _generation) return;
      setState(() {
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
              for (final entry in _snapshot!.history.entries) ...[
                _historyEntry(context, entry),
                const SizedBox(height: TioSpacing.sm),
              ],
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
    final target = snapshot.goal?.targetWeightKg;
    final chart = snapshot.chartEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Weight summary',
                style: typography.titleLarge,
              ),
            ),
            PopupMenuButton<ProgressWeightRange>(
              key: const ValueKey('progress-weight-range'),
              tooltip: 'Select weight chart range',
              initialValue: _range,
              onSelected: _setRange,
              itemBuilder: (context) => [
                for (final range in ProgressWeightRange.values)
                  PopupMenuItem(value: range, child: Text(range.label)),
              ],
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
          ],
        ),
        const SizedBox(height: TioSpacing.md),
        TioCard(
          variant: TioCardVariant.normal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _stat(
                      context,
                      'CURRENT',
                      current == null
                          ? '—'
                          : UnitFormatters.formatWeight(
                              current.weightKg,
                              widget.unit,
                            ),
                    ),
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: _stat(
                      context,
                      'RANGE CHANGE',
                      delta == null
                          ? 'Not enough history'
                          : _formatChange(delta),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TioSpacing.md),
              if (chart.isEmpty)
                const SizedBox(
                  height: TioSize.dp160,
                  child: Center(
                    child: Text('No measurements in this range'),
                  ),
                )
              else ...[
                Semantics(
                  label: 'Weight trend with ${chart.length} actual measurements '
                      'in ${_range.label}. Individual values are available in History.',
                  child: SizedBox(
                    height: TioSize.dp200,
                    width: double.infinity,
                    child: CustomPaint(
                      key: const ValueKey('progress-weight-chart'),
                      painter: _RecordedWeightPainter(
                        entries: chart,
                        targetKg: target,
                        lineColor: colors.progress,
                        gridColor: colors.outlineStrong,
                        targetColor: colors.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TioSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateLabel(context, chart.last.measuredAt),
                      style: typography.bodySmall,
                    ),
                    Text(
                      _dateLabel(context, chart.first.measuredAt),
                      style: typography.bodySmall,
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
              if (delta == null && chart.isNotEmpty) ...[
                const SizedBox(height: TioSpacing.xs),
                Text(
                  'Two measurements are needed to compare this range.',
                  style: typography.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

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

  Widget _historyEntry(BuildContext context, BodyWeightEntry entry) {
    final typography = Theme.of(context).textTheme;
    final colors = context.tioColors;
    final local = entry.measuredAt.toLocal();
    return TioCard(
      key: ValueKey('progress-weight-history-${entry.id!}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UnitFormatters.formatWeight(entry.weightKg, widget.unit),
            style: typography.titleMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: TioSpacing.xs),
          Text(
            '${_dateLabel(context, local)} at '
                '${TimeOfDay.fromDateTime(local).format(context)}',
            style: typography.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (entry.note != null) ...[
            const SizedBox(height: TioSpacing.xs),
            Text(entry.note!, style: typography.bodyMedium),
          ],
        ],
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
class _RecordedWeightPainter extends CustomPainter {
  const _RecordedWeightPainter({
    required this.entries,
    required this.targetKg,
    required this.lineColor,
    required this.gridColor,
    required this.targetColor,
  });

  final List<BodyWeightEntry> entries;
  final double? targetKg;
  final Color lineColor;
  final Color gridColor;
  final Color targetColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || size.width <= 0 || size.height <= 0) return;
    final ordered = entries.reversed.toList(growable: false);
    var low = ordered.first.weightKg;
    var high = low;
    for (final entry in ordered) {
      low = math.min(low, entry.weightKg);
      high = math.max(high, entry.weightKg);
    }
    if (targetKg != null) {
      low = math.min(low, targetKg!);
      high = math.max(high, targetKg!);
    }
    final pad = (high - low).abs() < 0.01 ? 1.0 : (high - low) * 0.08;
    low -= pad;
    high += pad;

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
        bottom - (weight - low) / (high - low) * (bottom - top);

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
        oldDelegate.targetKg != targetKg ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.targetColor != targetColor;
  }
}
