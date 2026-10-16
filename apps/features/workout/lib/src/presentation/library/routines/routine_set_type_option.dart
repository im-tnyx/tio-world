import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import 'routine_set_type_badge.dart';

/// A compact Set Type choice. Core owns the outlined card variant; Workout
/// owns its labels, Set badge and selected checkmark.
class RoutineSetTypeOption extends StatelessWidget {
  const RoutineSetTypeOption({
    required this.type,
    required this.normalNumber,
    required this.selected,
    required this.onTap,
    this.useEditSetNumberColor = false,
    super.key,
  });

  final RoutineSetType type;
  final int normalNumber;
  final bool selected;
  final VoidCallback onTap;
  final bool useEditSetNumberColor;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      RoutineSetType.normal => 'Normal Set',
      RoutineSetType.warmUp => 'Warm Up Set',
      RoutineSetType.failure => 'Failure Set',
      RoutineSetType.drop => 'Drop Set',
    };

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: TioCard(
        variant: TioCardVariant.outlined,
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.md,
          vertical: TioSpacing.sm,
        ),
        onTap: onTap,
        child: Row(
          children: [
            RoutineSetTypeBadge(
              setType: type,
              normalNumber: normalNumber,
              useEditSetNumberColor: useEditSetNumberColor,
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: TioSpacing.sm),
              const Icon(Icons.check),
            ],
          ],
        ),
      ),
    );
  }
}

/// Same compact Core outlined surface for the destructive Set action.
/// Selection and deletion remain owned by the calling Create/Edit page.
class RoutineRemoveSetOption extends StatelessWidget {
  const RoutineRemoveSetOption({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: 'Remove Set',
      onTap: onTap,
      excludeSemantics: true,
      child: TioCard(
        variant: TioCardVariant.outlined,
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.md,
          vertical: TioSpacing.sm,
        ),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: TioSize.dp38,
              height: TioSize.dp38,
              child: Center(
                child: Icon(
                  Icons.delete_outline,
                  color: context.tioColors.danger,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Text(
                'Remove Set',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
