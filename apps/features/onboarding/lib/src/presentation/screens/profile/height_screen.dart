import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class HeightScreen extends StatelessWidget {
  const HeightScreen(
      {required this.valueCm,
      required this.onChanged,
      super.key,
      this.errorText});

  final double? valueCm;
  final ValueChanged<double?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.height,
      title: 'What is your height?',
      description: 'Enter a value from 100 to 250 cm.',
      child: TioInput(
        key: const ValueKey('profile-height-input'),
        value: profileNumberValue(valueCm),
        onChanged: (value) => onChanged(double.tryParse(value)),
        label: 'Height (cm)',
        hint: '171',
        errorText: errorText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
