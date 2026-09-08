import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// A row that slides left far enough to reveal one action, and no further.
///
/// Deliberately not a `Dismissible`: archiving a category must never happen as
/// a side effect of a gesture. The swipe only reveals the action; the action
/// asks for confirmation; the confirmation performs the archive. A full-swipe
/// dismissal would collapse those three steps into one that cannot be
/// reviewed, and archive removes a category from every future meal picker.
///
/// The action stays reachable without the gesture: [semanticActionLabel] is
/// published as a custom semantics action on the row, so a screen-reader user
/// invokes archive directly.
class MealCategorySwipeRow extends StatefulWidget {
  const MealCategorySwipeRow({
    required this.child,
    required this.actionKey,
    required this.actionIcon,
    required this.actionLabel,
    required this.semanticActionLabel,
    required this.onAction,
    required this.isOpen,
    required this.onOpenChanged,
    required this.borderRadius,
    this.enabled = true,
    super.key,
  });

  /// Width revealed at rest. Enough for a 48dp target plus breathing room.
  static const double revealWidth = TioSize.dp72;

  /// How far the row must travel before it settles open rather than closed.
  static const double _openThreshold = revealWidth / 2;

  final Widget child;

  /// Per-row so the revealed action is addressable rather than one of several
  /// identically-keyed widgets.
  final Key actionKey;
  final IconData actionIcon;
  final String actionLabel;
  final String semanticActionLabel;
  final VoidCallback onAction;
  final bool enabled;

  /// Whether this row is the one currently revealed. The page owns this so
  /// only one row is open at a time.
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;

  /// The row's slice of the group card. Owned here because the sliding content
  /// has to be clipped to it — otherwise the row travels past the card's edge
  /// and its label runs off the screen.
  final BorderRadius borderRadius;

  @override
  State<MealCategorySwipeRow> createState() => _MealCategorySwipeRowState();
}

class _MealCategorySwipeRowState extends State<MealCategorySwipeRow>
    with SingleTickerProviderStateMixin {
  /// Built in `initState`, not lazily.
  ///
  /// A `late final` initializer runs on first access, and for a row that never
  /// animated that first access is `dispose()` — by which point the element is
  /// deactivated and creating a ticker throws. Any row scrolled out of view
  /// hits exactly that path.
  late final AnimationController _controller;

  double _offset = 0;

  /// Guards the reveal haptic so it fires once per crossing rather than on
  /// every drag frame that happens to sit past the threshold.
  bool _passedThreshold = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _offset = widget.isOpen ? MealCategorySwipeRow.revealWidth : 0;
  }

  @override
  void didUpdateWidget(MealCategorySwipeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      _animateTo(widget.isOpen ? MealCategorySwipeRow.revealWidth : 0);
    }
    if (!widget.enabled && _offset != 0) _animateTo(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final from = _offset;
    if (from == target) return;
    _controller
      ..stop()
      ..reset();
    final animation = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    void listener() => setState(() => _offset = animation.value);
    animation.addListener(listener);
    _controller.forward().whenComplete(() {
      animation.removeListener(listener);
      if (mounted) setState(() => _offset = target);
      _passedThreshold = target > 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      // Clamped: left swipe only, and never past the revealed width, so the
      // row cannot be thrown off screen.
      _offset =
          (_offset - details.delta.dx).clamp(0, MealCategorySwipeRow.revealWidth);
    });

    final past = _offset >= MealCategorySwipeRow._openThreshold;
    if (past != _passedThreshold) {
      _passedThreshold = past;
      // One tick when the action becomes reachable, not per frame.
      if (past) HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = velocity < -200
        ? true
        : velocity > 200
            ? false
            : _offset >= MealCategorySwipeRow._openThreshold;
    widget.onOpenChanged(shouldOpen);
    _animateTo(shouldOpen ? MealCategorySwipeRow.revealWidth : 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      // Archive stays reachable without the gesture.
      customSemanticsActions: widget.enabled
          ? {
              CustomSemanticsAction(label: widget.semanticActionLabel):
                  widget.onAction,
            }
          : const {},
      child: Material(
        color: colors.surfaceRaised,
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: Row(
            children: [
              // The row compresses rather than translating, so the category's
              // name stays where it was and stays readable. Sliding the whole
              // row would push the name off the card's edge — leaving the
              // reader deciding whether to archive something they can no
              // longer see.
              Expanded(child: widget.child),
              // `Align` with a width factor gives the action a width of
              // `revealWidth * factor` while the icon inside keeps its own
              // size, so the strip grows without squeezing its contents.
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                      (_offset / MealCategorySwipeRow.revealWidth).clamp(0, 1),
                  child: SizedBox(
                    width: MealCategorySwipeRow.revealWidth,
                    child: Opacity(
                      // Fades in with the reveal, so a half-open row never
                      // shows a fully-lit action it cannot yet accept.
                      opacity: (_offset / MealCategorySwipeRow.revealWidth)
                          .clamp(0, 1),
                      child: Center(
                        child: IconButton(
                          key: widget.actionKey,
                          tooltip: widget.actionLabel,
                          onPressed: _offset > 0 ? widget.onAction : null,
                          icon: Icon(widget.actionIcon, color: colors.danger),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
