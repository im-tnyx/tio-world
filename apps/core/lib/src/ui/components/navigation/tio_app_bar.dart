import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/tokens/components/tio_navigation_tokens.dart';
import '../../../theme/tokens/foundation/tio_spacing.dart';

/// The standard phone top bar for a pushed screen.
///
/// With a leading back/close button the title starts
/// [TioNavigationTokens.topBarTitleGap] after the icon; without one it is
/// inset by [TioSpacing.lg]. Either way the title keeps [TioSpacing.lg] clear
/// of the actions or the trailing edge, and it is start-aligned on every
/// platform.
class TioAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TioAppBar({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.backgroundColor,
    this.elevation,
    this.scrolledUnderElevation,
  });

  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;

  @override
  Size get preferredSize =>
      const Size.fromHeight(TioNavigationTokens.topBarHeight);

  @override
  Widget build(BuildContext context) {
    // Mirrors the cases in which AppBar implies a back, close or drawer
    // button.
    final hasLeading = leading != null ||
        (automaticallyImplyLeading &&
            ((Scaffold.maybeOf(context)?.hasDrawer ?? false) ||
                (ModalRoute.of(context)?.impliesAppBarDismissal ?? false)));
    final spacing =
        hasLeading ? TioNavigationTokens.topBarTitleSpacing : TioSpacing.lg;
    // A negative spacing would lay the title over the leading slot, where it
    // would take the leading button's taps. The title keeps its box after
    // the slot and is only painted closer to the icon.
    final layoutSpacing = math.max(TioSpacing.none, spacing);
    final paintShift = math.min(TioSpacing.none, spacing);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final title = this.title;

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: layoutSpacing,
      centerTitle: false,
      // AppBar applies titleSpacing on both sides of the title; the end
      // padding restores the standard inset on the trailing side.
      title: title == null
          ? null
          : Padding(
              padding: EdgeInsetsDirectional.only(
                end: math.max(
                  TioSpacing.none,
                  TioSpacing.lg - layoutSpacing + paintShift,
                ),
              ),
              child: Transform.translate(
                offset: Offset(isRtl ? -paintShift : paintShift, 0),
                transformHitTests: false,
                child: title,
              ),
            ),
      actions: actions,
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
    );
  }
}
