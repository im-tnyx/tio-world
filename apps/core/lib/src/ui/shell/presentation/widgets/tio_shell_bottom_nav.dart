import 'package:flutter/material.dart';

import '../../../../theme/locals/tio_theme_context.dart';
import '../../../../theme/tokens/semantic/tio_colors.dart';
import '../state/shell_state.dart';

class TioShellBottomNav extends StatelessWidget {
  const TioShellBottomNav({required this.selectedTab, required this.onTabSelected, super.key});

  final ShellTab selectedTab;
  final ValueChanged<ShellTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textMuted,
      currentIndex: selectedTab.index,
      onTap: (index) => onTabSelected(ShellTab.fromIndex(index)),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/nav_icon/home_outline.png', package: 'tio_core')),
          activeIcon: ImageIcon(AssetImage('assets/nav_icon/home_fill.png', package: 'tio_core')),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/nav_icon/apple_outline.png', package: 'tio_core')),
          activeIcon: ImageIcon(AssetImage('assets/nav_icon/apple_fill.png', package: 'tio_core')),
          label: 'Nutrition',
        ),
        BottomNavigationBarItem(
          icon: _AiTabIcon(isActive: false),
          activeIcon: _AiTabIcon(isActive: true),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/nav_icon/muscle_outline.png', package: 'tio_core')),
          activeIcon: ImageIcon(AssetImage('assets/nav_icon/muscle_fill.png', package: 'tio_core')),
          label: 'Workout',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/nav_icon/trophy_outline.png', package: 'tio_core')),
          activeIcon: ImageIcon(AssetImage('assets/nav_icon/trophy_fill.png', package: 'tio_core')),
          label: 'Progress',
        ),
      ],
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
              color: colors.coach.withOpacity(0.3),
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
            color: colors.textMuted.withOpacity(0.4),
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
