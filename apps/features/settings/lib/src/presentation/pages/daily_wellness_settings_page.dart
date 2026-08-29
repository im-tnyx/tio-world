import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';

import '../../domain/hydration_preferences.dart';
import '../widgets/daily_wellness_editor_sheet.dart';
import '../widgets/glass_size_bottom_sheet.dart';

/// Sleep duration is a pure function of Bedtime/Wake Time, never an
/// independent target. Null when either side of the schedule is unset —
/// never fabricated. Dart's `%` on int is Euclidean (always non-negative
/// for a positive divisor), so this handles the schedule wrapping past
/// midnight without a branch.
int? _computeSleepDuration(int? bed, int? wake) {
  if (bed == null || wake == null) return null;
  return (wake - bed) % (24 * 60);
}

/// Compact duration format for the derived Sleep Schedule summary:
/// "48 min", "7h", "7h 30m", "8h 15m". Deliberately not decimal hours.
String _formatSleepDuration(int? totalMinutes) {
  if (totalMinutes == null) return 'Not set';
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (hours == 0) return '$mins min';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

String _formatTimeOfDay(BuildContext context, int? totalMinutes) {
  if (totalMinutes == null) return 'Not set';
  final time = TimeOfDay(
    hour: (totalMinutes ~/ 60) % 24,
    minute: totalMinutes % 60,
  );
  return time.format(context);
}

class DailyWellnessSettingsPage extends StatefulWidget {
  const DailyWellnessSettingsPage({
    this.initialTargets,
    this.volumeUnit = VolumeUnit.ml,
    this.hydrationPreferences,
    this.onSaveHydration,
    this.hydrationLoading = false,
    this.hydrationLoadFailed = false,
    this.onRetryHydration,
    required this.onSave,
    super.key,
  });

  final WellnessTargetsData? initialTargets;
  final VolumeUnit volumeUnit;
  final HydrationPreferences? hydrationPreferences;
  final Future<void> Function(HydrationPreferences)? onSaveHydration;
  final bool hydrationLoading;
  final bool hydrationLoadFailed;
  final VoidCallback? onRetryHydration;
  final Future<void> Function(WellnessTargetsData targets) onSave;

  @override
  State<DailyWellnessSettingsPage> createState() =>
      _DailyWellnessSettingsPageState();
}

class _DailyWellnessSettingsPageState extends State<DailyWellnessSettingsPage> {
  late final ValueNotifier<HydrationPreferences> _glassCanonical;
  late final ValueNotifier<VolumeUnit> _glassVolumeUnit;
  late HydrationPreferences _glassPreferences;

  int? _dailySteps;
  int? _waterMl;
  int? _sleepTargetMinutes;
  int? _bedTimeMinutes;
  int? _wakeTimeMinutes;

  // Each flag tracks whether its field's local draft currently diverges from
  // the latest canonical value. It is recomputed on every edit AND on every
  // canonical refresh (didUpdateWidget), never latched permanently — so a
  // dirty field whose draft happens to match a newly arrived canonical value
  // converges back to non-dirty and stays eligible for future hydration,
  // instead of blocking every later refresh just because it once diverged.
  //
  // There is no _dirtySleep: sleepTargetMinutes is never independently
  // edited. It is always derived from Bedtime + Wake Time (see
  // _computeSleepDuration), so its "dirtiness" is fully implied by
  // _dirtyBedtime / _dirtyWakeTime.
  var _dirtySteps = false;
  var _dirtyWater = false;
  var _dirtyBedtime = false;
  var _dirtyWakeTime = false;

  var _isSaving = false;
  String? _errorMessage;

  bool get _hasChanges =>
      _dirtySteps || _dirtyWater || _dirtyBedtime || _dirtyWakeTime;

  @override
  void initState() {
    super.initState();
    _glassPreferences =
        widget.hydrationPreferences ?? const HydrationPreferences();
    _glassCanonical = ValueNotifier(_glassPreferences);
    _glassVolumeUnit = ValueNotifier(widget.volumeUnit);
    _dailySteps = widget.initialTargets?.dailySteps;
    _waterMl = widget.initialTargets?.waterMl;
    _bedTimeMinutes = widget.initialTargets?.bedTimeMinutes;
    _wakeTimeMinutes = widget.initialTargets?.wakeTimeMinutes;
    _sleepTargetMinutes =
        _computeSleepDuration(_bedTimeMinutes, _wakeTimeMinutes);
  }

  @override
  void didUpdateWidget(covariant DailyWellnessSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hydrationLoading &&
        !widget.hydrationLoadFailed &&
        (oldWidget.hydrationPreferences != widget.hydrationPreferences ||
            oldWidget.hydrationLoading ||
            oldWidget.hydrationLoadFailed)) {
      _glassPreferences =
          widget.hydrationPreferences ?? const HydrationPreferences();
    }
    // A modal is a separate route: notify it after this page finishes building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _glassCanonical.value = _glassPreferences;
      _glassVolumeUnit.value = widget.volumeUnit;
    });
    if (oldWidget.initialTargets == widget.initialTargets) return;

    final newInit = widget.initialTargets;

    if (_dirtySteps) {
      _dirtySteps = _dailySteps != newInit?.dailySteps;
    } else {
      _dailySteps = newInit?.dailySteps;
    }

    if (_dirtyWater) {
      _dirtyWater = _waterMl != newInit?.waterMl;
    } else {
      _waterMl = newInit?.waterMl;
    }

    if (_dirtyBedtime) {
      _dirtyBedtime = _bedTimeMinutes != newInit?.bedTimeMinutes;
    } else {
      _bedTimeMinutes = newInit?.bedTimeMinutes;
    }

    if (_dirtyWakeTime) {
      _dirtyWakeTime = _wakeTimeMinutes != newInit?.wakeTimeMinutes;
    } else {
      _wakeTimeMinutes = newInit?.wakeTimeMinutes;
    }

    _sleepTargetMinutes =
        _computeSleepDuration(_bedTimeMinutes, _wakeTimeMinutes);
  }

  String _formatSteps() {
    if (_dailySteps == null) return 'Not set';
    final grouped = _dailySteps!.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
    return '$grouped steps';
  }

  @override
  void dispose() {
    _glassCanonical.dispose();
    _glassVolumeUnit.dispose();
    super.dispose();
  }

  Future<void> _pickGlassSize() async {
    final save = widget.onSaveHydration;
    if (save == null || widget.hydrationLoading || widget.hydrationLoadFailed) {
      return;
    }
    final saved = await showDailyWellnessEditorSheet<HydrationPreferences>(
      context: context,
      builder: (context) => GlassSizeBottomSheet(
        canonical: _glassCanonical,
        volumeUnit: _glassVolumeUnit,
        onSave: save,
      ),
    );
    if (mounted && saved != null) {
      setState(() => _glassPreferences = saved);
      _glassCanonical.value = saved;
    }
  }

  String _glassSummary() {
    if (widget.hydrationLoading) return 'Loading…';
    if (widget.hydrationLoadFailed) return 'Could not load Glass Size';
    if (widget.onSaveHydration == null) return 'Unavailable';
    return formatGlassSize(
        _glassPreferences.defaultGlassSizeMl, widget.volumeUnit);
  }

  String _formatWater() {
    if (_waterMl == null) return 'Not set';
    if (widget.volumeUnit == VolumeUnit.flOz) {
      final oz = UnitConverters.mlToFlOz(_waterMl!.toDouble()).round();
      return '$oz fl oz';
    }
    final formatted = UnitFormatters.formatVolume(
      _waterMl!.toDouble(),
      VolumeUnit.ml,
      decimals: 1,
    );
    return formatted;
  }

  Future<void> _pickSteps() async {
    final current = _dailySteps ?? 10000;
    var tempValue = current.clamp(2000, 18000).toInt();
    final colors = context.tioColors;

    final result = await showDailyWellnessEditorSheet<int?>(
      context: context,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateDraft(double value) {
              final snapped = (value / 500).round() * 500;
              if (snapped == tempValue) return;
              HapticFeedback.selectionClick();
              setModalState(() => tempValue = snapped);
            }

            return DailyWellnessEditorSheet(
              title: 'Daily Step Goal',
              supportingText: 'Recommended: 10,000 steps/day',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      '$tempValue steps',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: TioFontWeight.w800,
                        fontSize: TioFontSize.size24,
                      ),
                    ),
                  ),
                  Slider(
                    key: const ValueKey('daily-wellness-steps-slider'),
                    value: tempValue.toDouble(),
                    min: 2000,
                    max: 18000,
                    divisions: 32,
                    activeColor: colors.primary,
                    onChanged: updateDraft,
                  ),
                ],
              ),
              actions: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(modalContext).pop(-1),
                      child: Text(
                        'Clear Goal',
                        style: TextStyle(color: colors.danger),
                      ),
                    ),
                  ),
                  const SizedBox(width: TioSpacing.md),
                  Expanded(
                    child: TioButton.primary(
                      label: 'Set Goal',
                      onPressed: () =>
                          Navigator.of(modalContext).pop(tempValue),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _dailySteps = result == -1 ? null : result;
        _dirtySteps = _dailySteps != widget.initialTargets?.dailySteps;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickWater() async {
    final current = _waterMl ?? 2500;
    var tempValue = current.clamp(1000, 8000).toInt();
    final colors = context.tioColors;

    final result = await showDailyWellnessEditorSheet<int?>(
      context: context,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isFlOz = widget.volumeUnit == VolumeUnit.flOz;
            final displayQty = isFlOz
                ? '${UnitConverters.mlToFlOz(tempValue.toDouble()).round()} fl oz'
                : '$tempValue ml (${UnitFormatters.formatVolume(tempValue.toDouble(), VolumeUnit.ml, decimals: 1)})';

            void updateDraft(double value) {
              final snapped = (value / 100).round() * 100;
              if (snapped == tempValue) return;
              HapticFeedback.selectionClick();
              setModalState(() => tempValue = snapped);
            }

            return DailyWellnessEditorSheet(
              title: 'Daily Water Goal',
              supportingText: 'Recommended: 2,000 - 4,000 ml/day',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      displayQty,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: TioFontWeight.w800,
                        fontSize: TioFontSize.size24,
                      ),
                    ),
                  ),
                  Slider(
                    key: const ValueKey('daily-wellness-water-slider'),
                    value: tempValue.toDouble(),
                    min: 1000,
                    max: 8000,
                    divisions: 70,
                    activeColor: colors.primary,
                    onChanged: updateDraft,
                  ),
                ],
              ),
              actions: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(modalContext).pop(-1),
                      child: Text(
                        'Clear Goal',
                        style: TextStyle(color: colors.danger),
                      ),
                    ),
                  ),
                  const SizedBox(width: TioSpacing.md),
                  Expanded(
                    child: TioButton.primary(
                      label: 'Set Goal',
                      onPressed: () =>
                          Navigator.of(modalContext).pop(tempValue),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _waterMl = result == -1 ? null : result;
        _dirtyWater = _waterMl != widget.initialTargets?.waterMl;
        _errorMessage = null;
      });
    }
  }

  /// Combined Bedtime + Wake Time editor. Both times are edited as local
  /// temporary state inside the sheet; nothing on the page commits unless
  /// the user taps "Save Schedule" — dismissing/backing out of the sheet
  /// leaves the page's Bedtime/Wake Time/derived duration untouched.
  Future<void> _pickSleepSchedule() async {
    final colors = context.tioColors;

    final result = await showModalBottomSheet<(int?, int?)>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TioRadius.lg),
        ),
      ),
      builder: (_) => _SleepScheduleBottomSheet(
        initialBedTime: _bedTimeMinutes,
        initialWakeTime: _wakeTimeMinutes,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _bedTimeMinutes = result.$1;
        _wakeTimeMinutes = result.$2;
        _dirtyBedtime = _bedTimeMinutes != widget.initialTargets?.bedTimeMinutes;
        _dirtyWakeTime =
            _wakeTimeMinutes != widget.initialTargets?.wakeTimeMinutes;
        _sleepTargetMinutes =
            _computeSleepDuration(_bedTimeMinutes, _wakeTimeMinutes);
        _errorMessage = null;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_hasChanges) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final targets = WellnessTargetsData(
        dailySteps: _dailySteps,
        waterMl: _waterMl,
        sleepTargetMinutes: _sleepTargetMinutes,
        bedTimeMinutes: _bedTimeMinutes,
        wakeTimeMinutes: _wakeTimeMinutes,
      );
      targets.validate();
      await widget.onSave(targets);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage =
            'Could not save your wellness targets. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Daily Wellness',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.lg,
                  TioSpacing.md,
                  TioSpacing.lg,
                  TioSpacing.xl,
                ),
                children: [
                  Text(
                    'Set and adjust your daily targets for movement, hydration, sleep duration, and schedule.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size14,
                      height: TioLineHeight.height145,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.xl),

                  // ── MOVEMENT GROUP ──
                  const _DailyWellnessSectionHeader(title: 'MOVEMENT'),
                  _DailyWellnessGroupCard(
                    key: const ValueKey('daily-wellness-movement-card'),
                    children: [
                      _DailyWellnessRow(
                        key: const ValueKey('daily-wellness-steps-field'),
                        icon: Icons.directions_walk_rounded,
                        label: 'Step Goal',
                        value: _formatSteps(),
                        isUnset: _dailySteps == null,
                        onTap: _pickSteps,
                      ),
                    ],
                  ),
                  const SizedBox(height: TioSpacing.lg),
                  const _DailyWellnessSectionHeader(title: 'HYDRATION'),
                  _DailyWellnessGroupCard(
                    key: const ValueKey('daily-wellness-hydration-card'),
                    children: [
                      _DailyWellnessRow(
                        key: const ValueKey('daily-wellness-water-field'),
                        icon: Icons.water_drop_outlined,
                        label: 'Water Goal',
                        value: _formatWater(),
                        isUnset: _waterMl == null,
                        onTap: _pickWater,
                      ),
                      const _DailyWellnessDivider(
                        key: ValueKey('daily-wellness-hydration-divider'),
                      ),
                      _DailyWellnessRow(
                        key: const ValueKey('daily-wellness-glass-size-field'),
                        icon: Icons.local_drink_outlined,
                        label: 'Glass Size',
                        value: _glassSummary(),
                        isUnset: false,
                        onTap: widget.onSaveHydration == null ||
                                widget.hydrationLoading ||
                                widget.hydrationLoadFailed
                            ? null
                            : _pickGlassSize,
                      ),
                      if (widget.hydrationLoadFailed &&
                          widget.onRetryHydration != null)
                        TextButton(
                          key: const ValueKey('glass-size-load-retry'),
                          onPressed: widget.onRetryHydration,
                          child: const Text('Retry Glass Size'),
                        ),
                    ],
                  ),

                  const SizedBox(height: TioSpacing.lg),

                  // ── SLEEP GROUP ──
                  const _DailyWellnessSectionHeader(title: 'SLEEP'),
                  _SleepScheduleSummaryCard(
                    key: const ValueKey('daily-wellness-sleep-card'),
                    durationMinutes: _sleepTargetMinutes,
                    bedTimeMinutes: _bedTimeMinutes,
                    wakeTimeMinutes: _wakeTimeMinutes,
                    onTap: _pickSleepSchedule,
                  ),
                ],
              ),
            ),

            // ── SAVE BAR ──
            Container(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.md,
                TioSpacing.lg,
                TioSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineStrong.withAlpha(TioAlpha.alpha24),
                    width: TioStroke.width1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _errorMessage!,
                          key: const ValueKey('daily-wellness-save-error'),
                          style: TextStyle(
                            color: colors.danger,
                            fontSize: TioFontSize.size13,
                            fontWeight: TioFontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: TioSpacing.md),
                    ],
                    TioButton.primary(
                      key: const ValueKey('daily-wellness-save'),
                      label: 'Save Changes',
                      onPressed: _hasChanges && !_isSaving ? _save : null,
                      loading: _isSaving,
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyWellnessSectionHeader extends StatelessWidget {
  const _DailyWellnessSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.only(
        left: TioSpacing.sm,
        bottom: TioSpacing.sm,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontWeight: TioFontWeight.w700,
          fontSize: TioFontSize.size11,
          letterSpacing: TioLetterSpacing.positive08,
        ),
      ),
    );
  }
}

class _DailyWellnessGroupCard extends StatelessWidget {
  const _DailyWellnessGroupCard({
    required this.children,
    super.key,
  });
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _DailyWellnessDivider extends StatelessWidget {
  const _DailyWellnessDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioStroke.width1,
      indent: TioSize.dp64,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}

class _DailyWellnessRow extends StatelessWidget {
  const _DailyWellnessRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isUnset,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Explicit unset styling contract instead of sniffing `value == 'Not set'`.
  final bool isUnset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md + TioSize.dp4,
        ),
        child: Row(
          children: [
            Container(
              width: TioSize.dp40,
              height: TioSize.dp40,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(TioAlpha.alpha18),
                borderRadius: BorderRadius.circular(TioRadius.sm),
              ),
              child: Icon(
                icon,
                size: TioSize.dp22,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Flexible(
              flex: 2,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: isUnset ? colors.textMuted : colors.textSecondary,
                  fontSize: TioFontSize.size13,
                  fontWeight:
                      isUnset ? TioFontWeight.w400 : TioFontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: TioSize.dp20,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dedicated Sleep Schedule summary presentation — deliberately not built on
/// [_DailyWellnessRow], since its two-row hierarchy (duration on the same
/// line as the title; range + edit affordance on a second line) doesn't fit
/// that generic single-value-line row shape.
class _SleepScheduleSummaryCard extends StatelessWidget {
  const _SleepScheduleSummaryCard({
    required this.durationMinutes,
    required this.bedTimeMinutes,
    required this.wakeTimeMinutes,
    required this.onTap,
    super.key,
  });

  final int? durationMinutes;
  final int? bedTimeMinutes;
  final int? wakeTimeMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isUnset = durationMinutes == null;
    final hasAnyTime = bedTimeMinutes != null || wakeTimeMinutes != null;
    final rangeText = hasAnyTime
        ? '${_formatTimeOfDay(context, bedTimeMinutes)} - ${_formatTimeOfDay(context, wakeTimeMinutes)}'
        : 'Set your bedtime and wake time';

    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('daily-wellness-sleep-schedule-field'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSpacing.md + TioSize.dp4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: TioSize.dp40,
                    height: TioSize.dp40,
                    decoration: BoxDecoration(
                      color: colors.primary.withAlpha(TioAlpha.alpha18),
                      borderRadius: BorderRadius.circular(TioRadius.sm),
                    ),
                    child: Icon(
                      Icons.bedtime_outlined,
                      size: TioSize.dp22,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.lg),
                  Expanded(
                    child: Text(
                      'Sleep Schedule',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioFontSize.size15,
                      ),
                    ),
                  ),
                  Text(
                    _formatSleepDuration(durationMinutes),
                    style: TextStyle(
                      color: isUnset ? colors.textMuted : colors.primary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TioSpacing.sm),
              Row(
                children: [
                  const SizedBox(width: TioSize.dp40 + TioSpacing.lg),
                  Expanded(
                    child: Text(
                      rangeText,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: TioFontSize.size13,
                        fontWeight: TioFontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: TioSize.dp18,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SleepScheduleHandle { bed, wake }

/// Dedicated Sleep Schedule editor: a 24-hour horizontal timeline (displayed
/// 20:00 -> next 20:00, so a typical overnight schedule renders as one
/// contiguous highlighted interval) with two independently draggable
/// handles. Dragging is the primary interaction; tapping the large time
/// values opens the platform time picker as a secondary, precise path. Both
/// paths update the same temporary state, which only commits to the page
/// when "Save Schedule" is tapped.
class _SleepScheduleBottomSheet extends StatefulWidget {
  const _SleepScheduleBottomSheet({
    required this.initialBedTime,
    required this.initialWakeTime,
  });

  final int? initialBedTime;
  final int? initialWakeTime;

  @override
  State<_SleepScheduleBottomSheet> createState() =>
      _SleepScheduleBottomSheetState();
}

class _SleepScheduleBottomSheetState
    extends State<_SleepScheduleBottomSheet> {
  static const _timelineStartMinutes = 20 * 60;
  static const _defaultBedTime = 22 * 60; // 10:00 PM
  static const _defaultWakeTime = 6 * 60 + 30; // 6:30 AM
  static const _snapMinutes = 15;
  static const _minutesPerDay = 24 * 60;

  int? _bedTime;
  int? _wakeTime;
  _SleepScheduleHandle? _draggingHandle;

  @override
  void initState() {
    super.initState();
    _bedTime = widget.initialBedTime;
    _wakeTime = widget.initialWakeTime;
  }

  int get _renderBedTime => _bedTime ?? _defaultBedTime;
  int get _renderWakeTime => _wakeTime ?? _defaultWakeTime;

  static double _fractionOf(int minuteOfDay) =>
      ((minuteOfDay - _timelineStartMinutes + _minutesPerDay) %
          _minutesPerDay) /
      _minutesPerDay;

  int _snap(int minuteOfDay) {
    final snapped =
        (minuteOfDay / _snapMinutes).round() * _snapMinutes % _minutesPerDay;
    return snapped < 0 ? snapped + _minutesPerDay : snapped;
  }

  void _setFromFraction(double fraction, _SleepScheduleHandle handle) {
    final positionMinutes = (fraction.clamp(0.0, 1.0) * _minutesPerDay).round();
    final absolute = _snap(positionMinutes + _timelineStartMinutes);
    final previous =
        handle == _SleepScheduleHandle.bed ? _bedTime : _wakeTime;
    // Fire exactly once per crossing into a different snapped 15-minute
    // value — never on every raw pointer update, and never merely for
    // touching/selecting a handle (the down event's own value is usually
    // unchanged from the handle's current position, so it stays silent).
    if (previous != absolute) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      if (handle == _SleepScheduleHandle.bed) {
        _bedTime = absolute;
      } else {
        _wakeTime = absolute;
      }
    });
  }

  void _adjust(_SleepScheduleHandle handle, int deltaMinutes) {
    final current =
        handle == _SleepScheduleHandle.bed ? _renderBedTime : _renderWakeTime;
    final next = _snap(current + deltaMinutes);
    setState(() {
      if (handle == _SleepScheduleHandle.bed) {
        _bedTime = next;
      } else {
        _wakeTime = next;
      }
    });
  }

  void _handlePanDown(Offset localPosition, double width) {
    final bedX = _fractionOf(_renderBedTime) * width;
    final wakeX = _fractionOf(_renderWakeTime) * width;
    _draggingHandle = (localPosition.dx - bedX).abs() <=
            (localPosition.dx - wakeX).abs()
        ? _SleepScheduleHandle.bed
        : _SleepScheduleHandle.wake;
    _setFromFraction(localPosition.dx / width, _draggingHandle!);
  }

  void _handlePanMove(Offset localPosition, double width) {
    final handle = _draggingHandle;
    if (handle == null) return;
    _setFromFraction(localPosition.dx / width, handle);
  }

  Future<void> _pickPreciseTime(_SleepScheduleHandle handle) async {
    final current =
        handle == _SleepScheduleHandle.bed ? _renderBedTime : _renderWakeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (handle == _SleepScheduleHandle.bed) {
        _bedTime = minutes;
      } else {
        _wakeTime = minutes;
      }
    });
  }

  Widget _largeTimeValue({
    required String label,
    required int? minutes,
    required _SleepScheduleHandle handle,
  }) {
    final colors = context.tioColors;
    return Expanded(
      child: InkWell(
        onTap: () => _pickPreciseTime(handle),
        borderRadius: BorderRadius.circular(TioRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioFontSize.size13,
                  fontWeight: TioFontWeight.w600,
                ),
              ),
              const SizedBox(height: TioSpacing.xs),
              Text(
                _formatTimeOfDay(context, minutes),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w800,
                  fontSize: TioFontSize.size24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeline(BuildContext context) {
    final colors = context.tioColors;
    final bedFraction = _fractionOf(_renderBedTime);
    final wakeFraction = _fractionOf(_renderWakeTime);

    const labelHours = [20, 0, 4, 8, 12, 16, 20];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bedX = bedFraction * width;
        final wakeX = wakeFraction * width;

        final highlights = <({double left, double width})>[
          if (wakeFraction >= bedFraction)
            (left: bedX, width: wakeX - bedX)
          else ...[
            (left: bedX, width: width - bedX),
            (left: 0.0, width: wakeX),
          ],
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              key: const ValueKey('sleep-schedule-timeline-track'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragDown: (details) =>
                  _handlePanDown(details.localPosition, width),
              onHorizontalDragUpdate: (details) =>
                  _handlePanMove(details.localPosition, width),
              onHorizontalDragEnd: (_) => _draggingHandle = null,
              child: SizedBox(
                height: TioSize.dp56,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: TioSize.dp26,
                      child: Container(
                        height: TioSize.dp4,
                        decoration: BoxDecoration(
                          color: colors.outlineStrong
                              .withAlpha(TioAlpha.alpha24),
                          borderRadius: BorderRadius.circular(TioSize.dp2),
                        ),
                      ),
                    ),
                    for (final segment in highlights)
                      Positioned(
                        left: segment.left,
                        width: segment.width,
                        top: TioSize.dp26,
                        child: Container(
                          height: TioSize.dp4,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(TioSize.dp2),
                          ),
                        ),
                      ),
                    _timelineHandle(
                      x: bedX,
                      handle: _SleepScheduleHandle.bed,
                      semanticLabel: 'Bedtime handle',
                      semanticValue: _formatTimeOfDay(context, _renderBedTime),
                    ),
                    _timelineHandle(
                      x: wakeX,
                      handle: _SleepScheduleHandle.wake,
                      semanticLabel: 'Wake time handle',
                      semanticValue:
                          _formatTimeOfDay(context, _renderWakeTime),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final hour in labelHours)
                  Text(
                    TimeOfDay(hour: hour, minute: 0).format(context),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: TioFontSize.size11,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _timelineHandle({
    required double x,
    required _SleepScheduleHandle handle,
    required String semanticLabel,
    required String semanticValue,
  }) {
    final colors = context.tioColors;
    const handleSize = TioSize.dp24;
    final current =
        handle == _SleepScheduleHandle.bed ? _renderBedTime : _renderWakeTime;

    return Positioned(
      left: x - handleSize / 2,
      top: TioSize.dp16,
      child: Semantics(
        label: semanticLabel,
        value: semanticValue,
        increasedValue: _formatTimeOfDay(context, _snap(current + _snapMinutes)),
        decreasedValue: _formatTimeOfDay(context, _snap(current - _snapMinutes)),
        onIncrease: () => _adjust(handle, _snapMinutes),
        onDecrease: () => _adjust(handle, -_snapMinutes),
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surfaceRaised, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final previewDuration = _computeSleepDuration(_bedTime, _wakeTime);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: TioSize.dp36,
                height: TioSize.dp4,
                decoration: BoxDecoration(
                  color: colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                  borderRadius: BorderRadius.circular(TioSize.dp2),
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.md),
            Text(
              'Sleep Schedule',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w700,
                fontSize: TioFontSize.size18,
              ),
            ),
            const SizedBox(height: TioSpacing.lg),
            Row(
              children: [
                _largeTimeValue(
                  label: 'Bedtime',
                  minutes: _bedTime,
                  handle: _SleepScheduleHandle.bed,
                ),
                _largeTimeValue(
                  label: 'Wake Time',
                  minutes: _wakeTime,
                  handle: _SleepScheduleHandle.wake,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.sm),
            Center(
              child: Text(
                previewDuration == null
                    ? 'Set both times to see sleep duration'
                    : '${_formatSleepDuration(previewDuration)} planned sleep',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.lg),
            _timeline(context),
            const SizedBox(height: TioSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _bedTime = null;
                        _wakeTime = null;
                      });
                    },
                    child: Text(
                      'Clear Schedule',
                      style: TextStyle(color: colors.danger),
                    ),
                  ),
                ),
                const SizedBox(width: TioSpacing.md),
                Expanded(
                  child: TioButton.primary(
                    label: 'Save Schedule',
                    onPressed: () =>
                        Navigator.of(context).pop((_bedTime, _wakeTime)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
