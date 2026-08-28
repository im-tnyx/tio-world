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
    final typedUnit = switch (unit) {
      'ft' || 'in' || 'ft_in' => HeightUnit.ftIn,
      _ => HeightUnit.cm,
    };
    return UnitFormatters.formatHeight(cm, typedUnit);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return ProfileScreenScaffold(
      stepId: ProfileStepId.height,
      title: 'What is your height?',
      description: 'Calculating your body mass index requires your height.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TioSpacing.sm),
          Center(
            child: Text(
              _displayValue,
              key: const ValueKey('profile-height-display'),
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
                Text(
                  'Calculating your body mass index',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                    fontSize: TioFontSize.size15,
                  ),
                ),
                const SizedBox(height: TioSize.dp6),
                Text(
                  'BMI is widely used as a risk indicator for the development or prevalence of several health issues',
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
