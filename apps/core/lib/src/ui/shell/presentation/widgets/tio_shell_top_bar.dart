import 'package:flutter/material.dart';

import '../action/shell_action.dart';
import '../state/shell_state.dart';

class TioShellTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TioShellTopBar({
    required this.planTier,
    required this.scrollOpacity,
    required this.onAction,
    super.key,
  });

  final ShellPlanTier planTier;
  final double scrollOpacity;
  final ValueChanged<ShellAction> onAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final opacity = scrollOpacity.clamp(0, 1).toDouble();
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Tio'),
      backgroundColor: colorScheme.surface.withValues(alpha: opacity),
      elevation: opacity > 0 ? 1 : 0,
      actions: [
        if (planTier == ShellPlanTier.free)
          TextButton(
            onPressed: () => onAction(const ShellPremiumClicked()),
            child: const Text('Plus'),
          ),
        IconButton(
          icon: const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 16)),
          onPressed: () => onAction(const ShellProfileClicked()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
