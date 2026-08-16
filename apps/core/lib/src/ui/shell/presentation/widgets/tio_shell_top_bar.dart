import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../theme/tokens/components/tio_navigation_tokens.dart';
import '../../../../theme/tokens/foundation/tio_spacing.dart';
import '../../../components/avatars/tio_avatar.dart';
import '../action/shell_action.dart';
import '../state/shell_state.dart';

class TioShellTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TioShellTopBar({
    required this.planTier,
    required this.scrollOpacity,
    required this.onAction,
    this.userName,
    this.avatarUrl,
    super.key,
  });

  final ShellPlanTier planTier;
  final double scrollOpacity;
  final ValueChanged<ShellAction> onAction;
  final String? userName;
  final String? avatarUrl;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final opacity = scrollOpacity.clamp(0, 1).toDouble();
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      shape: null,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leadingWidth: TioSpacing.extraLarge * 3,
      leading: Padding(
        padding: const EdgeInsets.only(left: TioSpacing.large),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'TIO',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      flexibleSpace: SafeArea(
        bottom: false,
        child: Center(
          child: Semantics(
            label: 'Plan: ${planTier.label}',
            child: ExcludeSemantics(
              child: Container(
                key: const ValueKey('shell-plan'),
                width: TioNavigationTokens.planPillWidth,
                height: TioNavigationTokens.planPillHeight,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: colorScheme.primaryContainer,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.small,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dynamic Icon based on Plan
                      switch (planTier) {
                        ShellPlanTier.free => SvgPicture.asset(
                            'assets/svg_icon/ic_pro_outline.svg',
                            package: 'tio_core',
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              colorScheme.onPrimaryContainer,
                              BlendMode.srcIn,
                            ),
                          ),
                        ShellPlanTier.plus => const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                        ShellPlanTier.premium => SvgPicture.asset(
                            'assets/svg_icon/ic_pro_fill.svg',
                            package: 'tio_core',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF5EEAD4),
                              BlendMode.srcIn,
                            ),
                          ),
                      },
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          planTier.label,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: colorScheme.surface.withValues(alpha: opacity),
      elevation: 0,
      actions: [
        IconButton(
          tooltip: 'Profile',
          icon: TioAvatar(
            key: ValueKey('top-bar-avatar-$avatarUrl-$userName'),
            size: TioAvatarSize.small,
            displayName: userName,
            imageUrl: avatarUrl,
            frame: switch (planTier) {
              ShellPlanTier.free => TioAvatarFrame.none,
              ShellPlanTier.plus => TioAvatarFrame.plusRing,
              ShellPlanTier.premium => TioAvatarFrame.proHexagon,
            },
          ),
          onPressed: () => onAction(const ShellProfileClicked()),
        ),
        const SizedBox(width: TioSpacing.small),
      ],
    );
  }
}
