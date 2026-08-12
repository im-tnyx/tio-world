import 'package:flutter/material.dart';

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
    super.key,
  });

  final ShellPlanTier planTier;
  final double scrollOpacity;
  final ValueChanged<ShellAction> onAction;

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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      planTier.label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
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
            size: TioAvatarSize.small,
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
