import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Workout's Play affordance. Reuses the governed appearance and placement of
/// the Nutrition FAB, without importing another feature or adding Core tokens.
class WorkoutPlayAction extends StatelessWidget {
  const WorkoutPlayAction({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      button: true,
      enabled: true,
      label: 'Log workout',
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Tooltip(
          message: 'Log workout',
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: context.tioShadows.soft,
            ),
            child: Material(
              color: colors.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox(
                  width: TioSize.dp56,
                  height: TioSize.dp56,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: colors.onPrimary,
                    size: TioSize.dp28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
