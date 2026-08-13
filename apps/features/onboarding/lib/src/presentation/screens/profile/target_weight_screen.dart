import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class TargetWeightScreen extends StatelessWidget {
  const TargetWeightScreen(
      {required this.valueKg,
      required this.onChanged,
      super.key,
      this.errorText});

  final double? valueKg;
  final ValueChanged<double?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.targetWeight,
      title: 'What is your target weight?',
      description:
          'Choose your own target from 30 to 200 kg. No target is auto-calculated here.',
      child: TioInput(
        key: const ValueKey('profile-target-weight-input'),
        value: profileNumberValue(valueKg),
        onChanged: (value) => onChanged(double.tryParse(value)),
        label: 'Target weight (kg)',
        hint: '68',
        errorText: errorText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
