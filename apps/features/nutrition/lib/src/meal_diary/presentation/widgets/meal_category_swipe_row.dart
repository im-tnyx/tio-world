import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// A row that slides left far enough to uncover one action, and no further.
///
/// Two layers sharing one geometry: the action sits behind, the complete row
/// in front. Sliding the front layer uncovers the one behind, which is why the
/// action matches the row's height and edges exactly instead of reading as a
/// panel parked beside it.
///
/// Deliberately not a `Dismissible`: archiving a category must never happen as
/// a side effect of a gesture. The swipe only uncovers the action; the action
/// asks; the confirmation performs it. A full-swipe dismissal collapses those
/// three steps into one that cannot be reviewed, and archive removes a
/// category from every future meal picker.
///
/// The action stays reachable without the gesture — [semanticActionLabel] is
/// published as a custom semantics action, so a screen-reader user invokes it
/// directly.
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
    this.actionEnabled = true,
    this.blockedReason,
    super.key,
  });

  /// How far the row slides. One 48dp target plus a gutter either side, so the
  /// icon is comfortably hittable without the row travelling far enough to
  /// read as leaving the screen.
  static const double revealWidth =
      TioSize.dp48 + TioSpacing.lg + TioSpacing.sm;

  /// Past halfway the row settles open; short of it, closed. Two resting
  /// states only — there is no partial position to leave a row parked in.
  static const double _openThreshold = revealWidth / 2;

  /// A flick decides regardless of distance, so a fast short swipe still opens.
  static const double _flickVelocity = 200;

  final Widget child;

  /// Per-row so the uncovered action is addressable rather than one of several
  /// identically-keyed widgets.
  final Key actionKey;
  final IconData actionIcon;
  final String actionLabel;
  final String semanticActionLabel;
  final VoidCallback onAction;
  final bool enabled;

  /// Whether the action is possible at all right now. False leaves the row
  /// unswipeable rather than uncovering something that would only be refused.
  final bool actionEnabled;

  /// Why the action is unavailable. Published as the row's semantics hint so a
  /// reader who cannot see the missing affordance still learns the reason.
  final String? blockedReason;

  /// Whether this row is the open one. The page owns this so only one row is
  /// ever open.
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;

  /// The row's slice of the group card. Both layers are clipped to it, so the
  /// sliding row stays inside the card and the corners stay consistent.
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
  /// takes exactly that path.
  late final AnimationController _controller;

  /// Drives the release. Held as an animation so settling follows a curve
  /// rather than jumping to its destination.
  Animation<double> _slide = const AlwaysStoppedAnimation(0);

  double _offset = 0;

  /// Guards the threshold haptic so it fires once per crossing rather than on
  /// every drag frame that happens to sit past it.
  bool _passedThreshold = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _offset = widget.isOpen ? MealCategorySwipeRow.revealWidth : 0;
    _passedThreshold = widget.isOpen;
  }

  @override
  void didUpdateWidget(MealCategorySwipeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      _animateTo(widget.isOpen ? MealCategorySwipeRow.revealWidth : 0);
    }
    if (!_canReveal && _offset != 0) _animateTo(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canReveal => widget.enabled && widget.actionEnabled;

  void _animateTo(double target) {
    if (_offset == target) return;
    _controller.stop();
    _slide = Tween<double>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) setState(() => _offset = _slide.value);
      });
    _controller
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) setState(() => _offset = target);
        _passedThreshold = target > 0;
      });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_canReveal) return;
    _controller.stop();
    setState(() {
      // Clamped: left only, and never past the reveal, so the row cannot be
      // dragged halfway across the screen or thrown off it.
      _offset = (_offset - details.delta.dx)
          .clamp(0, MealCategorySwipeRow.revealWidth);
    });

    final past = _offset >= MealCategorySwipeRow._openThreshold;
    if (past != _passedThreshold) {
      _passedThreshold = past;
      // One tick as the action becomes reachable, not one per frame.
      if (past) HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_canReveal) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = velocity < -MealCategorySwipeRow._flickVelocity
        ? true
        : velocity > MealCategorySwipeRow._flickVelocity
            ? false
            : _offset >= MealCategorySwipeRow._openThreshold;
    widget.onOpenChanged(shouldOpen);
    _animateTo(shouldOpen ? MealCategorySwipeRow.revealWidth : 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      // Reachable without the gesture when the action is possible; when it is
      // not, the reason is stated rather than the affordance silently missing.
      customSemanticsActions: _canReveal
          ? {
              CustomSemanticsAction(label: widget.semanticActionLabel):
                  widget.onAction,
            }
          : const {},
      hint: _canReveal ? null : widget.blockedReason,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        // The foreground sizes the stack and the background fills it, so the
        // two layers cannot disagree about height the way siblings would.
        child: Stack(
          children: [
            Positioned.fill(
              child: _ActionLayer(
                actionKey: widget.actionKey,
                icon: widget.actionIcon,
                label: widget.actionLabel,
                // Only tappable once uncovered; beneath a closed row it is
                // inert rather than a hidden target.
                onPressed: _offset > 0 ? widget.onAction : null,
                background: colors.danger.withAlpha(TioAlpha.alpha35),
                foreground: colors.danger,
              ),
            ),
            // The whole row moves as one unit — its own surface included — so
            // what appears from the right is the layer underneath rather than
            // a gap cut into the row.
            Transform.translate(
              offset: Offset(-_offset, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: Material(
                  color: colors.surfaceRaised,
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The layer behind the row. Right-aligned across the row's full height, so it
/// is uncovered edge to edge rather than floating beside the content.
class _ActionLayer extends StatelessWidget {
  const _ActionLayer({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });

  final Key actionKey;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: MealCategorySwipeRow.revealWidth,
        height: double.infinity,
        child: ColoredBox(
          color: background,
          child: Center(
            child: IconButton(
              key: actionKey,
              tooltip: label,
              onPressed: onPressed,
              icon: Icon(icon, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
