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
        color: const Color(0xFF38BDF8),
        message: 'Your weight is below the standard recommended healthy range.',
      );
    } else if (bmi < 25.0) {
      return (
        title: 'Normal Weight',
        color: const Color(0xFF4ADE80),
        message: 'Your body mass index is within a healthy and balanced range.',
      );
    } else if (bmi < 30.0) {
      return (
        title: 'Overweight',
        color: const Color(0xFFFBBF24),
        message: 'Slightly above standard range. Regular exercise can optimize health.',
      );
    } else {
      return (
        title: 'High Risk',
        color: const Color(0xFFF87171),
        message: 'Consider consulting a healthcare specialist for tailored guidance.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
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
          const SizedBox(height: 8),
          Center(
            child: Text(
              _displayValue,
              key: const ValueKey('profile-current-weight-display'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(TioRadius.large),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        color: bmiCategory.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: TioSpacing.medium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: bmiCategory.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(TioRadius.full),
                        border: Border.all(
                          color: bmiCategory.color.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bmiCategory.title,
                        style: TextStyle(
                          color: bmiCategory.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bmiCategory.message,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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
