import 'package:flutter/material.dart';

import '../action/shell_action.dart';

class TioShellTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TioShellTopBar({required this.onAction, super.key});

  final ValueChanged<ShellAction> onAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Tio'),
      actions: [
        IconButton(
          icon: const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 16)),
          onPressed: () => onAction(const ShellProfileClicked()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
