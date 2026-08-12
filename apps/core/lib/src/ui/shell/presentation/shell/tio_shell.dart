import 'package:flutter/material.dart';

import '../action/shell_action.dart';
import '../state/shell_state.dart';
import '../widgets/tio_shell_bottom_nav.dart';
import '../widgets/tio_shell_status_top_bar.dart';
import '../widgets/tio_shell_top_bar.dart';

class TioShell extends StatelessWidget {
  const TioShell(
      {required this.state,
      required this.onAction,
      required this.child,
      super.key});

  final ShellUiState state;
  final ValueChanged<ShellAction> onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: state.isRootTopBarVisible
          ? switch (state.selectedTab) {
              ShellTab.home => TioShellTopBar(
                  planTier: state.planTier,
                  scrollOpacity: state.appBarOpacity,
                  onAction: onAction,
                ),
              ShellTab.workout => TioShellStatusTopBar(
                  title: ShellTab.workout.label,
                  statusLabel: 'Workout streak',
                  statusKey: const ValueKey('shell-workout-streak'),
                  days: state.workoutStreakDays,
                  scrollOpacity: state.appBarOpacity,
                ),
              ShellTab.nutrition => TioShellStatusTopBar(
                  title: ShellTab.nutrition.label,
                  statusLabel: 'Meal log streak',
                  statusKey: const ValueKey('shell-meal-log-streak'),
                  days: state.mealLogStreakDays,
                  scrollOpacity: state.appBarOpacity,
                ),
              ShellTab.ai || ShellTab.progress => null,
            }
          : null,
      body: child,
      bottomNavigationBar: state.isBottomNavVisible
          ? TioShellBottomNav(
              selectedTab: state.selectedTab,
              visibleTabs: state.visibleTabs,
              onTabSelected: (tab) => onAction(ShellTabSelected(tab)),
            )
          : null,
    );
  }
}
