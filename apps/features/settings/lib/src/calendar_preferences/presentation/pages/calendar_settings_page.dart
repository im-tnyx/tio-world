import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/calendar_preferences.dart';

/// `Settings → App Preferences → Calendar`.
///
/// A choice with two options and an instant, visible effect, so it applies on
/// tap rather than behind a Save button: the same immediate-apply shape the
/// Appearance sheet already uses. There is nothing to review before committing
/// and nothing to lose by leaving the page.
class CalendarSettingsPage extends StatelessWidget {
  const CalendarSettingsPage({
    required this.firstDayOfWeek,
    required this.onFirstDayOfWeekChanged,
    super.key,
    this.errorText,
  });

  final FirstDayOfWeekPreference firstDayOfWeek;

  /// Applies and persists the choice. The page owns no state of its own, so a
  /// failed write leaves the previous value showing rather than a lie.
  final ValueChanged<FirstDayOfWeekPreference> onFirstDayOfWeekChanged;

  /// Set by the caller when the last write failed.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TioSpacing.xl),
          children: [
            Text(
              'First day of week',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: TioSpacing.sm),
            Text(
              'Every calendar in Tio starts its weeks on this day. '
              'Saved on this device.',
              style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: TioSpacing.xl),
            _FirstDayOption(
              key: const ValueKey('calendar-first-day-option-monday'),
              value: FirstDayOfWeekPreference.monday,
              label: 'Monday (default)',
              // The order under the label is the whole point of the choice, so
              // the option shows it instead of describing it.
              preview: 'MON TUE WED THU FRI SAT SUN',
              selected: firstDayOfWeek == FirstDayOfWeekPreference.monday,
              onSelected: onFirstDayOfWeekChanged,
            ),
            const SizedBox(height: TioSpacing.md),
            _FirstDayOption(
              key: const ValueKey('calendar-first-day-option-sunday'),
              value: FirstDayOfWeekPreference.sunday,
              label: 'Sunday',
              preview: 'SUN MON TUE WED THU FRI SAT',
              selected: firstDayOfWeek == FirstDayOfWeekPreference.sunday,
              onSelected: onFirstDayOfWeekChanged,
            ),
            if (errorText case final message?) ...[
              const SizedBox(height: TioSpacing.lg),
              Text(
                message,
                key: const ValueKey('calendar-first-day-error'),
                style: TextStyle(color: colors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One option, drawn by the canonical selectable card.
///
/// The card owns the chosen/unchosen appearance and the button/selected
/// semantics node; this widget only composes what goes inside it.
class _FirstDayOption extends StatelessWidget {
  const _FirstDayOption({
    required this.value,
    required this.label,
    required this.preview,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final FirstDayOfWeekPreference value;
  final String label;
  final String preview;
  final bool selected;
  final ValueChanged<FirstDayOfWeekPreference> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioSelectableCard(
      selected: selected,
      // The preview is a layout illustration, not something worth spelling out
      // letter by letter, so the option announces its name and state instead.
      semanticLabel: label,
      onTap: () => onSelected(value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight:
                        selected ? TioFontWeight.w600 : TioFontWeight.w500,
                  ),
                ),
                const SizedBox(height: TioSpacing.xxs),
                Text(
                  preview,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: TioLetterSpacing.positive08,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TioSpacing.md),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? colors.primary : colors.outlineStrong,
          ),
        ],
      ),
    );
  }
}
