import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Available actions for one Exercise in an unsaved Create/Edit Routine draft.
enum RoutineExerciseOption { replace, remove }

/// Dismissing the sheet returns null and must never change the Routine draft.
Future<RoutineExerciseOption?> showRoutineExerciseOptionsSheet(
  BuildContext context,
) => showTioEditorSheet<RoutineExerciseOption>(
      context: context,
      useSafeArea: true,
      builder: (_) => const RoutineExerciseOptionsSheet(),
    );

class RoutineExerciseOptionsSheet extends StatelessWidget {
  const RoutineExerciseOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) => TioEditorSheet(
        key: const ValueKey('routine-exercise-options-sheet'),
        title: 'Exercise Options',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('routine-exercise-option-replace'),
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Replace Exercise'),
              onTap: () => Navigator.of(context)
                  .pop<RoutineExerciseOption>(RoutineExerciseOption.replace),
            ),
            ListTile(
              key: const ValueKey('routine-exercise-option-remove'),
              leading: Icon(
                Icons.delete_outline_rounded,
                color: context.tioColors.danger,
              ),
              title: Text(
                'Remove Exercise',
                style: TextStyle(color: context.tioColors.danger),
              ),
              onTap: () => Navigator.of(context)
                  .pop<RoutineExerciseOption>(RoutineExerciseOption.remove),
            ),
          ],
        ),
      );
}
