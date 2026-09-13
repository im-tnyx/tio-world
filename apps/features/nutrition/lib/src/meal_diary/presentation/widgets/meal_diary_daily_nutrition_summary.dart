import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/models/daily_nutrition_summary.dart';
import '../../meal_diary_nutrition_summary_providers.dart';

/// Compact Nutrition-owned selected-day summary composition.
///
/// The geometry intentionally mirrors the owner-approved reference: one
/// equation row for Target − Eaten = Remaining, followed by one compact row of
/// supported nutrient progress cells. Workout is deliberately absent in N3A.
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
        value: summary.targetCaloriesKcal,
        valueKey: const ValueKey('daily-nutrition-target-calories'),
      ),
      _CalorieMetric(
        label: 'Eaten',
        value: summary.eatenCaloriesKcal,
        valueKey: const ValueKey('daily-nutrition-eaten-calories'),
      ),
      _CalorieMetric(
        label: 'Remaining',
        value: summary.remainingCaloriesKcal,
        valueKey: const ValueKey('daily-nutrition-remaining-calories'),
      ),
    ];
    final supportedNutrients = <({String label, NutrientId nutrient})>[
      (label: 'Carbs', nutrient: NutrientId.carbohydrate),
      (label: 'Protein', nutrient: NutrientId.protein),
      (label: 'Fat', nutrient: NutrientId.fat),
      (label: 'Fiber', nutrient: NutrientId.fiber),
    ].where((row) {
      return summary.consumedAmountFor(row.nutrient) != null &&
          summary.targetAmountFor(row.nutrient) != null;
    }).toList(growable: false);

    return TioCard(
      key: const ValueKey('meal-diary-daily-nutrition-summary'),
      variant: TioCardVariant.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _CalorieMetricCell(metric: metrics[0])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.xs),
                child: ExcludeSemantics(
                  child: Text(
                    '−',
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: TioFontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(child: _CalorieMetricCell(metric: metrics[1])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.xs),
                child: ExcludeSemantics(
                  child: Text(
                    '=',
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: TioFontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(child: _CalorieMetricCell(metric: metrics[2])),
            ],
          ),
          if (supportedNutrients.isNotEmpty) ...[
            const SizedBox(height: TioSpacing.md),
            const Divider(height: TioStroke.width1),
            const SizedBox(height: TioSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0;
                    index < supportedNutrients.length;
                    index++) ...[
                  if (index > 0) const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: _NutrientProgressCell(
                      label: supportedNutrients[index].label,
                      nutrient: supportedNutrients[index].nutrient,
                      summary: summary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MealDiaryDailyNutritionSummaryStatus extends ConsumerWidget {
  const MealDiaryDailyNutritionSummaryStatus.loading({super.key})
      : message = 'Loading daily nutrition…',
        isLoading = true;

  const MealDiaryDailyNutritionSummaryStatus.error({super.key})
      : message = 'Daily nutrition unavailable',
        isLoading = false;

  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          if (!isLoading)
            TextButton(
              key: const ValueKey('meal-diary-daily-nutrition-retry'),
              onPressed: () {
                ref.invalidate(mealDiaryDailyNutritionSummaryProvider);
                ref.invalidate(mealDiaryNutritionSummaryRangeProvider);
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

@immutable
class _CalorieMetric {
  const _CalorieMetric({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final num? value;
  final Key valueKey;
}

class _CalorieMetricCell extends StatelessWidget {
  const _CalorieMetricCell({required this.metric});

  final _CalorieMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final valueText = _formatNumber(metric.value);
    final semanticValue = metric.value == null
        ? 'unavailable'
        : '${_formatNumber(metric.value)} kilocalories';

    return Semantics(
      container: true,
      label: '${metric.label}, $semanticValue',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valueText,
              key: metric.valueKey,
              maxLines: 1,
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: TioSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.label,
              maxLines: 1,
              style: textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
                fontWeight: TioFontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientProgressCell extends StatelessWidget {
  const _NutrientProgressCell({
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
    final consumed = summary.consumedAmountFor(nutrient)!;
    final target = summary.targetAmountFor(nutrient)!;
    final progress = summary.progressFor(nutrient);
    final valueText = '${_grams(consumed)} / ${_grams(target)}';

    return Semantics(
      container: true,
      label: '$label, ${_grams(consumed)} consumed of ${_grams(target)} target',
      value: progress == null ? null : '${(progress * 100).round()} percent',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          if (progress != null)
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
          const SizedBox(height: TioSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valueText,
              key: ValueKey(
                'daily-nutrition-${nutrient.storageValue}-value',
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _grams(num value) => '${_formatNumber(value)} g';
}

String _formatNumber(num? value) {
  if (value == null) return '—';
  final number = value.toDouble();
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toStringAsFixed(1);
}
