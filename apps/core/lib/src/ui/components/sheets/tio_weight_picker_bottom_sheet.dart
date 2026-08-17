import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final val = isKg
        ? widget.initialWeightKg
        : (widget.initialWeightKg * 2.20462);

    _controller = TextEditingController(text: val.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final raw = double.tryParse(_controller.text.trim());
    if (raw == null) {
      Navigator.of(context).pop(widget.initialWeightKg);
      return;
    }

    final isKg = widget.unit == 'kg';
    final resolvedKg = isKg ? raw : (raw / 2.20462);

    if (resolvedKg >= 25 && resolvedKg <= 350) {
      Navigator.of(context).pop(resolvedKg);
    } else {
      Navigator.of(context).pop(widget.initialWeightKg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final isKg = widget.unit == 'kg';

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
                      'Weight',
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
                'Weight is important for calculating BMI, estimating calorie needs, and personalizing your fitness plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 28),

              // ── Weight Input Capsule ──
              Container(
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
                      isKg ? 'kg' : 'lbs',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
