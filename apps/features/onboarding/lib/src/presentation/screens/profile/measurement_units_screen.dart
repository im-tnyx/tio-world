import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class MeasurementUnitsScreen extends StatelessWidget {
  const MeasurementUnitsScreen({
    required this.preferences,
    required this.onChanged,
    super.key,
  });

  final UnitPreferences preferences;
  final ValueChanged<UnitPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.measurementUnits,
      title: 'Choose your units',
      description:
          'Choose how measurements are shown. Presets are optional—you can mix units to match your preference.',
      child: TioMeasurementUnitPreferencesEditor(
        preferences: preferences,
        onChanged: onChanged,
      ),
    );
  }
}
