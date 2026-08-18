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
      // Transparent tint/shadow intentionally suppress Material overlay effects.
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: TioNavigationTokens.elevation,
      leadingWidth: TioNavigationTokens.topBarLeadingWidth,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (planTier == ShellPlanTier.plus)
                      const Icon(
                        Icons.star_rounded,
                        size: TioNavigationTokens.planIconSize,
                        color: TioNavigationTokens.planPlusAccentColor,
                      )
                    else if (planTier == ShellPlanTier.premium)
                      SvgPicture.asset(
                        'assets/svg_icon/ic_pro_fill.svg',
                        package: 'tio_core',
                        width: TioNavigationTokens.planIconSize,
                        height: TioNavigationTokens.planIconSize,
                        colorFilter: ColorFilter.mode(
                          colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                      )
                    else
                      SvgPicture.asset(
                        'assets/svg_icon/ic_pro_outline.svg',
                        package: 'tio_core',
                        width: TioNavigationTokens.planIconSize,
                        height: TioNavigationTokens.planIconSize,
                        colorFilter: ColorFilter.mode(
                          colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    const SizedBox(width: TioNavigationTokens.planContentGap),
                    Flexible(
                      child: Text(
                        planTier.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
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
      backgroundColor: colorScheme.surface.withValues(alpha: opacity),
      elevation: TioNavigationTokens.elevation,
      actions: [
        IconButton(
          tooltip: 'Profile',
          icon: TioAvatar(
            key: ValueKey('top-bar-avatar-$avatarUrl-$userName-$planTier'),
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
