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

  final MeasurementUnitPreferences preferences;
  final ValueChanged<MeasurementUnitPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.measurementUnits,
      title: 'Choose your units',
      description:
          'Choose how measurements are shown. Presets are optional—you can mix units to match your preference.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Preset'),
          _UnitChoiceRow(
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
            leftLabel: 'kg',
            rightLabel: 'lb',
            leftSelected: preferences.weightUnit == WeightUnit.kg,
            rightSelected: preferences.weightUnit == WeightUnit.lb,
            onLeft: () => onChanged(preferences.copyWith(weightUnit: WeightUnit.kg)),
            onRight: () => onChanged(preferences.copyWith(weightUnit: WeightUnit.lb)),
          ),
          const SizedBox(height: TioSpacing.large),
          const _SectionLabel('Height'),
          _UnitChoiceRow(
            leftLabel: 'cm',
            rightLabel: 'ft / in',
            leftSelected: preferences.heightUnit == HeightUnit.cm,
            rightSelected: preferences.heightUnit == HeightUnit.ftIn,
            onLeft: () => onChanged(preferences.copyWith(heightUnit: HeightUnit.cm)),
            onRight: () => onChanged(preferences.copyWith(heightUnit: HeightUnit.ftIn)),
          ),
          const SizedBox(height: TioSpacing.large),
          const _SectionLabel('Distance'),
          _UnitChoiceRow(
            leftLabel: 'km',
            rightLabel: 'mi',
            leftSelected: preferences.distanceUnit == DistanceUnit.km,
            rightSelected: preferences.distanceUnit == DistanceUnit.mi,
            onLeft: () => onChanged(preferences.copyWith(distanceUnit: DistanceUnit.km)),
            onRight: () => onChanged(preferences.copyWith(distanceUnit: DistanceUnit.mi)),
          ),
          const SizedBox(height: TioSpacing.large),
          const _SectionLabel('Water & volume'),
          _UnitChoiceRow(
            leftLabel: 'mL / L',
            rightLabel: 'fl oz',
            leftSelected: preferences.volumeUnit == VolumeUnit.ml,
            rightSelected: preferences.volumeUnit == VolumeUnit.flOz,
            onLeft: () => onChanged(preferences.copyWith(volumeUnit: VolumeUnit.ml)),
            onRight: () => onChanged(preferences.copyWith(volumeUnit: VolumeUnit.flOz)),
          ),
        ],
      ),
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
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
  });

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
          child: leftSelected
              ? TioButton.primary(
                  label: leftLabel,
                  onPressed: onLeft,
                  expand: true,
                )
              : TioButton.secondary(
                  label: leftLabel,
                  onPressed: onLeft,
                  expand: true,
                ),
        ),
        const SizedBox(width: TioSpacing.medium),
        Expanded(
          child: rightSelected
              ? TioButton.primary(
                  label: rightLabel,
                  onPressed: onRight,
                  expand: true,
                )
              : TioButton.secondary(
                  label: rightLabel,
                  onPressed: onRight,
                  expand: true,
                ),
        ),
      ],
    );
  }
}
