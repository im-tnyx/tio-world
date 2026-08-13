import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class CurrentWeightScreen extends StatelessWidget {
  const CurrentWeightScreen(
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
      stepId: ProfileStepId.currentWeight,
      title: 'What is your current weight?',
      description: 'Enter a value from 30 to 200 kg.',
      child: TioInput(
        key: const ValueKey('profile-current-weight-input'),
        value: profileNumberValue(valueKg),
        onChanged: (value) => onChanged(double.tryParse(value)),
        label: 'Current weight (kg)',
        hint: '70',
        errorText: errorText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
