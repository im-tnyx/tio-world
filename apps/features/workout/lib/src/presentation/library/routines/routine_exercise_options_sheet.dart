import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Common, feature-owned Exercise overflow surface for Create and Edit Routine.
///
/// The only approved action is removal. Additional Exercise actions may be
/// added here later without changing the header's stable overflow affordance.
/// Dismissing the sheet never mutates the Routine draft.
Future<bool> showRoutineExerciseOptionsSheet(BuildContext context) async {
  final remove = await showTioEditorSheet<bool>(
    context: context,
    useSafeArea: true,
    builder: (_) => const RoutineExerciseOptionsSheet(),
  );
  return remove == true;
}

class RoutineExerciseOptionsSheet extends StatelessWidget {
  const RoutineExerciseOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) => TioEditorSheet(
        key: const ValueKey('routine-exercise-options-sheet'),
        title: 'Exercise Options',
        content: ListTile(
          key: const ValueKey('routine-exercise-option-remove'),
          leading: Icon(
            Icons.delete_outline_rounded,
            color: context.tioColors.danger,
          ),
          title: Text(
            'Remove Exercise',
            style: TextStyle(color: context.tioColors.danger),
          ),
          onTap: () => Navigator.of(context).pop<bool>(true),
        ),
      );
}
