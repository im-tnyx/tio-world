import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';

class DailyWellnessSettingsPage extends StatefulWidget {
  const DailyWellnessSettingsPage({
    this.initialTargets,
    this.volumeUnit = VolumeUnit.ml,
    required this.onSave,
    super.key,
  });

  final WellnessTargetsData? initialTargets;
  final VolumeUnit volumeUnit;
  final Future<void> Function(WellnessTargetsData targets) onSave;

  @override
  State<DailyWellnessSettingsPage> createState() =>
      _DailyWellnessSettingsPageState();
}

class _DailyWellnessSettingsPageState extends State<DailyWellnessSettingsPage> {
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

  /// Sleep duration is a pure function of Bedtime/Wake Time, never an
  /// independent target. Null when either side of the schedule is unset —
  /// never fabricated. Dart's `%` on int is Euclidean (always non-negative
  /// for a positive divisor), so this handles the schedule wrapping past
  /// midnight without a branch.
  static int? _computeSleepDuration(int? bed, int? wake) {
    if (bed == null || wake == null) return null;
    return (wake - bed) % (24 * 60);
  }

  @override
  void initState() {
    super.initState();
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
    return '$_dailySteps steps/day';
  }

  String _formatWater() {
    if (_waterMl == null) return 'Not set';
    if (widget.volumeUnit == VolumeUnit.flOz) {
      final oz = UnitConverters.mlToFlOz(_waterMl!.toDouble()).round();
      return '$oz fl oz/day';
    }
    final formatted = UnitFormatters.formatVolume(
      _waterMl!.toDouble(),
      VolumeUnit.ml,
      decimals: 1,
    );
    return '$_waterMl ml/day ($formatted)';
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

  String _formatTimeOfDay(int? totalMinutes) {
    if (totalMinutes == null) return 'Not set';
    final time = TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
    return time.format(context);
  }

  Future<void> _pickSteps() async {
    final current = _dailySteps ?? 10000;
    var tempValue = current.clamp(2000, 18000);
    final colors = context.tioColors;

    final result = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TioRadius.lg),
        ),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          color:
                              colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                          borderRadius: BorderRadius.circular(TioSize.dp2),
                        ),
                      ),
                    ),
                    const SizedBox(height: TioSpacing.md),
                    Text(
                      'Daily Step Goal',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioFontSize.size18,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      'Recommended: 10,000 steps/day',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: TioFontSize.size13,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.lg),
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
                      value: tempValue.toDouble(),
                      min: 2000,
                      max: 18000,
                      divisions: 32,
                      activeColor: colors.primary,
                      onChanged: (val) {
                        setModalState(() {
                          tempValue = (val / 500).round() * 500;
                        });
                      },
                    ),
                    const SizedBox(height: TioSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(modalContext).pop(-1),
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
                  ],
                ),
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
    var tempValue = current.clamp(1000, 8000);
    final colors = context.tioColors;

    final result = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TioRadius.lg),
        ),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isFlOz = widget.volumeUnit == VolumeUnit.flOz;
            final displayQty = isFlOz
                ? '${UnitConverters.mlToFlOz(tempValue.toDouble()).round()} fl oz'
                : '$tempValue ml (${UnitFormatters.formatVolume(tempValue.toDouble(), VolumeUnit.ml, decimals: 1)})';

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
                          color:
                              colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                          borderRadius: BorderRadius.circular(TioSize.dp2),
                        ),
                      ),
                    ),
                    const SizedBox(height: TioSpacing.md),
                    Text(
                      'Daily Water Goal',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioFontSize.size18,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      'Recommended: 2,000 - 4,000 ml/day',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: TioFontSize.size13,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.lg),
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
                      value: tempValue.toDouble(),
                      min: 1000,
                      max: 8000,
                      divisions: 70,
                      activeColor: colors.primary,
                      onChanged: (val) {
                        setModalState(() {
                          tempValue = (val / 100).round() * 100;
                        });
                      },
                    ),
                    const SizedBox(height: TioSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(modalContext).pop(-1),
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
                  ],
                ),
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
    var tempBedTime = _bedTimeMinutes;
    var tempWakeTime = _wakeTimeMinutes;
    final colors = context.tioColors;

    final result = await showModalBottomSheet<(int?, int?)>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TioRadius.lg),
        ),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewDuration =
                _computeSleepDuration(tempBedTime, tempWakeTime);

            Future<void> pickBedTime() async {
              final current = tempBedTime ?? (22 * 60);
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: current ~/ 60,
                  minute: current % 60,
                ),
              );
              if (picked != null) {
                setModalState(() {
                  tempBedTime = (picked.hour * 60) + picked.minute;
                });
              }
            }

            Future<void> pickWakeTime() async {
              final current = tempWakeTime ?? (6 * 60 + 30);
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: current ~/ 60,
                  minute: current % 60,
                ),
              );
              if (picked != null) {
                setModalState(() {
                  tempWakeTime = (picked.hour * 60) + picked.minute;
                });
              }
            }

            Widget scheduleTimeColumn({
              required String label,
              required int? minutes,
              required VoidCallback onTap,
            }) {
              return Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(TioRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TioSpacing.sm,
                    ),
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
                          _formatTimeOfDay(minutes),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: TioFontWeight.w700,
                            fontSize: TioFontSize.size18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

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
                          color:
                              colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                          borderRadius: BorderRadius.circular(TioSize.dp2),
                        ),
                      ),
                    ),
                    const SizedBox(height: TioSpacing.md),
                    Text(
                      'Sleep Schedule',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioFontSize.size18,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.lg),
                    Row(
                      children: [
                        scheduleTimeColumn(
                          label: 'Bedtime',
                          minutes: tempBedTime,
                          onTap: pickBedTime,
                        ),
                        scheduleTimeColumn(
                          label: 'Wake Time',
                          minutes: tempWakeTime,
                          onTap: pickWakeTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: TioSpacing.lg),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempBedTime = null;
                                tempWakeTime = null;
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
                            onPressed: () => Navigator.of(modalContext)
                                .pop((tempBedTime, tempWakeTime)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

                  // ── TARGETS GROUP ──
                  const _DailyWellnessSectionHeader(title: 'TARGETS'),
                  _DailyWellnessGroupCard(
                    children: [
                      _DailyWellnessRow(
                        key: const ValueKey('daily-wellness-steps-field'),
                        icon: Icons.directions_walk_rounded,
                        label: 'Step Goal',
                        value: _formatSteps(),
                        isUnset: _dailySteps == null,
                        onTap: _pickSteps,
                      ),
                      const _DailyWellnessDivider(),
                      _DailyWellnessRow(
                        key: const ValueKey('daily-wellness-water-field'),
                        icon: Icons.water_drop_outlined,
                        label: 'Water Goal',
                        value: _formatWater(),
                        isUnset: _waterMl == null,
                        onTap: _pickWater,
                      ),
                    ],
                  ),

                  const SizedBox(height: TioSpacing.lg),

                  // ── SLEEP GROUP ──
                  const _DailyWellnessSectionHeader(title: 'SLEEP'),
                  _DailyWellnessGroupCard(
                    children: [
                      _DailyWellnessRow(
                        key: const ValueKey(
                          'daily-wellness-sleep-schedule-field',
                        ),
                        icon: Icons.bedtime_outlined,
                        label: 'Sleep Schedule',
                        value: _formatSleepDuration(_sleepTargetMinutes),
                        isUnset: _sleepTargetMinutes == null,
                        subtitle: _bedTimeMinutes == null &&
                                _wakeTimeMinutes == null
                            ? null
                            : '${_formatTimeOfDay(_bedTimeMinutes)} - ${_formatTimeOfDay(_wakeTimeMinutes)}',
                        onTap: _pickSleepSchedule,
                      ),
                    ],
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
  const _DailyWellnessGroupCard({required this.children});
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
  const _DailyWellnessDivider();

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
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Explicit unset styling contract instead of sniffing `value == 'Not set'`.
  final bool isUnset;

  /// Optional secondary line rendered below [label]/[value] (e.g. the
  /// Bedtime–Wake Time range under the Sleep Schedule duration).
  final String? subtitle;
  final VoidCallback onTap;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.xxs),
                  Text(
                    value,
                    style: TextStyle(
                      color: isUnset ? colors.textMuted : colors.textSecondary,
                      fontSize: TioFontSize.size13,
                      fontWeight:
                          isUnset ? TioFontWeight.w400 : TioFontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: TioSpacing.xxs),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: TioFontSize.size12,
                        fontWeight: TioFontWeight.w400,
                      ),
                    ),
                  ],
                ],
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
