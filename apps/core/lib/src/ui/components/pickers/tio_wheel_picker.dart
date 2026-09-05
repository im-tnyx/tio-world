import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

typedef TioWheelItemBuilder = Widget Function(
  BuildContext context,
  int index,
  bool isSelected,
);

/// One user-originated wheel detent.
///
/// [index] is the logical item index. [itemDelta] preserves the physical
/// direction for looping wheels, so a caller can distinguish `59 -> 00`
/// forward from `00 -> 59` backward without guessing from the labels.
class TioWheelSelectionChange {
  const TioWheelSelectionChange({
    required this.index,
    required this.itemDelta,
  });

  final int index;
  final int itemDelta;
}

/// The shared Tio fixed-extent wheel column.
///
/// This owns the mechanics that were previously repeated by the DOB, weight,
/// and onboarding-height wheels: controller lifecycle, fixed-extent physics,
/// finite/unbounded/looping delegates, canonical selection haptic, and
/// programmatic synchronization. The caller owns labels and coherent domain
/// state.
class TioWheelPickerColumn extends StatefulWidget {
  const TioWheelPickerColumn({
    required this.selectedIndex,
    required this.itemBuilder,
    required this.onSelectedItemChanged,
    super.key,
    this.itemCount,
    this.looping = false,
    this.syncRevision = 0,
    this.semanticLabel,
    this.semanticValue,
  }) : assert(selectedIndex >= 0),
       assert(itemCount == null || itemCount > 0),
       assert(!looping || itemCount != null),
       assert(itemCount == null || selectedIndex < itemCount);

  /// Null means an unbounded positive logical index. That is useful for a
  /// date wheel whose index zero is a caller-supplied maximum and whose past
  /// has no invented product minimum.
  final int? itemCount;
  final int selectedIndex;
  final bool looping;
  final int syncRevision;
  final String? semanticLabel;
  final String? semanticValue;
  final TioWheelItemBuilder itemBuilder;
  final ValueChanged<TioWheelSelectionChange> onSelectedItemChanged;

  @override
  State<TioWheelPickerColumn> createState() => _TioWheelPickerColumnState();
}

class _TioWheelPickerColumnState extends State<TioWheelPickerColumn> {
  // A large, aligned cycle leaves practical scrolling room in both
  // directions without making a product-visible range decision.
  static const _loopingAnchorCycle = 10000;

  late final FixedExtentScrollController _controller;
  late int _selectedRawIndex;
  int? _pendingProgrammaticRawIndex;

  int get _logicalIndex => widget.looping
      ? _selectedRawIndex % widget.itemCount!
      : _selectedRawIndex;

  @override
  void initState() {
    super.initState();
    _selectedRawIndex = _initialRawIndex(widget.selectedIndex);
    _controller = FixedExtentScrollController(initialItem: _selectedRawIndex);
  }

  @override
  void didUpdateWidget(covariant TioWheelPickerColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final needsSync = widget.selectedIndex != _logicalIndex ||
        widget.syncRevision != oldWidget.syncRevision ||
        widget.looping != oldWidget.looping ||
        widget.itemCount != oldWidget.itemCount;
    if (!needsSync) return;

    final target = widget.looping
        ? _nearestLoopingRawIndex(widget.selectedIndex)
        : widget.selectedIndex;
    _selectedRawIndex = target;
    _pendingProgrammaticRawIndex = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_controller.hasClients ||
          _pendingProgrammaticRawIndex != target) {
        return;
      }
      if (_controller.selectedItem == target) {
        _pendingProgrammaticRawIndex = null;
        return;
      }
      _controller.jumpToItem(target);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _initialRawIndex(int selectedIndex) => widget.looping
      ? widget.itemCount! * _loopingAnchorCycle + selectedIndex
      : selectedIndex;

  int _nearestLoopingRawIndex(int logicalIndex) {
    final count = widget.itemCount!;
    final cycleStart = _selectedRawIndex - (_selectedRawIndex % count);
    final candidates = <int>[
      cycleStart - count + logicalIndex,
      cycleStart + logicalIndex,
      cycleStart + count + logicalIndex,
    ].where((candidate) => candidate >= 0);
    return candidates.reduce(
      (best, candidate) =>
          (candidate - _selectedRawIndex).abs() <
                  (best - _selectedRawIndex).abs()
              ? candidate
              : best,
    );
  }

  void _onSelectedItemChanged(int rawIndex) {
    final previousRawIndex = _selectedRawIndex;
    _selectedRawIndex = rawIndex;

    if (_pendingProgrammaticRawIndex == rawIndex) {
      _pendingProgrammaticRawIndex = null;
      if (mounted) setState(() {});
      return;
    }
    if (rawIndex == previousRawIndex) return;

    final logicalIndex = widget.looping
        ? rawIndex % widget.itemCount!
        : rawIndex;
    if (mounted) setState(() {});
    HapticFeedback.selectionClick();
    widget.onSelectedItemChanged(
      TioWheelSelectionChange(
        index: logicalIndex,
        itemDelta: rawIndex - previousRawIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wheel = ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: TioWheelPickerTokens.itemExtent,
      perspective: TioWheelPickerTokens.perspective,
      diameterRatio: TioWheelPickerTokens.diameterRatio,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: _onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.looping ? null : widget.itemCount,
        builder: (context, rawIndex) {
          final logicalIndex = widget.looping
              ? rawIndex % widget.itemCount!
              : rawIndex;
          return widget.itemBuilder(
            context,
            logicalIndex,
            rawIndex == _selectedRawIndex,
          );
        },
      ),
    );

    if (widget.semanticLabel == null && widget.semanticValue == null) {
      return wheel;
    }
    return Semantics(
      label: widget.semanticLabel,
      value: widget.semanticValue,
      child: wheel,
    );
  }
}

/// Shared viewport and selected-row treatment for Tio wheel compositions.
class TioWheelPickerFrame extends StatelessWidget {
  const TioWheelPickerFrame({
    required this.child,
    super.key,
    this.selectionPillKey,
    this.contentPadding = EdgeInsets.zero,
  });

  final Widget child;
  final Key? selectionPillKey;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return SizedBox(
      height: TioWheelPickerTokens.viewportHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            key: selectionPillKey,
            height: TioWheelPickerTokens.selectionHeight,
            margin: const EdgeInsets.symmetric(
              horizontal: TioWheelPickerTokens.selectionHorizontalMargin,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withAlpha(
                TioWheelPickerTokens.selectionSurfaceAlpha,
              ),
              borderRadius: BorderRadius.circular(TioRadius.md),
            ),
          ),
          Padding(padding: contentPadding, child: child),
        ],
      ),
    );
  }
}
