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
    return BottomNavigationBar(
      currentIndex: selectedTab.index,
      onTap: (index) => onTabSelected(ShellTab.fromIndex(index)),
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('../assets/nav_icon/home_outline.png')),
          activeIcon: ImageIcon(AssetImage('../assets/nav_icon/home_fill.png')),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('../assets/nav_icon/apple_outline.png')),
          activeIcon: ImageIcon(AssetImage('../assets/nav_icon/apple_fill.png')),
          label: 'Nutrition',
        ),
        BottomNavigationBarItem(
          icon: _AiTabIcon(isActive: false),
          activeIcon: _AiTabIcon(isActive: true),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('../assets/nav_icon/muscle_outline.png')),
          activeIcon: ImageIcon(AssetImage('../assets/nav_icon/muscle_fill.png')),
          label: 'Workout',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('../assets/nav_icon/trophy_outline.png')),
          activeIcon: ImageIcon(AssetImage('../assets/nav_icon/trophy_fill.png')),
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
