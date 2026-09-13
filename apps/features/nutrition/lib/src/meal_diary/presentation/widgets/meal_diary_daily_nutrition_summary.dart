import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/models/daily_nutrition_summary.dart';

/// Nutrition-owned selected-day summary composition.
///
/// The card receives already-derived domain truth and owns only formatting,
/// layout and accessibility. Workout is deliberately absent in N3A. The calorie
/// metric list wraps, so a later approved N3B term can be added without
/// replacing the composition.
class MealDiaryDailyNutritionSummary extends StatelessWidget {
  const MealDiaryDailyNutritionSummary({
    required this.summary,
    super.key,
  });

  final DailyNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final metrics = <_CalorieMetric>[
      _CalorieMetric(
        label: 'Target',
        value: _format(summary.targetCaloriesKcal, unit: 'kcal'),
      ),
      _CalorieMetric(
        label: 'Eaten',
        value: _format(summary.eatenCaloriesKcal, unit: 'kcal'),
      ),
      _CalorieMetric(
        label: 'Remaining',
        value: _format(summary.remainingCaloriesKcal, unit: 'kcal'),
      ),
    ];

    return TioCard(
      key: const ValueKey('meal-diary-daily-nutrition-summary'),
      variant: TioCardVariant.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daily Nutrition',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w700,
            ),
          ),
          const SizedBox(height: TioSpacing.xs),
          Text(
            'Target - Eaten = Remaining',
            key: const ValueKey('daily-nutrition-calorie-equation'),
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: TioSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= TioSize.dp360 ? 3 : 2;
              final gaps = TioSpacing.sm * (columns - 1);
              final tileWidth = (constraints.maxWidth - gaps) / columns;
              return Wrap(
                spacing: TioSpacing.sm,
                runSpacing: TioSpacing.sm,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: tileWidth,
                      child: _CalorieMetricTile(metric: metric),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: TioSpacing.lg),
          const Divider(height: TioStroke.width1),
          const SizedBox(height: TioSpacing.sm),
          _NutrientProgressRow(
            label: 'Carbs',
            nutrient: NutrientId.carbohydrate,
            summary: summary,
          ),
          _NutrientProgressRow(
            label: 'Protein',
            nutrient: NutrientId.protein,
            summary: summary,
          ),
          _NutrientProgressRow(
            label: 'Fat',
            nutrient: NutrientId.fat,
            summary: summary,
          ),
          _NutrientProgressRow(
            label: 'Fiber',
            nutrient: NutrientId.fiber,
            summary: summary,
          ),
        ],
      ),
    );
  }

  static String _format(num? value, {required String unit}) {
    if (value == null) return 'Unavailable';
    final number = value.toDouble();
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
    return '$text $unit';
  }
}

class MealDiaryDailyNutritionSummaryStatus extends StatelessWidget {
  const MealDiaryDailyNutritionSummaryStatus.loading({super.key})
      : message = 'Loading daily nutrition…',
        isLoading = true;

  const MealDiaryDailyNutritionSummaryStatus.error({super.key})
      : message = 'Daily nutrition unavailable',
        isLoading = false;

  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioCard(
      key: ValueKey(
        isLoading
            ? 'meal-diary-daily-nutrition-loading'
            : 'meal-diary-daily-nutrition-error',
      ),
      variant: TioCardVariant.normal,
      child: Row(
        children: [
          if (isLoading) ...[
            SizedBox.square(
              dimension: TioSize.dp20,
              child: CircularProgressIndicator(
                strokeWidth: TioStroke.width2,
                color: colors.nutrition,
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
          ],
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _CalorieMetric {
  const _CalorieMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _CalorieMetricTile extends StatelessWidget {
  const _CalorieMetricTile({required this.metric});

  final _CalorieMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '${metric.label}, ${metric.value}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(TioSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(TioRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: TioSpacing.xs),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientProgressRow extends StatelessWidget {
  const _NutrientProgressRow({
    required this.label,
    required this.nutrient,
    required this.summary,
  });

  final String label;
  final NutrientId nutrient;
  final DailyNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final consumed = summary.consumedAmountFor(nutrient);
    final target = summary.targetAmountFor(nutrient);
    final progress = summary.progressFor(nutrient);
    final available = consumed != null && target != null;
    final valueText = available
        ? '${_grams(consumed)} / ${_grams(target)}'
        : 'Unavailable';

    return Semantics(
      container: true,
      label: available
          ? '$label, ${_grams(consumed)} consumed of ${_grams(target)} target'
          : '$label nutrition progress unavailable',
      value: progress == null ? null : '${(progress * 100).round()} percent',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  valueText,
                  key: ValueKey(
                    'daily-nutrition-${nutrient.storageValue}-value',
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: available
                        ? colors.textSecondary
                        : colors.textMuted,
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: TioSpacing.xs),
              LinearProgressIndicator(
                key: ValueKey(
                  'daily-nutrition-${nutrient.storageValue}-progress',
                ),
                value: progress,
                minHeight: TioSize.dp4,
                borderRadius: BorderRadius.circular(TioRadius.full),
                color: colors.nutrition,
                backgroundColor: colors.surfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _grams(num value) {
    final number = value.toDouble();
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
    return '$text g';
  }
}
