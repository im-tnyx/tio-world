import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class OnboardingDobWheel extends StatelessWidget {
  const OnboardingDobWheel({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  static const int _startYear = 1940;
  static final int _endYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TioWheelPickerTokens.viewportHeight,
      child: TioDobWheelPicker(
        initialDate: value ?? DateTime.now(),
        startYear: _startYear,
        endYear: _endYear,
        onChanged: onChanged,
      ),
    );
  }
}
