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
    this.passThroughAnchorKey,
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

  /// A sibling control the dismiss layer leaves reachable while this card is
  /// open.
  ///
  /// Without it, two cards anchored to the same strip cost two taps to swap
  /// between: the first closes, the second opens. With it, the sibling is
  /// still pressable, so one tap closes this card and opens that one.
  ///
  /// Null keeps the plain behaviour, where every tap outside the card only
  /// dismisses it.
  final GlobalKey? passThroughAnchorKey;

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

  /// Where a sibling control currently sits, or null if there is none or it is
  /// not laid out yet.
  Rect? _rectOf(GlobalKey? key) {
    final renderObject = key?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
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
    // it. The actual card width is not known until the content lays out, so
    // fitting a leading-aligned card on screen has to assume the widest one.
    final leadingLimit = math.max(
      TioSpacing.lg,
      viewport.width - maximumWidth - TioSpacing.lg,
    );

    // A control close to the trailing edge cannot host a leading-aligned card
    // without that worst-case fit dragging it far off the control. Such a card
    // pins its trailing edge to the control's and grows the other way, which
    // needs no width in advance and keeps the two visually attached.
    final pinTrailing = anchor.left > leadingLimit;
    final left = pinTrailing ? null : math.max(TioSpacing.lg, anchor.left);
    final right = pinTrailing
        ? math.max(TioSpacing.lg, viewport.width - anchor.right)
        : null;

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

    // No Material across the whole overlay: one spanning the screen hit-tests
    // as a solid sheet, which would swallow the tap the barrier's hole exists
    // to let through. The card carries its own.
    return Stack(
      children: [
        TioPopupDismissBarrier(
          onDismiss: widget.onDismiss,
          semanticLabel: widget.dismissSemanticLabel,
          passThrough: _rectOf(widget.passThroughAnchorKey),
        ),
        // Anchored by the edge nearest the control, so the card grows away
        // from it. Pinning the top instead would need the height up front,
        // which is exactly what intrinsic content does not have.
        Positioned(
          key: widget.popupKey,
          left: left,
          right: right,
          top: openAbove ? null : anchor.bottom + gap,
          bottom: openAbove ? viewport.height - anchor.top + gap : null,
          child: Semantics(
            container: true,
            child: Material(
              color: TioPalette.transparent,
              child: GestureDetector(
                // Swallows taps so choosing inside the card is not also a
                // tap on the dismiss layer behind it.
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: content,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The full-screen layer that closes an anchored popup, with an optional hole.
///
/// A plain `Positioned.fill` barrier swallows every tap, which is correct until
/// two popups are anchored to the same strip: swapping between them then costs
/// a tap to close and a tap to open, because the first tap never reaches the
/// other control.
///
/// [passThrough] is cut out of the barrier — not made transparent, but absent,
/// so nothing in the overlay is hit-testable there and the tap continues down
/// to the control underneath. Four rectangles around the hole rather than one
/// across everything.
class TioPopupDismissBarrier extends StatelessWidget {
  const TioPopupDismissBarrier({
    required this.onDismiss,
    required this.semanticLabel,
    super.key,
    this.passThrough,
  });

  final VoidCallback onDismiss;
  final String semanticLabel;
  final Rect? passThrough;

  @override
  Widget build(BuildContext context) {
    final hole = passThrough;

    // One node, however many regions are painted. Four separately labelled
    // buttons would have a screen-reader user stepping through four
    // indistinguishable "Dismiss" controls for what is one layer.
    Widget announce(Widget child) => Semantics(
          button: true,
          label: semanticLabel,
          onTap: onDismiss,
          child: child,
        );

    Widget target() => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          excludeFromSemantics: true,
        );

    if (hole == null) return Positioned.fill(child: announce(target()));

    // Only the region above the hole speaks. Wrapping the whole stack gave one
    // node — which is what a screen-reader user should meet — but its bounds
    // then covered the hole as well, so exploring the sibling control by touch
    // found the dismiss layer sitting over it. Pointer hit testing passed
    // through and semantics did not.
    //
    // Announcing one region keeps both properties: a single dismiss action,
    // and nothing of this layer standing between a reader and the control the
    // hole exists to expose. The other three regions stay tappable and silent.
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: math.max(0, hole.top),
            child: announce(target()),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: hole.bottom,
            bottom: 0,
            child: target(),
          ),
          Positioned(
            left: 0,
            top: hole.top,
            height: hole.height,
            width: math.max(0, hole.left),
            child: target(),
          ),
          Positioned(
            left: hole.right,
            right: 0,
            top: hole.top,
            height: hole.height,
            child: target(),
          ),
        ],
      ),
    );
  }
}
