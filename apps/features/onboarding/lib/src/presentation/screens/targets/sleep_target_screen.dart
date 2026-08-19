import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

class SleepTargetScreen extends StatelessWidget {
  const SleepTargetScreen({
    required this.sleepTargetMinutes,
    required this.sleepTimeMinutes,
    required this.wakeTimeMinutes,
    required this.onSleepScheduleChange,
    super.key,
    this.errorText,
  });

  final int sleepTargetMinutes;
  final int sleepTimeMinutes;
  final int wakeTimeMinutes;
  final void Function({
    int? sleepTimeMinutes,
    int? wakeTimeMinutes,
    int? durationMinutes,
  }) onSleepScheduleChange;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final hours = sleepTargetMinutes / 60.0;
    final isRecommended = sleepTargetMinutes >= 420 && sleepTargetMinutes <= 540;

    final hoursDisplay = hours == hours.roundToDouble()
        ? '${hours.toInt()}h'
        : '${hours.toStringAsFixed(1)}h';

    return TargetsScreenScaffold(
      stepId: TargetStepId.sleepTarget,
      title: 'Sleep schedule target',
      description:
          'Consistent sleep duration and timing are vital for recovery and energy.',
      errorText: errorText,
      child: Column(
        children: [
          TioCard(
            key: const ValueKey('targets-sleep-card'),
            variant: TioCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      color: colors.progress,
                      size: TioSize.dp24,
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    Text(
                      'Sleep Target',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.md),
                Center(
                  child: Column(
                    children: [
                      Text(
                        hoursDisplay,
                        key: const ValueKey('targets-sleep-duration-text'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              fontWeight: TioFontWeight.w700,
                              color: colors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: TioSpacing.xs),
                      Text(
                        'hours/day ($sleepTargetMinutes min)',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TioSpacing.md),
                Slider(
                  key: const ValueKey('targets-sleep-slider'),
                  value: sleepTargetMinutes
                      .clamp(
                        SleepScheduleHelper.minDurationMinutes,
                        SleepScheduleHelper.maxDurationMinutes,
                      )
                      .toDouble(),
                  min: SleepScheduleHelper.minDurationMinutes.toDouble(),
                  max: SleepScheduleHelper.maxDurationMinutes.toDouble(),
                  divisions: 16, // Program value: 30-minute increments.
                  activeColor: colors.primary,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    onSleepScheduleChange(durationMinutes: val.round());
                  },
                ),
                Center(
                  child: TargetsStatusChip(
                    label: isRecommended ? 'Recommended' : 'Not Recommended',
                    isRecommended: isRecommended,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.lg),
          TioCard(
            key: const ValueKey('targets-sleep-schedule-card'),
            variant: TioCardVariant.outlined,
            child: Column(
              children: [
                _TimePickerRow(
                  key: const ValueKey('targets-sleep-time-row'),
                  icon: Icons.nightlight_outlined,
                  iconColor: colors.progress,
                  label: 'Sleep time',
                  timeMinutes: sleepTimeMinutes,
                  onTap: () => _pickTime(
                    context: context,
                    currentMinutes: sleepTimeMinutes,
                    onSelected: (mins) =>
                        onSleepScheduleChange(sleepTimeMinutes: mins),
                  ),
                ),
                const Divider(height: TioSize.dp1),
                _TimePickerRow(
                  key: const ValueKey('targets-wake-time-row'),
                  icon: Icons.wb_sunny_outlined,
                  iconColor: colors.warning,
                  label: 'Wake time',
                  timeMinutes: wakeTimeMinutes,
                  onTap: () => _pickTime(
                    context: context,
                    currentMinutes: wakeTimeMinutes,
                    onSelected: (mins) =>
                        onSleepScheduleChange(wakeTimeMinutes: mins),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.md),
          Text(
            '7–9 hours of sleep per night is recommended for optimal cognitive performance, muscle recovery, and metabolic health.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime({
    required BuildContext context,
    required int currentMinutes,
    required ValueChanged<int> onSelected,
  }) async {
    final initialTime = TimeOfDay(
      hour: (currentMinutes ~/ 60) % 24,
      minute: currentMinutes % 60,
    );

    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selected != null) {
      onSelected(selected.hour * 60 + selected.minute);
    }
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.timeMinutes,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int timeMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final h24 = (timeMinutes ~/ 60) % 24;
    final m = timeMinutes % 60;
    final isPm = h24 >= 12;
    final displayHour = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final amPm = isPm ? 'PM' : 'AM';
    final formattedTime =
        '$displayHour:${m.toString().padLeft(2, '0')} $amPm';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.md,
          vertical: TioSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: TioSize.dp22),
            const SizedBox(width: TioSpacing.md),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: TioFontWeight.w600,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: TioSize.dp20,
              color: colors.outlineStrong,
            ),
          ],
        ),
      ),
    );
  }
}
