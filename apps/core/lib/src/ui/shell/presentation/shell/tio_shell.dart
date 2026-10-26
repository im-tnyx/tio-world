import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';

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
    this.statusTopBarTrailingAction,
    this.statusTopBarTitle,
    this.statusTopBarCenter,
    super.key,
  });

  final ShellUiState state;
  final ValueChanged<ShellAction> onAction;
  final Widget child;
  final Widget? statusTopBarLeadingAction;
  final Widget? statusTopBarTrailingAction;

  /// Title for the status top bar when the visible screen names itself
  /// something other than its tab.
  ///
  /// A tab label names a domain; a screen inside it may be one of several. The
  /// shell has no way to know which, so the composition layer supplies the
  /// name and the tab label stays the fallback. Core never learns that
  /// Nutrition currently shows a diary.
  final String? statusTopBarTitle;

  /// Optional centred context for the status top bar.
  ///
  /// Where the title says which screen this is, the centre says where inside
  /// it the reader currently is. Core neither produces nor interprets that —
  /// it only reserves the slot.
  final Widget? statusTopBarCenter;

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
                  trailingAction: statusTopBarTrailingAction,
                  center: statusTopBarCenter,
                ),
              ShellTab.nutrition => TioShellStatusTopBar(
                  title: statusTopBarTitle ?? ShellTab.nutrition.label,
                  statusLabel: 'Meal log streak',
                  statusKey: const ValueKey('shell-meal-log-streak'),
                  days: state.mealLogStreakDays,
                  scrollOpacity: state.appBarOpacity,
                  leadingAction: statusTopBarLeadingAction,
                  trailingAction: statusTopBarTrailingAction,
                  center: statusTopBarCenter,
                ),
              // Progress is a first-class root tab and must reserve the
              // same canonical toolbar height and status-bar inset as every
              // other primary screen. It has no verified streak domain, so
              // do not invent one merely to reuse the status top bar.
              ShellTab.progress => AppBar(
                  toolbarHeight: TioNavigationTokens.topBarHeight,
                  automaticallyImplyLeading: false,
                  titleSpacing: TioSpacing.lg,
                  title: Text(statusTopBarTitle ?? ShellTab.progress.label),
                  shape: null,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  scrolledUnderElevation: TioElevation.none,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: state.appBarOpacity.clamp(0, 1).toDouble()),
                  elevation: TioElevation.none,
                ),
              ShellTab.ai => null,
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
