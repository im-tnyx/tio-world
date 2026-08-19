import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class TargetWeightScreen extends StatelessWidget {
  const TargetWeightScreen({
    required this.valueKg,
    required this.onChanged,
    this.unit = 'kg',
    this.currentWeightKg,
    this.primaryGoalId,
    this.heightCm,
    this.onContinue,
    this.isBusy = false,
    super.key,
    this.errorText,
  });

  final double? valueKg;
  final ValueChanged<double> onChanged;
  final String unit;
  final double? currentWeightKg;
  final String? primaryGoalId;
  final double? heightCm;
  final VoidCallback? onContinue;
  final bool isBusy;
  final String? errorText;

  static const double _defaultKg = 68.0;

  bool get _usesPounds => unit == 'lb' || unit == 'lbs';

  String get _displayValue {
    final kg = valueKg ?? _defaultKg;
    return MeasurementFormatters.formatWeight(
      kg,
      _usesPounds ? WeightUnit.lb : WeightUnit.kg,
    );
  }

  ({String badge, String diffText, String message, Color color}) _getTargetAnalysis() {
    final target = valueKg ?? _defaultKg;
    final current = currentWeightKg ?? target;
    final diffKg = target - current;
    final diffVal = _usesPounds ? MeasurementConverters.kgToLb(diffKg) : diffKg;
    final diffAbs = diffVal.abs();
    final unitLabel = _usesPounds ? 'lb' : 'kg';

    if (diffAbs < 0.2) {
      return (
        badge: 'Maintain',
        diffText: '0.0 $unitLabel',
        message: 'Your plan will focus on body recomposition, stamina, and overall vitality.',
        color: TioDomainColors.healthInfo,
      );
    } else if (diffKg < 0) {
      final diffStr = '-${diffAbs.toStringAsFixed(1)} $unitLabel';
      if (diffAbs <= (_usesPounds ? 33 : 15)) {
        return (
          badge: 'Weight Loss',
          diffText: diffStr,
          message: 'Sustainable calorie deficit and cardio-strength blend will achieve this safely.',
          color: TioDomainColors.healthPositive,
        );
      } else {
        return (
          badge: 'Ambitious Loss',
          diffText: diffStr,
          message: 'Ambitious target. We will pace your progression in sustainable phased cycles.',
          color: TioDomainColors.healthWarning,
        );
      }
    } else {
      final diffStr = '+${diffAbs.toStringAsFixed(1)} $unitLabel';
      if (diffAbs <= (_usesPounds ? 22 : 10)) {
        return (
          badge: 'Muscle Gain',
          diffText: diffStr,
          message: 'Hypertrophy resistance workouts and protein surplus will fuel lean gains.',
          color: TioDomainColors.healthPositive,
        );
      } else {
        return (
          badge: 'Significant Gain',
          diffText: diffStr,
          message: 'High calorie surplus and progressive overload will drive healthy mass growth.',
          color: TioDomainColors.healthWarning,
        );
      }
    }
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
