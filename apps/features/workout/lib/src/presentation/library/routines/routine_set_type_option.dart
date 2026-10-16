import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import 'routine_set_type_badge.dart';

/// One selectable Set Type option. Core owns the outlined selection surface;
/// Workout owns the Set badge and type labels.
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

    return TioSelectableCard(
      selected: selected,
      onTap: onTap,
      semanticLabel: label,
      child: Row(
        children: [
          ExcludeSemantics(
            child: RoutineSetTypeBadge(
              setType: type,
              normalNumber: normalNumber,
              useEditSetNumberColor: useEditSetNumberColor,
            ),
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
            const Icon(Icons.check, semanticLabel: null),
          ],
        ],
      ),
    );
  }
}
