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
    final colors = TioTheme.colors(context);
    final isFt = widget.unit == 'ft';

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioRadius.extraLarge),
        ),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(25),
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
                        fontSize: 24,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.outlineStrong.withAlpha(50),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                          size: 18,
                        ),
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Subtitle ──
              Text(
                'Height is important for calculating BMI, estimating calorie needs, and personalizing your fitness plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 28),

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
                    const SizedBox(width: 14),
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

              const SizedBox(height: 28),

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
      height: 64,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                fontSize: 24,
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
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
