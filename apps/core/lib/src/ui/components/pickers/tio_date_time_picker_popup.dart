import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../cards/tio_card.dart';
import 'tio_anchored_popup.dart';
import 'tio_date_time_wheel_picker.dart';

/// A reusable anchored DateTime popup card.
///
/// The caller owns the anchor, draft lifecycle and domain rules. This widget
/// only presents a generic DateTime drum above or below that anchor without
/// changing the layout or scroll extent of [child].
class TioDateTimePickerPopup extends StatefulWidget {
  const TioDateTimePickerPopup({
    required this.anchorKey,
    required this.isOpen,
    required this.onDismiss,
    required this.value,
    required this.maximumDate,
    required this.onChanged,
    required this.child,
    super.key,
    this.minimumDate,
    this.resolveDateTime,
    this.onPickerInteractionStart,
    this.passThroughAnchorKey,
  });

  /// A key on the caller's date/time control. It is presentation-only and has
  /// no feature/domain meaning.
  final GlobalKey anchorKey;
  final bool isOpen;
  final VoidCallback onDismiss;
  final DateTime value;
  final DateTime maximumDate;
  final DateTime? minimumDate;
  final TioDateTimeResolver? resolveDateTime;
  final ValueChanged<DateTime> onChanged;

  /// Lets a caller refresh a dynamic constraint before a native scroll starts.
  final VoidCallback? onPickerInteractionStart;

  /// A sibling control the dismiss layer leaves reachable while this card is
  /// open, so swapping between two cards on the same strip costs one tap
  /// rather than two. Null keeps the plain behaviour.
  final GlobalKey? passThroughAnchorKey;

  final Widget child;

  @override
  State<TioDateTimePickerPopup> createState() => _TioDateTimePickerPopupState();
}

class _TioDateTimePickerPopupState extends State<TioDateTimePickerPopup> {
  final _portalController = OverlayPortalController(
    debugLabel: 'TioDateTimePickerPopup',
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
  void didUpdateWidget(covariant TioDateTimePickerPopup oldWidget) {
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

  /// Where the sibling control sits, or null when there is none.
  Rect? _passThroughRect() {
    final renderObject =
        widget.passThroughAnchorKey?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
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
    const desiredHeight =
        TioWheelPickerTokens.viewportHeight + (TioSpacing.xs * 2);
    // Keep the floating card clear of the editor-footer divider and anchor.
    const gap = TioSpacing.sm;
    final availableAbove = math.max(TioSize.dp0, anchor.top - safeTop - gap);
    final availableBelow =
        math.max(TioSize.dp0, safeBottom - anchor.bottom - gap);
    final openAbove =
        availableAbove >= desiredHeight || availableAbove >= availableBelow;
    final availableHeight = openAbove ? availableAbove : availableBelow;
    final height = math.min(desiredHeight, availableHeight);
    final width = math.min(
      TioSize.dp480,
      math.max(TioSize.dp0, viewport.width - (TioSpacing.lg * 2)),
    );
    final left = (anchor.center.dx - (width / 2))
        .clamp(
          TioSpacing.lg,
          viewport.width - width - TioSpacing.lg,
        )
        .toDouble();
    final top = openAbove
        ? math.max(safeTop, anchor.top - gap - height)
        : math.min(safeBottom - height, anchor.bottom + gap);
    final pickerHeight = math.max(TioSize.dp0, height - (TioSpacing.xs * 2));

    if (width <= TioSize.dp0 || height <= TioSize.dp0) {
      return const SizedBox.shrink();
    }

    // No Material across the whole overlay: one spanning the screen hit-tests
    // as a solid sheet, which would swallow the tap the barrier's hole exists
    // to let through. The card carries its own.
    return Stack(
      children: [
          TioPopupDismissBarrier(
            onDismiss: widget.onDismiss,
            semanticLabel: 'Dismiss date and time picker',
            passThrough: _passThroughRect(),
          ),
          Positioned(
            key: const ValueKey('tio-date-time-picker-popup'),
            left: left,
            top: top,
            width: width,
            height: height,
            child: Semantics(
              container: true,
              child: Material(
                color: TioPalette.transparent,
                child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: TioCard(
                  variant: TioCardVariant.elevated,
                  padding: const EdgeInsets.all(TioSpacing.xs),
                  child: SizedBox(
                    height: pickerHeight,
                    child: Listener(
                      onPointerDown: (_) =>
                          widget.onPickerInteractionStart?.call(),
                      child: TioDateTimeWheelPicker(
                        value: widget.value,
                        minimumDate: widget.minimumDate,
                        maximumDate: widget.maximumDate,
                        resolveDateTime: widget.resolveDateTime,
                        onChanged: widget.onChanged,
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
