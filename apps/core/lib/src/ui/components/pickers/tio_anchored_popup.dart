import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../cards/tio_card.dart';

/// A floating card that opens beside a control without disturbing it.
///
/// ```text
///        ┌──────────────────────┐
///        │  content             │   the popup, in an overlay
///        └──────────────────────┘
///        ─────────────────────────
///        [anchor]        [other]     the caller's row, unmoved
/// ```
///
/// The content lives in an `OverlayPortal`, so opening it changes nothing
/// about [child] — no reflow, no scroll extent, no growing footer. A pinned
/// action region keeps its position and height while the card floats over the
/// body above it.
///
/// The caller owns the open flag and the anchor. This widget owns only where
/// the card goes and how it is dismissed: it prefers the side of the anchor
/// with more room, keeps clear of the status bar, the keyboard and the home
/// indicator, and closes on a tap anywhere outside.
///
/// Height is intrinsic and capped. The card is anchored by the edge nearest
/// the anchor — from the bottom when it opens upward — so it grows away from
/// the control without anyone having to know its height in advance, and
/// [contentBuilder] is told how much room it may use so long content can
/// scroll inside rather than being clipped.
class TioAnchoredPopup extends StatefulWidget {
  const TioAnchoredPopup({
    required this.anchorKey,
    required this.isOpen,
    required this.onDismiss,
    required this.dismissSemanticLabel,
    required this.contentBuilder,
    required this.child,
    super.key,
    this.popupKey,
    this.contentPadding = const EdgeInsets.all(TioSpacing.xs),
    this.maximumWidth = TioSize.dp480,
    this.preferredHeight,
  });

  /// A key on the caller's control. Presentation-only: this widget reads its
  /// geometry and nothing else.
  final GlobalKey anchorKey;

  final bool isOpen;
  final VoidCallback onDismiss;

  /// What a screen reader is told the full-screen dismiss target does.
  final String dismissSemanticLabel;

  /// Builds the card's content, given the height it may occupy.
  final Widget Function(BuildContext context, double maximumHeight)
      contentBuilder;

  /// How tall the content would like to be, used only to choose a side. Null
  /// picks whichever side has more room, which is what a control pinned near
  /// one edge of the screen wants.
  final double? preferredHeight;

  final Key? popupKey;
  final EdgeInsets contentPadding;

  /// The widest the card may be. It sizes to its content within this, so a
  /// short list of short labels stays a small card beside its control rather
  /// than a band across the screen.
  final double maximumWidth;

  final Widget child;

  @override
  State<TioAnchoredPopup> createState() => _TioAnchoredPopupState();
}

class _TioAnchoredPopupState extends State<TioAnchoredPopup> {
  final _portalController = OverlayPortalController(
    debugLabel: 'TioAnchoredPopup',
  );
  Rect? _anchorRect;
  var _geometryScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPopup());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isOpen) _scheduleGeometry();
  }

  @override
  void didUpdateWidget(covariant TioAnchoredPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPopup());
    } else if (widget.isOpen) {
      _scheduleGeometry();
    }
  }

  void _syncPopup() {
    if (!mounted) return;
    if (!widget.isOpen) {
      _portalController.hide();
      return;
    }
    _portalController.show();
    _scheduleGeometry();
  }

  void _scheduleGeometry() {
    if (_geometryScheduled) return;
    _geometryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryScheduled = false;
      if (!mounted || !widget.isOpen) return;
      final renderObject = widget.anchorKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final next = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      if (next == _anchorRect) return;
      setState(() => _anchorRect = next);
    });
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: _buildOverlay,
        child: widget.child,
      );

  Widget _buildOverlay(BuildContext context) {
    final anchor = _anchorRect;
    if (anchor == null) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.of(context);
    final viewport = mediaQuery.size;
    final safeTop = mediaQuery.padding.top + TioSpacing.sm;
    final safeBottom = viewport.height -
        math.max(mediaQuery.padding.bottom, mediaQuery.viewInsets.bottom) -
        TioSpacing.sm;

    // Clear of the anchor and of the divider a pinned region usually sits
    // under, so the card reads as floating over the body rather than growing
    // out of the control.
    const gap = TioSpacing.sm;
    final availableAbove = math.max(TioSize.dp0, anchor.top - safeTop - gap);
    final availableBelow =
        math.max(TioSize.dp0, safeBottom - anchor.bottom - gap);

    final preferred = widget.preferredHeight;
    final openAbove = preferred == null
        ? availableAbove >= availableBelow
        : availableAbove >= preferred || availableAbove >= availableBelow;
    final availableHeight = openAbove ? availableAbove : availableBelow;

    final maximumWidth = math.min(
      widget.maximumWidth,
      math.max(TioSize.dp0, viewport.width - (TioSpacing.lg * 2)),
    );
    if (maximumWidth <= TioSize.dp0 || availableHeight <= TioSize.dp0) {
      return const SizedBox.shrink();
    }

    // Aligned to the control's leading edge, so the card reads as belonging to
    // it. Clamped against the card's widest possible size rather than its
    // actual one — the actual one is not known until the content lays out, and
    // clamping for the worst case keeps it on screen either way.
    final left = anchor.left
        .clamp(
          TioSpacing.lg,
          math.max(TioSpacing.lg, viewport.width - maximumWidth - TioSpacing.lg),
        )
        .toDouble();

    // No width is imposed. The card takes what its content needs up to the
    // cap, which is what keeps a short list from stretching across the screen.
    final content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maximumWidth,
        maxHeight: availableHeight,
      ),
      child: TioCard(
        variant: TioCardVariant.elevated,
        padding: widget.contentPadding,
        child: widget.contentBuilder(
          context,
          math.max(
            TioSize.dp0,
            availableHeight -
                widget.contentPadding.top -
                widget.contentPadding.bottom,
          ),
        ),
      ),
    );

    return Material(
      color: TioPalette.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              label: widget.dismissSemanticLabel,
              onTap: widget.onDismiss,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDismiss,
              ),
            ),
          ),
          // Anchored by the edge nearest the control, so the card grows away
          // from it. Pinning the top instead would need the height up front,
          // which is exactly what intrinsic content does not have.
          Positioned(
            key: widget.popupKey,
            left: left,
            top: openAbove ? null : anchor.bottom + gap,
            bottom: openAbove ? viewport.height - anchor.top + gap : null,
            child: Semantics(
              container: true,
              child: GestureDetector(
                // Swallows taps so choosing inside the card is not also a
                // tap on the dismiss layer behind it.
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
