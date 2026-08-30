import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Thin Product Onboarding adapter over the shared [TioWeightWheel] core
/// primitive: preserves this widget's existing String-based `unit` API
/// (`'kg'` / `'lbs'`) and its exact prior 30-200kg / 66-440lbs bounds and
/// kg/lbs unit-switcher behavior, so no onboarding call site or rendered
/// behavior changes.
class OnboardingWeightWheel extends StatelessWidget {
  const OnboardingWeightWheel({
    required this.valueKg,
    required this.onChanged,
    this.unit = 'kg',
    this.onUnitChanged,
    super.key,
  });

  final double? valueKg;
  final ValueChanged<double> onChanged;
  final String unit;
  final ValueChanged<String>? onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return TioWeightWheel(
      valueKg: valueKg,
      onChanged: onChanged,
      unit: unit == 'lbs' ? WeightUnit.lb : WeightUnit.kg,
      onUnitChanged: onUnitChanged == null
          ? null
          : (weightUnit) =>
              onUnitChanged!(weightUnit == WeightUnit.lb ? 'lbs' : 'kg'),
      minLbs: 66,
      maxLbs: 440,
    );
  }
}
