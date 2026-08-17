import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class HeightScreen extends StatelessWidget {
  const HeightScreen({
    required this.valueCm,
    required this.onChanged,
    this.unit = 'cm',
    this.onContinue,
    this.isBusy = false,
    super.key,
    this.errorText,
  });

  final double? valueCm;
  final ValueChanged<double> onChanged;
  final String unit;
  final VoidCallback? onContinue;
  final bool isBusy;
  final String? errorText;

  static const double _defaultCm = 170.0;

  String get _displayValue {
    final cm = valueCm ?? _defaultCm;
    if (unit == 'in' || unit == 'ft') {
      final totalInches = (cm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return '$feet ft $inches in';
    } else {
      if (cm % 1 == 0) {
        return '${cm.toInt()} cm';
      } else {
        return '${cm.toStringAsFixed(1)} cm';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return ProfileScreenScaffold(
      stepId: ProfileStepId.height,
      title: 'What is your height?',
      description: 'Calculating your body mass index requires your height.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Large Bold Value Header (Syncs with cm vs ft/in unit)
          Center(
            child: Text(
              _displayValue,
              key: const ValueKey('profile-height-display'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // BMI Info Card
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
                Text(
                  'Calculating your body mass index',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'BMI is widely used as a risk indicator for the development or prevalence of several health issues',
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
