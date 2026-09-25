import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    final titleSpacing =
        hasLeading ? TioNavigationTokens.topBarTitleSpacing : TioSpacing.lg;
    final title = this.title;

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing,
      centerTitle: false,
      title: title == null
          ? null
          // A negative spacing lays the title over the end of the leading
          // slot; that strip stays with the leading button's tap target.
          : _LeadingTapClearance(
              extent: math.max(TioSpacing.none, -titleSpacing),
              textDirection: Directionality.of(context),
              // AppBar applies titleSpacing on both sides of the title; the
              // end padding restores the standard inset on the trailing side.
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: TioSpacing.lg - titleSpacing,
                ),
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

/// Ignores pointers on the first [extent] of its child's start side, so a
/// title laid out over the leading slot never takes the leading button's
/// taps. Elsewhere the child is hit exactly where it is painted.
class _LeadingTapClearance extends SingleChildRenderObjectWidget {
  const _LeadingTapClearance({
    required this.extent,
    required this.textDirection,
    required super.child,
  });

  final double extent;
  final TextDirection textDirection;

  @override
  _RenderLeadingTapClearance createRenderObject(BuildContext context) =>
      _RenderLeadingTapClearance(extent, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLeadingTapClearance renderObject,
  ) {
    renderObject
      ..extent = extent
      ..textDirection = textDirection;
  }
}

class _RenderLeadingTapClearance extends RenderProxyBox {
  _RenderLeadingTapClearance(this.extent, this.textDirection);

  double extent;
  TextDirection textDirection;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final fromStart = textDirection == TextDirection.rtl
        ? size.width - position.dx
        : position.dx;
    if (fromStart < extent) return false;
    return super.hitTest(result, position: position);
  }
}
