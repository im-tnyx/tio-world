import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/calendar_preferences.dart';

/// `Settings → App Preferences → Calendar`.
///
/// Every day of the week is offered, Monday through Sunday, so a reader whose
/// week genuinely starts mid-cycle is not told their week is invalid. Seven
/// options is also why this is a page rather than a bottom sheet: a sheet that
/// tall scrolls badly on a small phone, and Calendar is a preference family
/// that will gain members.
///
/// The choice applies on tap rather than behind a Save button, the same
/// immediate-apply shape the Appearance sheet uses. There is nothing to review
/// before committing and nothing to lose by leaving the page.
///
/// One live preview sits above the list instead of a preview under every
/// option: seven near-identical seven-token strings are a wall of text, while
/// a single strip that reorders as you choose answers the same question.
///
/// The one line under the heading names the surface the choice affects. Two
/// earlier attempts were rejected: "every calendar in Tio" promised screens
/// that do not exist yet, and "Saved on this device" is implementation detail
/// wearing the clothes of help text. Naming the real surface is what a reader
/// can act on, and it is the shape other fitness apps use.
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
  final Future<void> Function(FirstDayOfWeekPreference) onFirstDayOfWeekChanged;

  /// Set by the caller when the last write failed.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toString();

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
            // Names the surface this actually affects rather than promising
            // "every calendar", because Meal Diary is the only consumer today.
            // As Workout, plans and Progress start reading the preference,
            // extend this sentence with them — do not generalise it early.
            Text(
              'This changes where weeks start in your Meal Diary calendar.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: TioSpacing.lg),
            // Drawn from the same ordering helper the calendar header uses, so
            // this cannot promise a layout the calendar does not render.
            Text(
              tioOrderedWeekdayLabels(
                firstDayOfWeek: firstDayOfWeek.weekday,
                localeName: localeName,
              ).join('   '),
              key: const ValueKey('calendar-first-day-preview'),
              style: textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                letterSpacing: TioLetterSpacing.positive08,
              ),
            ),
            const SizedBox(height: TioSpacing.xl),
            for (final option in FirstDayOfWeekPreference.values) ...[
              if (option != FirstDayOfWeekPreference.values.first)
                const SizedBox(height: TioSpacing.md),
              _FirstDayOption(
                key: ValueKey(
                  'calendar-first-day-option-${option.storageValue}',
                ),
                value: option,
                label: _optionLabel(option, localeName),
                selected: firstDayOfWeek == option,
                onSelected: onFirstDayOfWeekChanged,
              ),
            ],
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

/// The day's own name, with the shipped default called out so a reader can
/// find their way back to it without having to remember which day it was.
String _optionLabel(FirstDayOfWeekPreference option, String localeName) {
  final name = tioWeekdayName(option.weekday, localeName: localeName);
  return option == CalendarPreferences.defaultFirstDayOfWeek
      ? '$name (default)'
      : name;
}

/// One option, drawn by the canonical selectable card.
///
/// The card owns the chosen/unchosen appearance and the button/selected
/// semantics node; this widget only composes what goes inside it.
class _FirstDayOption extends StatelessWidget {
  const _FirstDayOption({
    required this.value,
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final FirstDayOfWeekPreference value;
  final String label;
  final bool selected;
  final Future<void> Function(FirstDayOfWeekPreference) onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioSelectableCard(
      selected: selected,
      semanticLabel: label,
      onTap: () async {
        try {
          await onSelected(value);
        } catch (_) {
          // The app controller has already retained the retryable save error
          // and notified the route. Consume this UI event Future so a failed
          // device-local write is not reported as an uncaught async exception.
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: selected ? TioFontWeight.w600 : TioFontWeight.w500,
              ),
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
