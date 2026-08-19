import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class CurrentWeightScreen extends StatelessWidget {
  const CurrentWeightScreen({
    required this.valueKg,
    required this.onChanged,
    this.unit = 'kg',
    this.heightCm,
    this.onContinue,
    this.isBusy = false,
    super.key,
    this.errorText,
  });

  final double? valueKg;
  final ValueChanged<double> onChanged;
  final String unit;
  final double? heightCm;
  final VoidCallback? onContinue;
  final bool isBusy;
  final String? errorText;

  static const double _defaultKg = 75.0;

  String get _displayValue {
    final kg = valueKg ?? _defaultKg;
    final typedUnit = unit == 'lb' || unit == 'lbs' ? WeightUnit.lb : WeightUnit.kg;
    return MeasurementFormatters.formatWeight(kg, typedUnit);
  }

  double get _currentBmi {
    final kg = valueKg ?? _defaultKg;
    final height = heightCm ?? 170.0;
    final heightM = height / 100.0;
    if (heightM <= 0) return 22.0;
    return kg / (heightM * heightM);
  }

  ({String title, Color color, String message}) _getBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return (
        title: 'Underweight',
        color: TioDomainColors.healthInfo,
        message: 'Your weight is below the standard recommended healthy range.',
      );
    } else if (bmi < 25.0) {
      return (
        title: 'Normal Weight',
        color: TioDomainColors.healthPositive,
        message: 'Your body mass index is within a healthy and balanced range.',
      );
    } else if (bmi < 30.0) {
      return (
        title: 'Overweight',
        color: TioDomainColors.healthWarning,
        message: 'Slightly above standard range. Regular exercise can optimize health.',
      );
    } else {
      return (
        title: 'High Risk',
        color: TioDomainColors.healthDanger,
        message: 'Consider consulting a healthcare specialist for tailored guidance.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final bmi = _currentBmi;
    final bmiCategory = _getBmiCategory(bmi);

    return ProfileScreenScaffold(
      stepId: ProfileStepId.currentWeight,
      title: 'What is your current weight?',
      description: 'Enter your current body weight to personalize targets.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TioSpacing.sm),
          Center(
            child: Text(
              _displayValue,
              key: const ValueKey('profile-current-weight-display'),
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
                      'BMI  ',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: TioFontWeight.w600,
                        fontSize: TioFontSize.size15,
                      ),
                    ),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        color: bmiCategory.color,
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
                        color: bmiCategory.color.withAlpha(TioAlpha.alpha25),
                        borderRadius: BorderRadius.circular(TioRadius.full),
                        border: Border.all(
                          color: bmiCategory.color.withAlpha(TioAlpha.alpha80),
                          width: TioStroke.width1,
                        ),
                      ),
                      child: Text(
                        bmiCategory.title,
                        style: TextStyle(
                          color: bmiCategory.color,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  bmiCategory.message,
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
