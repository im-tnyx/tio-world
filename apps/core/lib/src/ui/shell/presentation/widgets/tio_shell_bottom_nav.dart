import 'package:flutter/material.dart';

import '../../../../theme/locals/tio_theme_context.dart';
import '../../../../theme/tokens/components/tio_navigation_tokens.dart';
import '../state/shell_state.dart';

class TioShellBottomNav extends StatelessWidget {
  const TioShellBottomNav({
    required this.selectedTab,
    required this.visibleTabs,
    required this.onTabSelected,
    super.key,
  });

  final ShellTab selectedTab;
  final List<ShellTab> visibleTabs;
  final ValueChanged<ShellTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final selectedIndex = visibleTabs.indexOf(selectedTab);

    return NavigationBar(
      height: TioNavigationTokens.bottomBarHeight,
      backgroundColor: colors.surface,
      indicatorColor: colors.primary.withValues(
        alpha: TioNavigationTokens.indicatorOpacity,
      ),
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => onTabSelected(visibleTabs[index]),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: visibleTabs.map(_destinationForTab).toList(growable: false),
    );
  }

  NavigationDestination _destinationForTab(ShellTab tab) {
    return switch (tab) {
      ShellTab.home => const NavigationDestination(
          icon: ImageIcon(AssetImage('assets/nav_icon/home_outline.png',
              package: 'tio_core')),
          selectedIcon: ImageIcon(
              AssetImage('assets/nav_icon/home_fill.png', package: 'tio_core')),
          label: 'Home',
        ),
      ShellTab.nutrition => const NavigationDestination(
          icon: ImageIcon(AssetImage('assets/nav_icon/apple_outline.png',
              package: 'tio_core')),
          selectedIcon: ImageIcon(AssetImage('assets/nav_icon/apple_fill.png',
              package: 'tio_core')),
          label: 'Nutrition',
        ),
      ShellTab.ai => const NavigationDestination(
          icon: _AiTabIcon(isActive: false),
          selectedIcon: _AiTabIcon(isActive: true),
          label: 'Tio',
        ),
      ShellTab.workout => const NavigationDestination(
          icon: ImageIcon(AssetImage('assets/nav_icon/muscle_outline.png',
              package: 'tio_core')),
          selectedIcon: ImageIcon(AssetImage('assets/nav_icon/muscle_fill.png',
              package: 'tio_core')),
          label: 'Workout',
        ),
      ShellTab.progress => const NavigationDestination(
          icon: ImageIcon(AssetImage('assets/nav_icon/trophy_outline.png',
              package: 'tio_core')),
          selectedIcon: ImageIcon(AssetImage('assets/nav_icon/trophy_fill.png',
              package: 'tio_core')),
          label: 'Progress',
        ),
    };
  }
}

class _AiTabIcon extends StatelessWidget {
  const _AiTabIcon({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    if (isActive) {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.coach,
          boxShadow: [
            BoxShadow(
              color: colors.coach.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.auto_awesome,
          size: 14,
          color: colors.isDark ? colors.background : colors.surface,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.textMuted.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.auto_awesome,
          size: 14,
          color: colors.textMuted,
        ),
      );
    }
  }
}
