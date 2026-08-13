import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          icon: _SvgNavIcon('assets/nav_icon/ic_nav_home_outlined.svg'),
          selectedIcon: _SvgNavIcon('assets/nav_icon/ic_nav_home_filled.svg'),
          label: 'Home',
        ),
      ShellTab.nutrition => const NavigationDestination(
          icon:
              _SvgNavIcon('assets/nav_icon/ic_nav_nutrition_outlined.svg'),
          selectedIcon:
              _SvgNavIcon('assets/nav_icon/ic_nav_nutrition_filled.svg'),
          label: 'Nutrition',
        ),
      ShellTab.ai => const NavigationDestination(
          icon: _AiTabIcon(isActive: false),
          selectedIcon: _AiTabIcon(isActive: true),
          label: 'Tio',
        ),
      ShellTab.workout => const NavigationDestination(
          icon: _SvgNavIcon('assets/nav_icon/ic_nav_workout_outlined.svg'),
          selectedIcon:
              _SvgNavIcon('assets/nav_icon/ic_nav_workout_filled.svg'),
          label: 'Workout',
        ),
      ShellTab.progress => const NavigationDestination(
          icon: _SvgNavIcon('assets/nav_icon/ic_nav_progress_outlined.svg'),
          selectedIcon:
              _SvgNavIcon('assets/nav_icon/ic_nav_progress_filled.svg'),
          label: 'Progress',
        ),
    };
  }
}

class _SvgNavIcon extends StatelessWidget {
  const _SvgNavIcon(this.assetName);

  final String assetName;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconColor = iconTheme.color;
    final iconSize = iconTheme.size ?? TioNavigationTokens.iconSize;

    return SvgPicture.asset(
      assetName,
      package: 'tio_core',
      width: iconSize,
      height: iconSize,
      colorFilter: iconColor == null
          ? null
          : ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
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
