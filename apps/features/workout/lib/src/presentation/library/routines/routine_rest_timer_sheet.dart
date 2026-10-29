import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/models/routine_rest_timer_preset.dart';

/// Shows the Routine Rest Timer configuration sheet.
Future<RoutineRestTimerPreset?> showRoutineRestTimerSheet({
  required BuildContext context,
  required int? initialNormalRestSeconds,
  required int? initialWarmUpRestSeconds,
  String? exerciseName,
}) =>
    showModalBottomSheet<RoutineRestTimerPreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineRestTimerSheet(
        initialNormalRestSeconds: initialNormalRestSeconds,
        initialWarmUpRestSeconds: initialWarmUpRestSeconds,
        exerciseName: exerciseName,
      ),
    );

/// Modal sheet for configuring Normal and Warm-up Rest Timer presets independently.
class RoutineRestTimerSheet extends StatefulWidget {
  const RoutineRestTimerSheet({
    this.initialNormalRestSeconds,
    this.initialWarmUpRestSeconds,
    this.exerciseName,
    super.key,
  });

  final int? initialNormalRestSeconds;
  final int? initialWarmUpRestSeconds;
  final String? exerciseName;

  @override
  State<RoutineRestTimerSheet> createState() => _RoutineRestTimerSheetState();
}

class _RoutineRestTimerSheetState extends State<RoutineRestTimerSheet> {
  static const int _maxDurationSeconds = 600; // 10 minutes maximum
  static const int _stepSeconds = 5;

  static int get _itemCount => (_maxDurationSeconds ~/ _stepSeconds) + 1; // 121 items

  static int? indexToSeconds(int index) {
    if (index <= 0) return null;
    return (index * _stepSeconds).clamp(5, _maxDurationSeconds);
  }

  static int secondsToIndex(int? seconds) {
    if (seconds == null || seconds <= 0) return 0;
    final clamped = seconds.clamp(5, _maxDurationSeconds);
    return ((clamped + 2) ~/ _stepSeconds)
        .clamp(1, _maxDurationSeconds ~/ _stepSeconds);
  }

  int _selectedTab = 0; // 0: Normal set, 1: Warm-up Set

  int? _normalSeconds;
  int? _warmUpSeconds;

  late FixedExtentScrollController _scrollController;
  bool _isProgrammaticSync = false;

  @override
  void initState() {
    super.initState();
    _normalSeconds = widget.initialNormalRestSeconds != null &&
            widget.initialNormalRestSeconds! > 0
        ? widget.initialNormalRestSeconds!.clamp(0, _maxDurationSeconds)
        : null;
    _warmUpSeconds = widget.initialWarmUpRestSeconds != null &&
            widget.initialWarmUpRestSeconds! > 0
        ? widget.initialWarmUpRestSeconds!.clamp(0, _maxDurationSeconds)
        : null;

    final initialSeconds = _selectedTab == 0 ? _normalSeconds : _warmUpSeconds;
    final initialIndex = secondsToIndex(initialSeconds);
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _selectedTab) return;
    setState(() {
      _selectedTab = index;
    });

    final targetSeconds = _selectedTab == 0 ? _normalSeconds : _warmUpSeconds;
    final targetIndex = secondsToIndex(targetSeconds);

    _isProgrammaticSync = true;
    if (_scrollController.hasClients) {
      _scrollController.jumpToItem(targetIndex);
    }
    _isProgrammaticSync = false;
  }

  void _onWheelChanged(int index) {
    if (_isProgrammaticSync) return;
    HapticFeedback.selectionClick();
    final value = indexToSeconds(index);
    setState(() {
      if (_selectedTab == 0) {
        _normalSeconds = value;
      } else {
        _warmUpSeconds = value;
      }
    });
  }

  void _onDone() {
    Navigator.of(context).pop(
      RoutineRestTimerPreset(
        normalRestSeconds: _normalSeconds,
        warmUpRestSeconds: _warmUpSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioRadius.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.lg,
            TioSpacing.lg,
            TioSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: Centered Title & Subtitle (No checkmark) ──
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rest Timer',
                      style: TextStyle(
                        fontSize: TioFontSize.size18,
                        fontWeight: TioFontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (widget.exerciseName != null &&
                        widget.exerciseName!.isNotEmpty) ...[
                      const SizedBox(height: TioSpacing.xxs),
                      Text(
                        widget.exerciseName!,
                        style: TextStyle(
                          fontSize: TioFontSize.size14,
                          fontWeight: TioFontWeight.w400,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: TioSpacing.lg),

              // ── Tab Switcher: Normal set / Warm-up Set Slider Switch ──
              _RoutineRestTimerSliderSwitch(
                selectedIndex: _selectedTab,
                onSelected: _onTabChanged,
              ),
              const SizedBox(height: TioSpacing.lg),

              // ── Single Wheel with selection pill ──
              SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      key: const ValueKey('routine-rest-timer-selection-pill'),
                      height: TioWheelPickerTokens.selectionHeight,
                      margin: const EdgeInsets.symmetric(
                        horizontal: TioSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant.withAlpha(
                          TioWheelPickerTokens.selectionSurfaceAlpha,
                        ),
                        borderRadius: BorderRadius.circular(TioRadius.md),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      key: const ValueKey('routine-rest-timer-wheel'),
                      controller: _scrollController,
                      itemExtent: TioWheelPickerTokens.itemExtent,
                      perspective: TioWheelPickerTokens.perspective,
                      diameterRatio: TioWheelPickerTokens.diameterRatio,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: _onWheelChanged,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _itemCount,
                        builder: (context, index) {
                          final isSelected = _scrollController.hasClients &&
                              _scrollController.selectedItem == index;
                          final label =
                              RoutineRestTimerFormatter.formatWheelItem(index);
                          return Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: isSelected
                                    ? TioWheelPickerTokens.selectedFontSize
                                    : TioFontSize.size16,
                                fontWeight: isSelected
                                    ? TioFontWeight.w700
                                    : TioFontWeight.w400,
                                color: isSelected
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TioSpacing.xl),

              // ── Done Button ──
              TioButton.primary(
                key: const ValueKey('routine-rest-timer-done-button'),
                label: 'Done',
                expand: true,
                onPressed: _onDone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineRestTimerSliderSwitch extends StatelessWidget {
  const _RoutineRestTimerSliderSwitch({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          if (details.primaryDelta != null) {
            if (details.primaryDelta! > 2 && selectedIndex != 1) {
              HapticFeedback.selectionClick();
              onSelected(1);
            } else if (details.primaryDelta! < -2 && selectedIndex != 0) {
              HapticFeedback.selectionClick();
              onSelected(0);
            }
          }
        },
        child: Container(
          width: 230,
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(TioRadius.full),
          ),
          child: Stack(
            children: [
              // ── Physical Animated Sliding Pill Thumb ──
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(TioRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Labels over the sliding thumb ──
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: const ValueKey('routine-rest-timer-tab-normal'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selectedIndex != 0) {
                          HapticFeedback.selectionClick();
                          onSelected(0);
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            fontSize: TioFontSize.size12,
                            fontWeight: selectedIndex == 0
                                ? TioFontWeight.w600
                                : TioFontWeight.w400,
                            color: selectedIndex == 0
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                          child: const Text('Normal set'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      key: const ValueKey('routine-rest-timer-tab-warmup'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selectedIndex != 1) {
                          HapticFeedback.selectionClick();
                          onSelected(1);
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            fontSize: TioFontSize.size12,
                            fontWeight: selectedIndex == 1
                                ? TioFontWeight.w600
                                : TioFontWeight.w400,
                            color: selectedIndex == 1
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                          child: const Text('Warm-up Set'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
