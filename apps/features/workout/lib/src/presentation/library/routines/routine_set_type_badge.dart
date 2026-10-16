import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_composition_repository.dart';

/// The Normal number a selected Set would display if chosen as Normal.
/// Warm Up, Failure and Drop Sets do not advance Normal numbering.
int routineNormalNumberForSelection(
  List<RoutineCompositionSet> sets,
  String selectedSetId,
) {
  var normalNumber = 1;
  for (final set in sets) {
    if (set.id == selectedSetId) return normalNumber;
    if (set.prescription.setType == RoutineSetType.normal) normalNumber++;
  }
  return normalNumber;
}

/// Workout-owned type indicator used in both the Set grid and picker sheets.
/// Color, shape, legibility and numbering have one presentation owner.
class RoutineSetTypeBadge extends StatelessWidget {
  const RoutineSetTypeBadge({
    required this.setType,
    required this.normalNumber,
    this.useEditSetNumberColor = false,
    this.containerKey,
    super.key,
  });

  final RoutineSetType setType;
  final int normalNumber;
  final bool useEditSetNumberColor;

  /// Preserves existing widget-test and semantics finder keys on the
  /// actual painted Container, rather than on a parent widget.
  final Key? containerKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final preferred = switch (setType) {
      RoutineSetType.normal =>
        useEditSetNumberColor ? colors.primary : colors.textPrimary,
      RoutineSetType.warmUp => colors.warning,
      RoutineSetType.failure => colors.danger,
      RoutineSetType.drop => colors.info,
    };
    final text = switch (setType) {
      RoutineSetType.normal => '$normalNumber',
      RoutineSetType.warmUp => 'W',
      RoutineSetType.failure => 'F',
      RoutineSetType.drop => 'D',
    };
    return Container(
      key: containerKey,
      width: TioSize.dp38,
      constraints: const BoxConstraints(minHeight: TioSize.dp38),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(TioInputTokens.radius),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _readableSetBadgeColor(preferred, colors.surfaceVariant),
        ),
      ),
    );
  }
}

// Keep the preferred type color when readable. In high-contrast themes the
// opaque surface may invert; black/white fallback guarantees >=4.5:1.
Color _readableSetBadgeColor(Color preferred, Color background) {
  final foregroundLuminance = preferred.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final contrast = foregroundLuminance > backgroundLuminance
      ? (foregroundLuminance + 0.05) / (backgroundLuminance + 0.05)
      : (backgroundLuminance + 0.05) / (foregroundLuminance + 0.05);
  if (contrast >= 4.5) return preferred;
  return backgroundLuminance > 0.179 ? TioPalette.black : TioPalette.white;
}
