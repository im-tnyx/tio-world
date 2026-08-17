import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

enum _WaterDisplayUnit { litres, ml, oz }

class WaterTargetScreen extends StatefulWidget {
  const WaterTargetScreen({
    required this.waterMl,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final int waterMl;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  State<WaterTargetScreen> createState() => _WaterTargetScreenState();
}

class _WaterTargetScreenState extends State<WaterTargetScreen> {
  _WaterDisplayUnit _displayUnit = _WaterDisplayUnit.litres;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isRecommended = widget.waterMl >= 2000 && widget.waterMl <= 4000;

    final displayValueText = switch (_displayUnit) {
      _WaterDisplayUnit.litres => WaterUnitConverter.formatLitres(widget.waterMl),
      _WaterDisplayUnit.ml => WaterUnitConverter.formatMl(widget.waterMl),
      _WaterDisplayUnit.oz => WaterUnitConverter.formatOz(widget.waterMl),
    };

    final displayUnitSuffix = switch (_displayUnit) {
      _WaterDisplayUnit.litres => 'L/day',
      _WaterDisplayUnit.ml => 'ml/day',
      _WaterDisplayUnit.oz => 'oz/day',
    };

    return TargetsScreenScaffold(
      stepId: TargetStepId.waterTarget,
      title: 'Daily hydration target',
      description:
          'Adequate hydration supports energy, digestion, and exercise recovery.',
      errorText: widget.errorText,
      child: Column(
        children: [
          TioCard(
            key: const ValueKey('targets-water-card'),
            variant: TioCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          color: colors.info,
                          size: 24,
                        ),
                        const SizedBox(width: TioSpacing.small),
                        Text(
                          'Water Target',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    DropdownButton<_WaterDisplayUnit>(
                      key: const ValueKey('targets-water-unit-dropdown'),
                      value: _displayUnit,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      items: const [
                        DropdownMenuItem(
                          value: _WaterDisplayUnit.litres,
                          child: Text('L'),
                        ),
                        DropdownMenuItem(
                          value: _WaterDisplayUnit.ml,
                          child: Text('ml'),
                        ),
                        DropdownMenuItem(
                          value: _WaterDisplayUnit.oz,
                          child: Text('oz'),
                        ),
                      ],
                      onChanged: (unit) {
                        if (unit != null) {
                          setState(() => _displayUnit = unit);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.medium),
                Center(
                  child: Column(
                    children: [
                      Text(
                        displayValueText,
                        key: const ValueKey('targets-water-value-text'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayUnitSuffix,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: TioSpacing.medium),
                Slider(
                  key: const ValueKey('targets-water-slider'),
                  value: widget.waterMl
                      .clamp(
                        TargetStepValidator.minWaterMl,
                        TargetStepValidator.maxWaterMl,
                      )
                      .toDouble(),
                  min: TargetStepValidator.minWaterMl.toDouble(), // 1000
                  max: TargetStepValidator.maxWaterMl.toDouble(), // 8000
                  divisions: 70, // 100 ml steps from 1000 to 8000
                  activeColor: colors.primary,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    widget.onChanged(val.round());
                  },
                ),
                Center(
                  child: TargetsStatusChip(
                    label: isRecommended ? 'Recommended' : 'Not Recommended',
                    isRecommended: isRecommended,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.large),
          Text(
            'Drinking 2.0–4.0 L (68–135 oz) of water daily is recommended for most active adults to maintain optimal hydration and performance.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
