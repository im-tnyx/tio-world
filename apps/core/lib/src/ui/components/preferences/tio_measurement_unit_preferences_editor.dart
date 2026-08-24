import 'package:flutter/material.dart';

import '../../../measurement/measurement.dart';
import '../../../theme/theme.dart';

/// Shared editor for the four independent measurement-unit preferences.
///
/// Metric and Imperial are convenience presets only. Selecting an individual
/// category after a preset creates a mixed preference without changing any
/// canonical physical value. Mixed preferences expose a derived Custom preset
/// state; Custom is never persisted separately.
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
    final isCustom =
        !preferences.isMetricPreset && !preferences.isImperialPreset;
    final selectedPreset = preferences.isMetricPreset
        ? _MeasurementPreset.metric
        : preferences.isImperialPreset
            ? _MeasurementPreset.imperial
            : _MeasurementPreset.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          key: const ValueKey('measurement-units-preset-control'),
          alignment: Alignment.center,
          child: _PreferenceSegmentedControl<_MeasurementPreset>(
            key: const ValueKey('measurement-units-preset-segmented-control'),
            options: [
              const _SegmentOption(
                value: _MeasurementPreset.metric,
                label: 'Metric',
                key: ValueKey('measurement-units-preset-metric'),
              ),
              const _SegmentOption(
                value: _MeasurementPreset.imperial,
                label: 'Imperial',
                key: ValueKey('measurement-units-preset-imperial'),
              ),
              if (isCustom)
                const _SegmentOption(
                  value: _MeasurementPreset.custom,
                  label: 'Custom',
                  key: ValueKey('measurement-units-preset-custom'),
                ),
            ],
            selected: selectedPreset,
            onSelected: (preset) {
              switch (preset) {
                case _MeasurementPreset.metric:
                  onChanged(MeasurementUnitPreferences.metric);
                case _MeasurementPreset.imperial:
                  onChanged(MeasurementUnitPreferences.imperial);
                case _MeasurementPreset.custom:
                  break;
              }
            },
          ),
        ),
        const SizedBox(height: TioSpacing.xxl),
        _UnitPreferenceRow(
          label: 'Weight',
          control: _PreferenceSegmentedControl<WeightUnit>(
            options: const [
              _SegmentOption(
                value: WeightUnit.kg,
                label: 'kg',
                key: ValueKey('measurement-units-weight-kg'),
              ),
              _SegmentOption(
                value: WeightUnit.lb,
                label: 'lb',
                key: ValueKey('measurement-units-weight-lb'),
              ),
            ],
            selected: preferences.weightUnit,
            onSelected: (unit) => onChanged(
              preferences.copyWith(weightUnit: unit),
            ),
          ),
        ),
        const SizedBox(height: TioSpacing.xl),
        _UnitPreferenceRow(
          label: 'Height',
          control: _PreferenceSegmentedControl<HeightUnit>(
            options: const [
              _SegmentOption(
                value: HeightUnit.cm,
                label: 'cm',
                key: ValueKey('measurement-units-height-cm'),
              ),
              _SegmentOption(
                value: HeightUnit.ftIn,
                label: 'ft / in',
                key: ValueKey('measurement-units-height-ft-in'),
              ),
            ],
            selected: preferences.heightUnit,
            onSelected: (unit) => onChanged(
              preferences.copyWith(heightUnit: unit),
            ),
          ),
        ),
        const SizedBox(height: TioSpacing.xl),
        _UnitPreferenceRow(
          label: 'Distance',
          control: _PreferenceSegmentedControl<DistanceUnit>(
            options: const [
              _SegmentOption(
                value: DistanceUnit.km,
                label: 'km',
                key: ValueKey('measurement-units-distance-km'),
              ),
              _SegmentOption(
                value: DistanceUnit.mi,
                label: 'miles',
                key: ValueKey('measurement-units-distance-mi'),
              ),
            ],
            selected: preferences.distanceUnit,
            onSelected: (unit) => onChanged(
              preferences.copyWith(distanceUnit: unit),
            ),
          ),
        ),
        const SizedBox(height: TioSpacing.xl),
        _UnitPreferenceRow(
          label: 'Liquid volume',
          control: _PreferenceSegmentedControl<VolumeUnit>(
            options: const [
              _SegmentOption(
                value: VolumeUnit.ml,
                label: 'mL / L',
                key: ValueKey('measurement-units-volume-ml'),
              ),
              _SegmentOption(
                value: VolumeUnit.flOz,
                label: 'fl oz',
                key: ValueKey('measurement-units-volume-fl-oz'),
              ),
            ],
            selected: preferences.volumeUnit,
            onSelected: (unit) => onChanged(
              preferences.copyWith(volumeUnit: unit),
            ),
          ),
        ),
      ],
    );
  }
}

enum _MeasurementPreset { metric, imperial, custom }

class _UnitPreferenceRow extends StatelessWidget {
  const _UnitPreferenceRow({
    required this.label,
    required this.control,
  });

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: TioFontWeight.w600,
        );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: TioSpacing.lg,
      runSpacing: TioSpacing.sm,
      children: [
        Text(label, style: labelStyle),
        control,
      ],
    );
  }
}

class _PreferenceSegmentedControl<T extends Object> extends StatelessWidget {
  const _PreferenceSegmentedControl({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<_SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [
        for (final option in options)
          ButtonSegment<T>(
            value: option.value,
            label: Text(
              option.label,
              key: option.key,
              textAlign: TextAlign.center,
            ),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.single),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(TioSize.dp64, TioSize.dp44),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: TioSpacing.md,
            vertical: TioSpacing.sm,
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: TioFontWeight.w700),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceVariant;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.textPrimary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.outlineStrong.withAlpha(TioAlpha.alpha24),
            width: TioStroke.width1,
          );
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TioRadius.full),
          ),
        ),
      ),
    );
  }
}

class _SegmentOption<T extends Object> {
  const _SegmentOption({
    required this.value,
    required this.label,
    required this.key,
  });

  final T value;
  final String label;
  final Key key;
}
