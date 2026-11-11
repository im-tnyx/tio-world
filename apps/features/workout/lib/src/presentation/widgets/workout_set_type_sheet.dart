import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_composition_repository.dart';
import '../library/routines/routine_set_type_badge.dart';
import '../library/routines/routine_set_type_option.dart';

/// Shows the bottom sheet for selecting a set type or removing a set.
///
/// Shared across both Routine editing and Active Workout logging.
Future<Object?> showWorkoutSetTypeSheet({
  required BuildContext context,
  required List<RoutineCompositionSet> sets,
  required RoutineCompositionSet targetSet,
  bool allowRemove = true,
}) {
  return showTioEditorSheet<Object>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => TioEditorSheet(
      title: 'Select Set Type',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in RoutineSetType.values) ...[
            RoutineSetTypeOption(
              key: ValueKey('routine-type-option-${type.wireValue}'),
              type: type,
              normalNumber:
                  routineNormalNumberForSelection(sets, targetSet.id),
              selected: type == targetSet.prescription.setType,
              onTap: () => Navigator.of(sheetContext).pop<Object>(type),
            ),
            const SizedBox(height: TioSpacing.sm),
          ],
          if (allowRemove)
            RoutineRemoveSetOption(
              key: const ValueKey('routine-type-remove-set'),
              onTap: () => Navigator.of(sheetContext).pop<Object>('remove'),
            ),
        ],
      ),
    ),
  );
}
