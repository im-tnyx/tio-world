import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../units/units.dart';
import '../../../theme/theme.dart';
import '../buttons/tio_button.dart';

/// Shows the custom Weight Picker Bottom Sheet matching the canonical design.
///
/// Supports both `kg` and `lbs` modes with instant conversion.
Future<double?> showTioWeightPickerBottomSheet({
  required BuildContext context,
  required double initialWeightKg,
  required String unit, // 'kg' or 'lbs'
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => TioWeightPickerBottomSheet(
      initialWeightKg: initialWeightKg,
      unit: unit,
    ),
  );
}

class TioWeightPickerBottomSheet extends StatefulWidget {
  const TioWeightPickerBottomSheet({
    required this.initialWeightKg,
    required this.unit,
    super.key,
  });

  final double initialWeightKg;
  final String unit;

  @override
  State<TioWeightPickerBottomSheet> createState() =>
      _TioWeightPickerBottomSheetState();
}

class _TioWeightPickerBottomSheetState
    extends State<TioWeightPickerBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final isKg = widget.unit == 'kg';
    final value = isKg
        ? widget.initialWeightKg
        : UnitConverters.kgToLb(widget.initialWeightKg);

    _controller = TextEditingController(text: value.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final raw = double.tryParse(_controller.text.trim());
    if (raw == null || !raw.isFinite) {
      Navigator.of(context).pop(widget.initialWeightKg);
      return;
    }

    final isKg = widget.unit == 'kg';
    final resolvedKg = isKg ? raw : UnitConverters.lbToKg(raw);

    if (resolvedKg.isFinite && resolvedKg >= 25 && resolvedKg <= 350) {
      Navigator.of(context).pop(resolvedKg);
    } else {
      Navigator.of(context).pop(widget.initialWeightKg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isKg = widget.unit == 'kg';

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
                      'Weight',
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
                'Weight is important for calculating BMI, estimating calorie needs, and personalizing your fitness plan.',
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
              Container(
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
                        controller: _controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        cursorColor: colors.primary,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize:
                              TioMeasurementPickerTokens.inputTextFontSize,
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
                      isKg ? 'kg' : 'lbs',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: TioMeasurementPickerTokens.unitFontSize,
                        fontWeight: TioFontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
