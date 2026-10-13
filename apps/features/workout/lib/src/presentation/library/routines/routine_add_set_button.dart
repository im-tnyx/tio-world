import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Neutral full-width Set action shared by Routine Create and Edit.
///
/// The governed Core button still owns semantics, focus, states and its
/// accessible 46dp target. Only the approved neutral surface is composed here.
class RoutineAddSetButton extends StatelessWidget {
  const RoutineAddSetButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: TioButtonTokens.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.tioColors.surface,
            borderRadius: BorderRadius.circular(TioRadius.full),
          ),
          child: TioButton.ghost(
            label: 'Add Set',
            leading: const Icon(Icons.add, size: TioSize.dp20),
            expand: true,
            onPressed: onPressed,
          ),
        ),
      );
}
