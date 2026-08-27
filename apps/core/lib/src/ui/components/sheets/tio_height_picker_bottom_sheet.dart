import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../units/units.dart';
import '../../../theme/theme.dart';
import '../buttons/tio_button.dart';

/// Shows the custom Height Picker Bottom Sheet matching the canonical design.
///
/// Supports both `cm` mode (single capsule input) and `ft` mode (dual ft + in capsule inputs).
Future<double?> showTioHeightPickerBottomSheet({
  required BuildContext context,
  required double initialHeightCm,
  required String unit, // 'cm' or 'ft'
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => TioHeightPickerBottomSheet(
      initialHeightCm: initialHeightCm,
      unit: unit,
    ),
  );
}

class TioHeightPickerBottomSheet extends StatefulWidget {
  const TioHeightPickerBottomSheet({
    required this.initialHeightCm,
    required this.unit,
    super.key,
  });

  final double initialHeightCm;
  final String unit;

  @override
  State<TioHeightPickerBottomSheet> createState() =>
      _TioHeightPickerBottomSheetState();
}

class _TioHeightPickerBottomSheetState
    extends State<TioHeightPickerBottomSheet> {
  late TextEditingController _cmController;
  late TextEditingController _ftController;
  late TextEditingController _inController;

  @override
  void initState() {
    super.initState();
    final cm = widget.initialHeightCm;
    _cmController = TextEditingController(text: cm.toStringAsFixed(1));

    final display = UnitConverters.cmToFeetInches(cm);
    _ftController = TextEditingController(text: display.feet.toString());
    _inController = TextEditingController(text: display.inches.toString());
  }

  @override
  void dispose() {
    _cmController.dispose();
    _ftController.dispose();
    _inController.dispose();
    super.dispose();
  }

  void _save() {
    double? resolvedCm;

    if (widget.unit == 'cm') {
      resolvedCm = double.tryParse(_cmController.text.trim());
    } else {
      final feet = int.tryParse(_ftController.text.trim());
      final inches = int.tryParse(_inController.text.trim());
      if (feet != null &&
          inches != null &&
          feet >= 0 &&
          inches >= 0 &&
          inches <= 11) {
        resolvedCm = UnitConverters.feetInchesToCm(
          feet: feet,
          inches: inches,
        );
      }
    }

    if (resolvedCm != null &&
        resolvedCm.isFinite &&
        resolvedCm >= 50 &&
        resolvedCm <= 260) {
      Navigator.of(context).pop(resolvedCm);
    } else {
      Navigator.of(context).pop(widget.initialHeightCm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isFt = widget.unit == 'ft';

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioRadius.xl),
        ),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(
            TioMeasurementPickerTokens.sheetOutlineAlpha,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.lg,
            TioSpacing.lg,
            TioSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Height',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioMeasurementPickerTokens.titleFontSize,
                        letterSpacing:
                            TioMeasurementPickerTokens.titleLetterSpacing,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: TioMeasurementPickerTokens.closeButtonSize,
                      height: TioMeasurementPickerTokens.closeButtonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.outlineStrong.withAlpha(
                          TioMeasurementPickerTokens.closeContainerAlpha,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                          size: TioMeasurementPickerTokens.closeIconSize,
                        ),
                        splashRadius:
                            TioMeasurementPickerTokens.closeSplashRadius,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: TioMeasurementPickerTokens.headerSubtitleGap,
              ),
              Text(
                'Height is important for calculating BMI, estimating calorie needs, and personalizing your fitness plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioMeasurementPickerTokens.subtitleFontSize,
                  height: TioMeasurementPickerTokens.subtitleLineHeight,
                  fontWeight: TioFontWeight.w400,
                ),
              ),
              const SizedBox(
                height: TioMeasurementPickerTokens.inputSectionGap,
              ),
              if (isFt)
                Row(
                  children: [
                    Expanded(
                      child: _HeightInputCapsule(
                        controller: _ftController,
                        suffix: 'ft',
                        colors: colors,
                      ),
                    ),
                    const SizedBox(
                      width: TioMeasurementPickerTokens.dualInputGap,
                    ),
                    Expanded(
                      child: _HeightInputCapsule(
                        controller: _inController,
                        suffix: 'in',
                        colors: colors,
                      ),
                    ),
                  ],
                )
              else
                _HeightInputCapsule(
                  controller: _cmController,
                  suffix: 'cm',
                  colors: colors,
                ),
              const SizedBox(
                height: TioMeasurementPickerTokens.inputSectionGap,
              ),
              TioButton.primary(
                label: 'Save',
                expand: true,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeightInputCapsule extends StatelessWidget {
  const _HeightInputCapsule({
    required this.controller,
    required this.suffix,
    required this.colors,
  });

  final TextEditingController controller;
  final String suffix;
  final TioColors colors;

  @override
  Widget build(BuildContext context) {
    final supportsDecimal = suffix == 'cm';

    return Container(
      height: TioMeasurementPickerTokens.inputHeight,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(
          TioMeasurementPickerTokens.inputRadius,
        ),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(
            TioMeasurementPickerTokens.inputOutlineAlpha,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: TioMeasurementPickerTokens.inputHorizontalPadding,
      ),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: supportsDecimal,
              ),
              inputFormatters: supportsDecimal
                  ? [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ]
                  : [FilteringTextInputFormatter.digitsOnly],
              cursorColor: colors.primary,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioMeasurementPickerTokens.inputTextFontSize,
                fontWeight: TioFontWeight.w700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            suffix,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioMeasurementPickerTokens.unitFontSize,
              fontWeight: TioFontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
