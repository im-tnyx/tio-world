import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

/// Compatibility placeholder for Nutrition Target step.
///
/// Blocked by formula authority (Path C): Android reference contains conflicting
/// formula families for calorie/macro recommendation, and no canonical authority
/// exists yet in local nutrition/shared domains.
class TargetsCompatibilityScreen extends StatelessWidget {
  const TargetsCompatibilityScreen({
    required this.stepId,
    super.key,
    this.errorText,
  });

  final TargetStepId stepId;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return TargetsScreenScaffold(
      stepId: stepId,
      title: 'Nutrition targets',
      description:
          'Daily calorie budget and macronutrient breakdown recommendations will land here.',
      errorText: errorText,
      child: Column(
        children: [
          TioCard(
            key: const ValueKey('targets-compat-nutritionTarget'),
            variant: TioCardVariant.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      color: colors.info,
                      size: TioSize.dp22,
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    Text(
                      'Blocked by Formula Authority',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: TioFontWeight.w600,
                            color: colors.info,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  'Daily calorie and macronutrient (protein, carbs, fat, fiber) recommendation requires an approved canonical formula from the nutrition domain. Onboarding remains navigation-passable for preview, but completion is gated until approved calculations are provided.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
