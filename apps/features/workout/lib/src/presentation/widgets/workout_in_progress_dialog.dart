import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// User choice when Play is pressed while a workout is already in progress.
enum WorkoutInProgressAction {
  resume,
  startNew,
  cancel,
}

/// Owner-approved conflict card for Play when a workout is already running.
Future<WorkoutInProgressAction?> showWorkoutInProgressDialog(
  BuildContext context,
) {
  return showDialog<WorkoutInProgressAction>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final colors = dialogContext.tioColors;
      const compactMinSize = WidgetStatePropertyAll<Size>(
        Size(TioButtonTokens.minimumWidth, TioSize.dp38),
      );
      final compactTheme = theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: (theme.filledButtonTheme.style ?? const ButtonStyle())
              .copyWith(minimumSize: compactMinSize),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: (theme.outlinedButtonTheme.style ?? const ButtonStyle())
              .copyWith(minimumSize: compactMinSize),
        ),
      );

      return Dialog(
        key: const ValueKey('workout-in-progress-dialog'),
        backgroundColor: TioPalette.transparent,
        elevation: TioElevation.none,
        insetPadding: const EdgeInsets.all(TioSpacing.lg),
        child: SizedBox(
          width: TioSize.dp320,
          child: SingleChildScrollView(
            child: TioCard(
              key: const ValueKey('workout-in-progress-card'),
              variant: TioCardVariant.elevated,
              padding: const EdgeInsets.all(TioSpacing.lg),
              child: Theme(
                data: compactTheme,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'You have a workout in progress',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      'If you start a new workout, your old workout will be permanently deleted.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: TioLineHeight.height140,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.lg),
                    TioButton.primary(
                      key: const ValueKey('workout-in-progress-resume'),
                      label: 'Resume workout in progress',
                      expand: true,
                      onPressed: () => Navigator.of(dialogContext).pop(
                        WorkoutInProgressAction.resume,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    TioButton.destructive(
                      key: const ValueKey('workout-in-progress-start-new'),
                      label: 'Start new workout',
                      expand: true,
                      onPressed: () => Navigator.of(dialogContext).pop(
                        WorkoutInProgressAction.startNew,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    TioButton.secondary(
                      key: const ValueKey('workout-in-progress-cancel'),
                      label: 'Cancel',
                      expand: true,
                      onPressed: () => Navigator.of(dialogContext).pop(
                        WorkoutInProgressAction.cancel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
