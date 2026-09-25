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
      // The header semantics AppBar would add around the title are added
      // below instead, inside the clearance, so they are clipped with it.
      excludeHeaderSemantics: true,
      title: title == null
          ? null
          // A negative spacing lays the title over the end of the leading
          // slot; that strip stays with the leading button, for pointers
          // and for accessibility.
          : _LeadingClearance(
              extent: math.max(TioSpacing.none, -titleSpacing),
              textDirection: Directionality.of(context),
              child: Semantics(
                // Same header semantics as AppBar's.
                namesRoute: switch (Theme.of(context).platform) {
                  TargetPlatform.android ||
                  TargetPlatform.fuchsia ||
                  TargetPlatform.linux ||
                  TargetPlatform.windows =>
                    true,
                  TargetPlatform.iOS || TargetPlatform.macOS => null,
                },
                header: true,
                // AppBar applies titleSpacing on both sides of the title;
                // the end padding restores the standard inset on the
                // trailing side.
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: TioSpacing.lg - titleSpacing,
                  ),
                  child: title,
                ),
              ),
            ),
      actions: actions,
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
    );
  }
}

/// Keeps the first [extent] of its child's start side clear, so a title
/// laid out over the leading slot never takes the leading button's taps or
/// its accessibility bounds. Elsewhere the child is hit exactly where it is
/// painted.
class _LeadingClearance extends SingleChildRenderObjectWidget {
  const _LeadingClearance({
    required this.extent,
    required this.textDirection,
    required super.child,
  });

  final double extent;
  final TextDirection textDirection;

  @override
  _RenderLeadingClearance createRenderObject(BuildContext context) =>
      _RenderLeadingClearance(extent, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLeadingClearance renderObject,
  ) {
    renderObject
      ..extent = extent
      ..textDirection = textDirection;
  }
}

class _RenderLeadingClearance extends RenderProxyBox {
  _RenderLeadingClearance(this._extent, this._textDirection);

  double _extent;
  set extent(double value) {
    if (value == _extent) return;
    _extent = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  /// The part of the child outside the cleared strip.
  Rect get _uncleared {
    final cleared = math.min(_extent, size.width);
    return _textDirection == TextDirection.rtl
        ? Rect.fromLTRB(0, 0, size.width - cleared, size.height)
        : Rect.fromLTRB(cleared, 0, size.width, size.height);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_uncleared.contains(position)) return false;
    return super.hitTest(result, position: position);
  }

  @override
  Rect? describeSemanticsClip(RenderObject? child) => _uncleared;
}
