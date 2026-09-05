import 'package:flutter/material.dart';

import '../action/shell_action.dart';
import '../state/shell_state.dart';
import '../widgets/tio_shell_bottom_nav.dart';
import '../widgets/tio_shell_status_top_bar.dart';
import '../widgets/tio_shell_top_bar.dart';

class TioShell extends StatelessWidget {
  const TioShell({
    required this.state,
    required this.onAction,
    required this.child,
    this.statusTopBarLeadingAction,
    this.statusTopBarTitle,
    super.key,
  });

  final ShellUiState state;
  final ValueChanged<ShellAction> onAction;
  final Widget child;
  final Widget? statusTopBarLeadingAction;

  /// Title for the status top bar when the visible screen names itself
  /// something other than its tab.
  ///
  /// A tab label names a domain; a screen inside it may be one of several. The
  /// shell has no way to know which, so the composition layer supplies the
  /// name and the tab label stays the fallback. Core never learns that
  /// Nutrition currently shows a diary.
  final String? statusTopBarTitle;

  @override
  Widget build(BuildContext context) {
    final effectiveVisibleTabs =
        state.visibleTabs.length == 1 && state.visibleTabs.single == ShellTab.home
            ? missingModeCompatibilityShellTabs
            : state.visibleTabs;
    final canRenderBottomNav =
        state.isBottomNavVisible && effectiveVisibleTabs.length >= 2;

    return Scaffold(
      appBar: state.isRootTopBarVisible
          ? switch (state.selectedTab) {
              ShellTab.home => TioShellTopBar(
                  planTier: state.planTier,
                  scrollOpacity: state.appBarOpacity,
                  onAction: onAction,
                  userName: state.userName,
                  avatarUrl: state.avatarUrl,
                ),
              ShellTab.workout => TioShellStatusTopBar(
                  title: statusTopBarTitle ?? ShellTab.workout.label,
                  statusLabel: 'Workout streak',
                  statusKey: const ValueKey('shell-workout-streak'),
                  days: state.workoutStreakDays,
                  scrollOpacity: state.appBarOpacity,
                  leadingAction: statusTopBarLeadingAction,
                ),
              ShellTab.nutrition => TioShellStatusTopBar(
                  title: statusTopBarTitle ?? ShellTab.nutrition.label,
                  statusLabel: 'Meal log streak',
                  statusKey: const ValueKey('shell-meal-log-streak'),
                  days: state.mealLogStreakDays,
                  scrollOpacity: state.appBarOpacity,
                  leadingAction: statusTopBarLeadingAction,
                ),
              ShellTab.ai || ShellTab.progress => null,
            }
          : null,
      body: child,
      bottomNavigationBar: canRenderBottomNav
          ? TioShellBottomNav(
              selectedTab: state.selectedTab,
              visibleTabs: effectiveVisibleTabs,
              onTabSelected: (tab) => onAction(ShellTabSelected(tab)),
            )
          : null,
    );
  }
}
