import 'package:flutter/material.dart';

import '../action/shell_action.dart';
import '../state/shell_state.dart';
import '../widgets/tio_shell_bottom_nav.dart';
import '../widgets/tio_shell_top_bar.dart';

class TioShell extends StatelessWidget {
  const TioShell({required this.state, required this.onAction, required this.child, super.key});

  final ShellUiState state;
  final ValueChanged<ShellAction> onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TioShellTopBar(onAction: onAction),
      body: child,
      bottomNavigationBar: state.isBottomNavVisible
          ? TioShellBottomNav(
              selectedTab: state.selectedTab,
              onTabSelected: (tab) => onAction(ShellTabSelected(tab)),
            )
          : null,
    );
  }
}
