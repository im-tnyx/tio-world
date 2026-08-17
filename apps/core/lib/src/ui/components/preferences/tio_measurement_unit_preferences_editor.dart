import 'package:flutter/material.dart';

import '../../../measurement/measurement.dart';
import '../../../theme/theme.dart';
import '../buttons/tio_button.dart';

/// Shared editor for the four independent measurement-unit preferences.
///
/// Metric and Imperial are convenience presets only. Selecting an individual
/// category after a preset creates a mixed preference without changing any
/// canonical physical value.
class TioMeasurementUnitPreferencesEditor extends StatelessWidget {
  const TioMeasurementUnitPreferencesEditor({
    required this.preferences,
    required this.onChanged,
    super.key,
  });

  final MeasurementUnitPreferences preferences;
  final ValueChanged<MeasurementUnitPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Preset'),
        _UnitChoiceRow(
          leftKey: const ValueKey('measurement-units-preset-metric'),
          rightKey: const ValueKey('measurement-units-preset-imperial'),
          leftLabel: 'Metric',
          rightLabel: 'Imperial',
          leftSelected: preferences.isMetricPreset,
          rightSelected: preferences.isImperialPreset,
          onLeft: () => onChanged(MeasurementUnitPreferences.metric),
          onRight: () => onChanged(MeasurementUnitPreferences.imperial),
        ),
        const SizedBox(height: TioSpacing.large),
        const _SectionLabel('Weight'),
        _UnitChoiceRow(
          leftKey: const ValueKey('measurement-units-weight-kg'),
          rightKey: const ValueKey('measurement-units-weight-lb'),
          leftLabel: 'kg',
          rightLabel: 'lb',
          leftSelected: preferences.weightUnit == WeightUnit.kg,
          rightSelected: preferences.weightUnit == WeightUnit.lb,
          onLeft: () => onChanged(
            preferences.copyWith(weightUnit: WeightUnit.kg),
          ),
          onRight: () => onChanged(
            preferences.copyWith(weightUnit: WeightUnit.lb),
          ),
        ),
        const SizedBox(height: TioSpacing.large),
        const _SectionLabel('Height'),
        _UnitChoiceRow(
          leftKey: const ValueKey('measurement-units-height-cm'),
          rightKey: const ValueKey('measurement-units-height-ft-in'),
          leftLabel: 'cm',
          rightLabel: 'ft / in',
          leftSelected: preferences.heightUnit == HeightUnit.cm,
          rightSelected: preferences.heightUnit == HeightUnit.ftIn,
          onLeft: () => onChanged(
            preferences.copyWith(heightUnit: HeightUnit.cm),
          ),
          onRight: () => onChanged(
            preferences.copyWith(heightUnit: HeightUnit.ftIn),
          ),
        ),
        const SizedBox(height: TioSpacing.large),
        const _SectionLabel('Distance'),
        _UnitChoiceRow(
          leftKey: const ValueKey('measurement-units-distance-km'),
          rightKey: const ValueKey('measurement-units-distance-mi'),
          leftLabel: 'km',
          rightLabel: 'mi',
          leftSelected: preferences.distanceUnit == DistanceUnit.km,
          rightSelected: preferences.distanceUnit == DistanceUnit.mi,
          onLeft: () => onChanged(
            preferences.copyWith(distanceUnit: DistanceUnit.km),
          ),
          onRight: () => onChanged(
            preferences.copyWith(distanceUnit: DistanceUnit.mi),
          ),
        ),
        const SizedBox(height: TioSpacing.large),
        const _SectionLabel('Water & volume'),
        _UnitChoiceRow(
          leftKey: const ValueKey('measurement-units-volume-ml'),
          rightKey: const ValueKey('measurement-units-volume-fl-oz'),
          leftLabel: 'mL / L',
          rightLabel: 'fl oz',
          leftSelected: preferences.volumeUnit == VolumeUnit.ml,
          rightSelected: preferences.volumeUnit == VolumeUnit.flOz,
          onLeft: () => onChanged(
            preferences.copyWith(volumeUnit: VolumeUnit.ml),
          ),
          onRight: () => onChanged(
            preferences.copyWith(volumeUnit: VolumeUnit.flOz),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: TioSpacing.small),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UnitChoiceRow extends StatelessWidget {
  const _UnitChoiceRow({
    required this.leftKey,
    required this.rightKey,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
  });

  final Key leftKey;
  final Key rightKey;
  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final bool rightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            selected: leftSelected,
            child: leftSelected
                ? TioButton.primary(
                    key: leftKey,
                    label: leftLabel,
                    onPressed: onLeft,
                    expand: true,
                  )
                : TioButton.secondary(
                    key: leftKey,
                    label: leftLabel,
                    onPressed: onLeft,
                    expand: true,
                  ),
          ),
        ),
        const SizedBox(width: TioSpacing.medium),
        Expanded(
          child: Semantics(
            selected: rightSelected,
            child: rightSelected
                ? TioButton.primary(
                    key: rightKey,
                    label: rightLabel,
                    onPressed: onRight,
                    expand: true,
                  )
                : TioButton.secondary(
                    key: rightKey,
                    label: rightLabel,
                    onPressed: onRight,
                    expand: true,
                  ),
          ),
        ),
      ],
    );
  }
}
