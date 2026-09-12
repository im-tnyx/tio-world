import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/meal_diary_display_preferences.dart';
import '../../meal_diary_display_preferences_providers.dart';
import '../../meal_diary_history_providers.dart';
import 'meal_diary_meal_card.dart';

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
    this.onEdit,
  });

  final DateTime date;

  /// Null only in isolated feature harnesses where app composition has not
  /// supplied persistence. Production supplies a request through the canonical
  /// repository seam.
  final MealDiaryHistoryRequest? request;

  /// Opens the canonical row in Quick Edit. Null keeps isolated read-only
  /// harnesses honest and omits the action rather than drawing a dead control.
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences =
        ref.watch(mealDiaryDisplayPreferencesControllerProvider).preferences;
    final historyRequest = request;
    final history = historyRequest == null
        ? null
        : ref.watch(mealDiaryHistoryProvider(historyRequest));

    return Padding(
      padding: const EdgeInsets.all(TioSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      onEdit: onEdit,
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
    required this.onEdit,
  });

  final MealDiaryHistoryReadModel data;
  final MealDiaryDisplayPreferences preferences;
  final ValueChanged<String>? onEdit;

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
            onEdit: onEdit,
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
    required this.onEdit,
  });

  final MealDiarySectionReadModel section;
  final MealDiaryDisplayPreferences preferences;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final hasSummary = preferences.showMealSectionNutrition &&
        (section.caloriesKcal != null || section.proteinGrams != null);

    return Column(
      key: ValueKey('meal-diary-section-${section.categoryId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Title and rule share one tight flex region so a short title
            // cannot leave slack that pushes the trailing summary off the
            // content edge. The rule absorbs the middle; the summary stays
            // intrinsic and flush right.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    // Natural width, so the rule starts immediately after the
                    // title. The cap is the gap the rule needs, so a maximum
                    // length category name shortens the rule instead of
                    // overflowing the header.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - TioSpacing.sm,
                      ),
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
                    Expanded(
                      child: Divider(
                        height: TioStroke.width1,
                        thickness: TioStroke.width1,
                        color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasSummary) ...[
              const SizedBox(width: TioSpacing.sm),
              _SectionNutritionSummary(
                key: ValueKey(
                  'meal-diary-section-summary-${section.categoryId}',
                ),
                caloriesKcal: section.caloriesKcal,
                proteinGrams: section.proteinGrams,
              ),
            ],
          ],
        ),
        const SizedBox(height: TioSpacing.sm),
        for (var entryIndex = 0;
            entryIndex < section.entries.length;
            entryIndex++) ...[
          // Cards breathe by the same inset that holds them off the screen
          // edges, so the rhythm reads the same in both directions.
          if (entryIndex > 0) const SizedBox(height: TioSpacing.lg),
          _MealEntryCard(
            entry: section.entries[entryIndex],
            preferences: preferences,
            onEdit: onEdit,
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
    required this.onEdit,
  });

  final MealDiaryEntryReadModel entry;
  final MealDiaryDisplayPreferences preferences;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final noteVisible = preferences.mealNotesEnabled && entry.note != null;
    final edit = onEdit;
    final open = edit == null ? null : () => edit(entry.id);

    return MealDiaryMealCard(
      entryId: entry.id,
      mealName: entry.displayTitle,
      caloriesText: entry.caloriesKcal == null
          ? null
          : '${_formatAmount(entry.caloriesKcal!)} kcal',
      proteinText: entry.proteinGrams == null
          ? null
          : '${_formatAmount(entry.proteinGrams!)} g',
      timeText: preferences.showMealTimes
          ? _formatLoggedTime(context, entry.loggedLocalDateTime)
          : null,
      noteIndicatorVisible: noteVisible,
      notePreview:
          noteVisible && preferences.showMealNotePreview ? entry.note : null,
      onTap: open,
      onEdit: open,
    );
  }
}

class _SectionNutritionSummary extends StatelessWidget {
  const _SectionNutritionSummary({
    required this.caloriesKcal,
    required this.proteinGrams,
    super.key,
  });

  final num? caloriesKcal;
  final num? proteinGrams;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
        );
    final caloriesLabel =
        caloriesKcal == null ? null : '${_formatAmount(caloriesKcal!)} kcal';
    final proteinLabel =
        proteinGrams == null ? null : '${_formatAmount(proteinGrams!)}g';
    final semanticParts = [
      if (caloriesLabel != null) caloriesLabel,
      if (proteinLabel != null) '$proteinLabel protein',
    ];

    return Semantics(
      label: semanticParts.join(', '),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (caloriesLabel != null) ...[
              SvgPicture.asset(
                'assets/svg_icon/apple.svg',
                package: 'tio_core',
                width: TioSize.dp20,
                height: TioSize.dp20,
                // Both glyphs must be tinted here. Without a filter the asset
                // paints whatever colour it was authored with, which no theme
                // and no analyzer can reach.
                colorFilter: ColorFilter.mode(
                  colors.nutrition,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: TioSpacing.xs),
              Text(caloriesLabel, style: style),
            ],
            if (caloriesLabel != null && proteinLabel != null)
              const SizedBox(width: TioSpacing.sm),
            if (proteinLabel != null) ...[
              SvgPicture.asset(
                'assets/svg_icon/ic_protine.svg',
                package: 'tio_core',
                width: TioSize.dp20,
                height: TioSize.dp20,
                colorFilter: ColorFilter.mode(
                  colors.warning,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: TioSpacing.xs),
              Text(proteinLabel, style: style),
            ],
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

String _formatAmount(num value) {
  final numeric = value.toDouble();
  if (numeric == numeric.roundToDouble()) return numeric.toInt().toString();
  return numeric.toStringAsFixed(1);
}
