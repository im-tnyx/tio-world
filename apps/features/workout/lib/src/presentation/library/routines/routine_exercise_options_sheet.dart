import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Available actions for one Exercise in an unsaved Create/Edit Routine draft.
enum RoutineExerciseOption { replace, remove, addToSuperset, removeFromSuperset }

/// Dismissing the sheet returns null and must never change the Routine draft.
Future<RoutineExerciseOption?> showRoutineExerciseOptionsSheet(
  BuildContext context, {
  bool isGrouped = false,
  bool canAddSupersetMember = true,
  bool canRemoveFromSuperset = true,
  bool canReplaceExercise = true,
  bool canRemoveExercise = true,
  String? lockedMessage,
}) => showTioEditorSheet<RoutineExerciseOption>(
      context: context,
      useSafeArea: true,
      builder: (_) => RoutineExerciseOptionsSheet(
        isGrouped: isGrouped,
        canAddSupersetMember: canAddSupersetMember,
        canRemoveFromSuperset: canRemoveFromSuperset,
        canReplaceExercise: canReplaceExercise,
        canRemoveExercise: canRemoveExercise,
        lockedMessage: lockedMessage,
      ),
    );

class RoutineExerciseOptionsSheet extends StatelessWidget {
  const RoutineExerciseOptionsSheet({
    this.isGrouped = false,
    this.canAddSupersetMember = true,
    this.canRemoveFromSuperset = true,
    this.canReplaceExercise = true,
    this.canRemoveExercise = true,
    this.lockedMessage,
    super.key,
  });

  final bool isGrouped;
  final bool canAddSupersetMember;
  final bool canRemoveFromSuperset;
  final bool canReplaceExercise;
  final bool canRemoveExercise;
  final String? lockedMessage;

  @override
  Widget build(BuildContext context) => TioEditorSheet(
        key: const ValueKey('routine-exercise-options-sheet'),
        title: 'Exercise Options',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lockedMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.lg,
                  0,
                  TioSpacing.lg,
                  TioSpacing.sm,
                ),
                child: Text(
                  lockedMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.tioColors.textSecondary),
                ),
              ),
            if (canAddSupersetMember)
              ListTile(
                key: const ValueKey('routine-exercise-option-add-superset'),
                leading: const Icon(Icons.compare_arrows_rounded),
                title: Text(
                  isGrouped ? 'Add Exercise to Superset' : 'Add to Superset',
                ),
                onTap: () => Navigator.of(context).pop<RoutineExerciseOption>(
                  RoutineExerciseOption.addToSuperset,
                ),
              ),
            if (isGrouped && canRemoveFromSuperset)
              ListTile(
                key: const ValueKey('routine-exercise-option-remove-superset'),
                leading: const Icon(Icons.link_off_rounded),
                title: const Text('Remove from Superset'),
                onTap: () => Navigator.of(context).pop<RoutineExerciseOption>(
                  RoutineExerciseOption.removeFromSuperset,
                ),
              ),
            if (canReplaceExercise)
              ListTile(
              key: const ValueKey('routine-exercise-option-replace'),
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Replace Exercise'),
              onTap: () => Navigator.of(context)
                  .pop<RoutineExerciseOption>(RoutineExerciseOption.replace),
            ),
            if (canRemoveExercise)
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
