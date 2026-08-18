import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();

    _ftController = TextEditingController(text: feet.toString());
    _inController = TextEditingController(text: inches.toString());
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
      final ft = double.tryParse(_ftController.text.trim()) ?? 0;
      final inch = double.tryParse(_inController.text.trim()) ?? 0;
      resolvedCm = (ft * 12 + inch) * 2.54;
    }

    if (resolvedCm != null && resolvedCm >= 50 && resolvedCm <= 260) {
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
          top: Radius.circular(TioRadius.extraLarge),
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
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.extraLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: Title & Close Button ──
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Height',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
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

              // ── Subtitle ──
              Text(
                'Height is important for calculating BMI, estimating calorie needs, and personalizing your fitness plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioMeasurementPickerTokens.subtitleFontSize,
                  height: TioMeasurementPickerTokens.subtitleLineHeight,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(
                height: TioMeasurementPickerTokens.inputSectionGap,
              ),

              // ── Input Fields ──
              if (isFt)
                Row(
                  children: [
                    // Feet Box
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
                    // Inches Box
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

              // ── Save Button ──
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              cursorColor: colors.primary,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioMeasurementPickerTokens.inputTextFontSize,
                fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
