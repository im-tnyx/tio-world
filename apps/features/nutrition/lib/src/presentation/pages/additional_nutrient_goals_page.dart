import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/domain.dart';
import '../widgets/nutrition_settings_widgets.dart';

/// Read-only Additional Nutrition reference values.
///
/// Every amount here is derived at display time from canonical Calories and
/// Profile date of birth. Nothing on this screen is stored, and nothing on it
/// writes: there is no per-nutrient editor, no custom override and no
/// enabled/disabled state in V1. Editing is a separate, later product slice.
///
/// When a rule's canonical input is missing, the row reads Unavailable rather
/// than showing a defaulted number — a fabricated nutrition figure is worse
/// than an honest gap.
class AdditionalNutrientGoalsPage extends StatelessWidget {
  const AdditionalNutrientGoalsPage({
    required this.caloriesKcal,
    required this.dateOfBirth,
    super.key,
    this.now,
  });

  /// Canonical Calories target. Null makes the percentage-derived values
  /// underivable rather than defaulted.
  final int? caloriesKcal;

  /// Canonical Profile date of birth, read only to resolve eligibility and the
  /// age bands. It is never copied into storage.
  final DateTime? dateOfBirth;

  /// Injectable clock so age boundaries are testable.
  final DateTime? now;

  /// Display labels. Order is owned by the policy so the screen cannot drift
  /// from it.
  static const _labels = <NutrientId, String>{
    NutrientId.saturatedFat: 'Saturated Fat',
    NutrientId.transFat: 'Trans Fat',
    NutrientId.addedSugar: 'Added Sugar',
    NutrientId.sodium: 'Sodium',
    NutrientId.calcium: 'Calcium',
    NutrientId.phosphorus: 'Phosphorus',
    NutrientId.vitaminD: 'Vitamin D',
  };

  NutrientRecommendation _recommendationFor(NutrientId nutrientId) =>
      AdditionalNutrientRecommendationPolicy.derive(
        nutrientId: nutrientId,
        caloriesKcal: caloriesKcal,
        dateOfBirth: dateOfBirth,
        now: now ?? DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    const order = AdditionalNutrientRecommendationPolicy.displayOrder;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Additional Nutrition',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.md,
            TioSpacing.lg,
            TioSpacing.xl,
          ),
          children: [
            const NutritionSettingsSectionHeader(title: 'DAILY REFERENCE'),
            TioGroupCard(
              children: [
                for (final (index, nutrientId) in order.indexed) ...[
                  // A divider separates every pair of rows and never trails
                  // the last one, so the card's rounded edge stays clean.
                  if (index > 0) _RowDivider(color: colors.outlineStrong),
                  _ValueRow(
                    key: ValueKey(
                      'additional-nutrient-${nutrientId.storageValue}-row',
                    ),
                    label: _labels[nutrientId]!,
                    recommendation: _recommendationFor(nutrientId),
                  ),
                ],
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            Text(
              'These daily reference values are calculated from your '
              'Nutrition Targets and profile where required. Missing required '
              'information is shown as Unavailable.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size13,
                height: TioLineHeight.height140,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One label/amount pair. Deliberately not tappable and with no trailing
/// affordance: this surface is read-only in V1.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.recommendation,
    super.key,
  });

  final String label;
  final NutrientRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final value = recommendation.recommendedValue;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioFontSize.size15,
                fontWeight: TioFontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: TioSpacing.md),
          Text(
            value == null
                ? 'Unavailable'
                : formatNutrientGoalAmount(
                    recommendation.nutrientId,
                    value,
                    recommendation.comparison,
                  ),
            style: TextStyle(
              // An unavailable value is deliberately quieter than a real one,
              // so a gap never reads as a number.
              color: value == null ? colors.textSecondary : colors.textPrimary,
              fontSize: TioFontSize.size15,
              fontWeight:
                  value == null ? TioFontWeight.w500 : TioFontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: TioSize.dp1,
      thickness: TioSize.dp1,
      color: color.withAlpha(TioAlpha.alpha50),
    );
  }
}

/// Renders an amount with the comparator its rule carries.
///
/// Sodium and added sugar are strictly *below* their numbers, so rendering a
/// bare "2,000 mg" would present the forbidden boundary as the goal itself.
/// The comparator belongs to the nutrient's policy, not to the value.
String formatNutrientGoalAmount(
  NutrientId nutrientId,
  double value,
  NutrientGoalComparison comparison,
) {
  final amount = formatNutrientAmount(nutrientId, value);
  return comparison == NutrientGoalComparison.lessThan ? '< $amount' : amount;
}

/// Display precision for a reference amount.
///
/// Grams keep one decimal because the derived maxima land on values like
/// 22.2 g; milligrams and micrograms are whole numbers at these magnitudes.
/// Four-digit amounts are grouped so "2,000 mg" reads as prose rather than a
/// raw number.
String formatNutrientAmount(NutrientId nutrientId, double value) {
  final unit = nutrientId.canonicalUnit;
  final decimals = unit == NutrientUnit.g ? 1 : 0;
  final text = _trimTrailingZero(value.toStringAsFixed(decimals));
  return '${_groupThousands(text)} ${unit.storageValue}';
}

String _trimTrailingZero(String value) =>
    value.contains('.') ? value.replaceFirst(RegExp(r'\.?0+$'), '') : value;

String _groupThousands(String value) {
  final parts = value.split('.');
  final digits = parts.first;
  if (digits.length < 4) return value;

  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return parts.length > 1 ? '$buffer.${parts[1]}' : buffer.toString();
}
