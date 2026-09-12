import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/meal_diary_display_preferences.dart';
import '../../meal_diary_display_preferences_providers.dart';
import '../../meal_diary_history_providers.dart';

/// Selected-day MealLog history below the reusable date calendar.
///
/// This widget is deliberately read-only in TNYX-199. It renders canonical
/// repository truth and presentation preferences, but owns no create/edit/
/// delete action and does not reach any backend client directly.
class MealDiaryHistoryView extends ConsumerWidget {
  const MealDiaryHistoryView({
    required this.date,
    required this.request,
    super.key,
  });

  final DateTime date;

  /// Null only in isolated feature harnesses where app composition has not
  /// supplied persistence. Production supplies a request through the canonical
  /// repository seam.
  final MealDiaryHistoryRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref
        .watch(mealDiaryDisplayPreferencesControllerProvider)
        .preferences;
    final historyRequest = request;
    final history = historyRequest == null
        ? null
        : ref.watch(mealDiaryHistoryProvider(historyRequest));

    return Padding(
      padding: const EdgeInsets.all(TioSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            MaterialLocalizations.of(context).formatFullDate(date),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.tioColors.textPrimary,
                ),
          ),
          const SizedBox(height: TioSpacing.lg),
          if (history == null)
            const _EmptyDay()
          else
            history.when(
              loading: () => const _HistoryLoading(),
              error: (_, __) => _HistoryError(
                onRetry: () => ref.invalidate(
                  mealDiaryHistoryProvider(historyRequest!),
                ),
              ),
              data: (data) => data.isEmpty
                  ? const _EmptyDay()
                  : _HistorySections(
                      data: data,
                      preferences: preferences,
                    ),
            ),
        ],
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        key: ValueKey('meal-diary-history-loading'),
        padding: EdgeInsets.symmetric(vertical: TioSpacing.xl),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return Text(
      key: const ValueKey('meal-diary-empty-day-note'),
      'Nothing is logged for this day.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.tioColors.textSecondary,
          ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('meal-diary-history-error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Could not load meals for this day.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: TioSpacing.sm),
        Text(
          'Check your connection and try again.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: TioSpacing.lg),
        TioButton.secondary(
          key: const ValueKey('meal-diary-history-retry'),
          label: 'Retry',
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _HistorySections extends StatelessWidget {
  const _HistorySections({
    required this.data,
    required this.preferences,
  });

  final MealDiaryHistoryReadModel data;
  final MealDiaryDisplayPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var sectionIndex = 0;
            sectionIndex < data.sections.length;
            sectionIndex++) ...[
          if (sectionIndex > 0) const SizedBox(height: TioSpacing.xl),
          _Section(
            section: data.sections[sectionIndex],
            preferences: preferences,
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.preferences,
  });

  final MealDiarySectionReadModel section;
  final MealDiaryDisplayPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final summary = _nutritionSummary(
      caloriesKcal: section.caloriesKcal,
      proteinGrams: section.proteinGrams,
      compactProtein: false,
    );

    return Column(
      key: ValueKey('meal-diary-section-${section.categoryId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                section.categoryDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              child: Divider(
                height: TioStroke.width1,
                thickness: TioStroke.width1,
                color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
              ),
            ),
            if (summary != null) ...[
              const SizedBox(width: TioSpacing.sm),
              Text(
                summary,
                key: ValueKey(
                  'meal-diary-section-summary-${section.categoryId}',
                ),
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: TioSpacing.sm),
        for (var entryIndex = 0;
            entryIndex < section.entries.length;
            entryIndex++) ...[
          if (entryIndex > 0) const SizedBox(height: TioSpacing.sm),
          _MealEntryCard(
            entry: section.entries[entryIndex],
            preferences: preferences,
          ),
        ],
      ],
    );
  }
}

class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({
    required this.entry,
    required this.preferences,
  });

  final MealDiaryEntryReadModel entry;
  final MealDiaryDisplayPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final noteVisible = preferences.mealNotesEnabled && entry.note != null;
    final notePreviewVisible = noteVisible && preferences.showMealNotePreview;
    final timeLabel = preferences.showMealTimes
        ? _formatLoggedTime(context, entry.loggedLocalDateTime)
        : null;
    final nutrition = _nutritionSummary(
      caloriesKcal: entry.caloriesKcal,
      proteinGrams: entry.proteinGrams,
      compactProtein: true,
    );

    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry.displayTitle != null || noteVisible)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.displayTitle != null)
                Expanded(
                  child: Text(
                    entry.displayTitle!,
                    key: ValueKey('meal-diary-entry-title-${entry.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (noteVisible) ...[
                const SizedBox(width: TioSpacing.sm),
                Icon(
                  Icons.sticky_note_2_outlined,
                  key: ValueKey('meal-diary-entry-note-${entry.id}'),
                  size: TioSize.dp16,
                  color: colors.textSecondary,
                  semanticLabel: 'Meal note',
                ),
              ],
            ],
          ),
        if ((entry.displayTitle != null || noteVisible) && nutrition != null)
          const SizedBox(height: TioSpacing.xs),
        if (nutrition != null)
          Text(
            nutrition,
            key: ValueKey('meal-diary-entry-nutrition-${entry.id}'),
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        if (notePreviewVisible) ...[
          const SizedBox(height: TioSpacing.xs),
          Text(
            entry.note!,
            key: ValueKey('meal-diary-entry-note-preview-${entry.id}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      label: entry.displayTitle ?? 'Meal log',
      child: TioCard(
        key: ValueKey('meal-diary-entry-${entry.id}'),
        variant: TioCardVariant.normal,
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timeLabel != null) ...[
              Text(
                timeLabel,
                key: ValueKey('meal-diary-entry-time-${entry.id}'),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: TioSpacing.md),
            ],
            Expanded(child: detail),
          ],
        ),
      ),
    );
  }
}

String? _formatLoggedTime(BuildContext context, DateTime? loggedLocalDateTime) {
  if (loggedLocalDateTime == null) return null;
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(
      hour: loggedLocalDateTime.hour,
      minute: loggedLocalDateTime.minute,
    ),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

String? _nutritionSummary({
  required num? caloriesKcal,
  required num? proteinGrams,
  required bool compactProtein,
}) {
  final parts = <String>[];
  if (caloriesKcal != null) {
    parts.add('${_formatAmount(caloriesKcal)} kcal');
  }
  if (proteinGrams != null) {
    parts.add(
      '${_formatAmount(proteinGrams)}g ${compactProtein ? 'P' : 'protein'}',
    );
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String _formatAmount(num value) {
  final numeric = value.toDouble();
  if (numeric == numeric.roundToDouble()) return numeric.toInt().toString();
  return numeric.toStringAsFixed(1);
}
