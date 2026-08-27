import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class TargetWeightScreen extends StatelessWidget {
  const TargetWeightScreen({
    required this.valueKg,
    required this.onChanged,
    required this.weightGoalDirection,
    this.unit = 'kg',
    this.currentWeightKg,
    this.heightCm,
    this.onContinue,
    this.isBusy = false,
    super.key,
    this.errorText,
  });

  final double? valueKg;
  final ValueChanged<double> onChanged;
  final GoalWeightDirection? weightGoalDirection;
  final String unit;
  final double? currentWeightKg;
  final double? heightCm;
  final VoidCallback? onContinue;
  final bool isBusy;
  final String? errorText;

  static const double _defaultKg = 68.0;

  bool get _usesPounds => unit == 'lb' || unit == 'lbs';

  String get _displayValue {
    final kg = valueKg ?? currentWeightKg ?? _defaultKg;
    return UnitFormatters.formatWeight(
      kg,
      _usesPounds ? WeightUnit.lb : WeightUnit.kg,
    );
  }

  ({String badge, String diffText, String message, Color color})
      _getTargetAnalysis() {
    final target = valueKg ?? currentWeightKg ?? _defaultKg;
    final current = currentWeightKg ?? target;
    final diffKg = target - current;
    final diffVal = _usesPounds ? UnitConverters.kgToLb(diffKg) : diffKg;
    final diffAbs = diffVal.abs();
    final unitLabel = _usesPounds ? 'lb' : 'kg';
    final diffText = diffAbs < 0.05
        ? '0.0 $unitLabel'
        : '${diffVal > 0 ? '+' : '-'}${diffAbs.toStringAsFixed(1)} $unitLabel';

    return switch (weightGoalDirection) {
      GoalWeightDirection.loss => diffKg >= 0
          ? (
              badge: 'Weight Loss',
              diffText: diffText,
              message: 'Choose a target below your current weight for this goal.',
              color: TioDomainColors.healthWarning,
            )
          : diffAbs <= (_usesPounds ? 33 : 15)
              ? (
                  badge: 'Weight Loss',
                  diffText: diffText,
                  message:
                      'A steady target supports sustainable progress toward your weight-loss goal.',
                  color: TioDomainColors.healthPositive,
                )
              : (
                  badge: 'Ambitious Loss',
                  diffText: diffText,
                  message:
                      'Ambitious target. We will pace your progression in sustainable phased cycles.',
                  color: TioDomainColors.healthWarning,
                ),
      GoalWeightDirection.gain => diffKg <= 0
          ? (
              badge: 'Weight Gain',
              diffText: diffText,
              message: 'Choose a target above your current weight for this goal.',
              color: TioDomainColors.healthWarning,
            )
          : diffAbs <= (_usesPounds ? 22 : 10)
              ? (
                  badge: 'Weight Gain',
                  diffText: diffText,
                  message:
                      'A steady target supports healthy progress toward your weight-gain goal.',
                  color: TioDomainColors.healthPositive,
                )
              : (
                  badge: 'Significant Gain',
                  diffText: diffText,
                  message:
                      'A larger target change should be approached gradually and sustainably.',
                  color: TioDomainColors.healthWarning,
                ),
      null => (
          badge: 'Target',
          diffText: diffText,
          message: 'Adjust your target to match the goal you selected.',
          color: TioDomainColors.healthInfo,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final analysis = _getTargetAnalysis();

    return ProfileScreenScaffold(
      stepId: ProfileStepId.targetWeight,
      title: 'What is your target weight?',
      description:
          'We use your target weight to create a personalized plan tailored to your goal.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TioSpacing.sm),
          Center(
            child: Text(
              _displayValue,
              key: const ValueKey('profile-target-weight-display'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioFontSize.size44,
                fontWeight: TioFontWeight.w900,
                letterSpacing: TioLetterSpacing.negative10,
              ),
            ),
          ),
          const SizedBox(height: TioSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: TioSize.dp20,
              vertical: TioSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(TioRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Difference  ',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: TioFontWeight.w600,
                        fontSize: TioFontSize.size15,
                      ),
                    ),
                    Text(
                      analysis.diffText,
                      style: TextStyle(
                        color: analysis.color,
                        fontWeight: TioFontWeight.w800,
                        fontSize: TioFontSize.size18,
                      ),
                    ),
                    const SizedBox(width: TioSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TioSize.dp10,
                        vertical: TioSize.dp3,
                      ),
                      decoration: BoxDecoration(
                        color: analysis.color.withAlpha(TioAlpha.alpha25),
                        borderRadius: BorderRadius.circular(TioRadius.full),
                        border: Border.all(
                          color: analysis.color.withAlpha(TioAlpha.alpha80),
                          width: TioStroke.width1,
                        ),
                      ),
                      child: Text(
                        analysis.badge,
                        style: TextStyle(
                          color: analysis.color,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  analysis.message,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: TioFontSize.size13,
                    height: TioLineHeight.height140,
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
