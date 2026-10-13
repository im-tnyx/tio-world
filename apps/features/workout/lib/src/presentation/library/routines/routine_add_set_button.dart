import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Neutral full-width Set action shared by Routine Create and Edit.
///
/// The governed Core button still owns semantics, focus, states and its
/// accessible 46dp minimum target (it can grow for large text).
/// Only the approved neutral surface is composed here.
class RoutineAddSetButton extends StatelessWidget {
  const RoutineAddSetButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    // Keep Core's sizing, focus shape and states. Only this Workout action's
    // neutral text/icon color differs from the usual accent ghost button.
    final themedStyle = Theme.of(context).textButtonTheme.style?.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.textMuted
            : colors.textPrimary,
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TioButtonTokens.height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(TioRadius.full),
        ),
        child: TextButtonTheme(
          data: TextButtonThemeData(style: themedStyle),
          child: TioButton.ghost(
            label: 'Add Set',
            leading: const Icon(Icons.add, size: TioSize.dp20),
            expand: true,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
