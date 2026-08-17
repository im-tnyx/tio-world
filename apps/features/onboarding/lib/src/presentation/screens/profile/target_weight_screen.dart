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

  String get _displayValue {
    final kg = valueKg ?? _defaultKg;
    if (unit == 'lbs') {
      final lbs = kg * 2.20462;
      return '${lbs.toStringAsFixed(1)} lbs';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  ({String badge, String diffText, String message, Color color}) _getTargetAnalysis() {
    final target = valueKg ?? _defaultKg;
    final current = currentWeightKg ?? target;
    final diffKg = target - current;
    final isLbs = unit == 'lbs';
    final diffVal = isLbs ? diffKg * 2.20462 : diffKg;
    final diffAbs = diffVal.abs();
    final unitLabel = isLbs ? 'lbs' : 'kg';

    if (diffAbs < 0.2) {
      return (
        badge: 'Maintain',
        diffText: '0.0 $unitLabel',
        message: 'Your plan will focus on body recomposition, stamina, and overall vitality.',
        color: const Color(0xFF38BDF8),
      );
    } else if (diffKg < 0) {
      final diffStr = '-${diffAbs.toStringAsFixed(1)} $unitLabel';
      if (diffAbs <= (isLbs ? 33 : 15)) {
        return (
          badge: 'Weight Loss',
          diffText: diffStr,
          message: 'Sustainable calorie deficit and cardio-strength blend will achieve this safely.',
          color: const Color(0xFF4ADE80),
        );
      } else {
        return (
          badge: 'Ambitious Loss',
          diffText: diffStr,
          message: 'Ambitious target. We will pace your progression in sustainable phased cycles.',
          color: const Color(0xFFFBBF24),
        );
      }
    } else {
      final diffStr = '+${diffAbs.toStringAsFixed(1)} $unitLabel';
      if (diffAbs <= (isLbs ? 22 : 10)) {
        return (
          badge: 'Muscle Gain',
          diffText: diffStr,
          message: 'Hypertrophy resistance workouts and protein surplus will fuel lean gains.',
          color: const Color(0xFF4ADE80),
        );
      } else {
        return (
          badge: 'Significant Gain',
          diffText: diffStr,
          message: 'High calorie surplus and progressive overload will drive healthy mass growth.',
          color: const Color(0xFFFBBF24),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
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
          const SizedBox(height: 8),

          // Large Bold Value Header (Syncs with kg vs lbs unit)
          Center(
            child: Text(
              _displayValue,
              key: const ValueKey('profile-target-weight-display'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Live Target Analysis Card (100% Identical pattern to CurrentWeightScreen BMI Card)
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
                // Top Row: Difference Label + Value + Status Badge (Identical to BMI row)
                Row(
                  children: [
                    Text(
                      'Difference  ',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      analysis.diffText,
                      style: TextStyle(
                        color: analysis.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: TioSpacing.medium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: analysis.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(TioRadius.full),
                        border: Border.all(
                          color: analysis.color.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        analysis.badge,
                        style: TextStyle(
                          color: analysis.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description text
                Text(
                  analysis.message,
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
