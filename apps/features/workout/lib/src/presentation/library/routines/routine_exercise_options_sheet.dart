import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Available Exercise actions; the Log Workout draft can opt into calculator.
enum RoutineExerciseOption {
  replace,
  remove,
  addToSuperset,
  removeFromSuperset,
  warmupMethods,
  warmupCalculator,
}

/// Dismissing the sheet returns null and never invokes an Exercise action.
Future<RoutineExerciseOption?> showRoutineExerciseOptionsSheet(
  BuildContext context, {
  bool isGrouped = false,
  bool canAddSupersetMember = true,
  bool canRemoveFromSuperset = true,
  bool canReplaceExercise = true,
  bool canRemoveExercise = true,
  bool canChooseWarmupMethod = false,
  bool canUseWarmupCalculator = false,
  String? lockedMessage,
}) =>
    showTioEditorSheet<RoutineExerciseOption>(
      context: context,
      useSafeArea: true,
      builder: (_) => RoutineExerciseOptionsSheet(
        isGrouped: isGrouped,
        canAddSupersetMember: canAddSupersetMember,
        canRemoveFromSuperset: canRemoveFromSuperset,
        canReplaceExercise: canReplaceExercise,
        canRemoveExercise: canRemoveExercise,
        canChooseWarmupMethod: canChooseWarmupMethod,
        canUseWarmupCalculator: canUseWarmupCalculator,
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
    this.canChooseWarmupMethod = false,
    this.canUseWarmupCalculator = false,
    this.lockedMessage,
    super.key,
  });

  final bool isGrouped;
  final bool canAddSupersetMember;
  final bool canRemoveFromSuperset;
  final bool canReplaceExercise;
  final bool canRemoveExercise;
  final bool canChooseWarmupMethod;
  final bool canUseWarmupCalculator;
  final String? lockedMessage;

  @override
  Widget build(BuildContext context) => TioEditorSheet(
        key: const ValueKey('routine-exercise-options-sheet'),
        title: 'Exercise Options',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              color: context.tioColors.outlineStrong.withValues(
                alpha: TioOpacity.opacity10,
              ),
              height: TioSize.dp1,
            ),
            if (canChooseWarmupMethod)
              ListTile(
                key: const ValueKey('routine-exercise-option-warmup-methods'),
                leading: Icon(
                  Icons.fitness_center_rounded,
                  color: context.tioColors.textSecondary,
                ),
                title: const Text('Warm-up methods'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.lg,
                  vertical: TioSpacing.xs,
                ),
                onTap: () => Navigator.of(context).pop<RoutineExerciseOption>(
                  RoutineExerciseOption.warmupMethods,
                ),
              ),
            if (canUseWarmupCalculator)
              ListTile(
                key: const ValueKey('routine-exercise-option-warmup'),
                leading: Icon(
                  Icons.add_rounded,
                  color: context.tioColors.textSecondary,
                ),
                title: const Text('Add warm-up sets'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.lg,
                  vertical: TioSpacing.xs,
                ),
                onTap: () => Navigator.of(context).pop<RoutineExerciseOption>(
                  RoutineExerciseOption.warmupCalculator,
                ),
              ),
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
              Divider(
                color: context.tioColors.outlineStrong.withValues(
                  alpha: TioOpacity.opacity10,
                ),
                height: TioSize.dp1,
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
