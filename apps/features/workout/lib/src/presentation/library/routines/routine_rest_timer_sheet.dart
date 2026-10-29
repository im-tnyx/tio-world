import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/models/routine_rest_timer_preset.dart';

/// Shows the Routine Rest Timer configuration sheet.
Future<RoutineRestTimerPreset?> showRoutineRestTimerSheet({
  required BuildContext context,
  required int? initialNormalRestSeconds,
  required int? initialWarmUpRestSeconds,
}) =>
    showTioEditorSheet<RoutineRestTimerPreset>(
      context: context,
      useSafeArea: true,
      builder: (context) => RoutineRestTimerSheet(
        initialNormalRestSeconds: initialNormalRestSeconds,
        initialWarmUpRestSeconds: initialWarmUpRestSeconds,
      ),
    );

/// Modal sheet for configuring Normal and Warm-up Rest Timer presets independently.
class RoutineRestTimerSheet extends StatefulWidget {
  const RoutineRestTimerSheet({
    this.initialNormalRestSeconds,
    this.initialWarmUpRestSeconds,
    super.key,
  });

  final int? initialNormalRestSeconds;
  final int? initialWarmUpRestSeconds;

  @override
  State<RoutineRestTimerSheet> createState() => _RoutineRestTimerSheetState();
}

class _RoutineRestTimerSheetState extends State<RoutineRestTimerSheet> {
  static const int _maxMinutes = 10;
  static const List<int> _secondSteps = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];

  int _selectedTab = 0; // 0: Normal set, 1: Warm-up Set

  int? _normalSeconds;
  int? _warmUpSeconds;

  int _lastNormalNonZero = 90;
  int _lastWarmUpNonZero = 45;

  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _secondController;
  bool _isProgrammaticSync = false;

  @override
  void initState() {
    super.initState();
    _normalSeconds = widget.initialNormalRestSeconds;
    _warmUpSeconds = widget.initialWarmUpRestSeconds;

    if (_normalSeconds != null && _normalSeconds! > 0) {
      _lastNormalNonZero = _normalSeconds!;
    }
    if (_warmUpSeconds != null && _warmUpSeconds! > 0) {
      _lastWarmUpNonZero = _warmUpSeconds!;
    }

    final initialSeconds = _selectedTab == 0 ? _normalSeconds : _warmUpSeconds;
    final initialDuration =
        initialSeconds ?? (_selectedTab == 0 ? _lastNormalNonZero : _lastWarmUpNonZero);

    final initialMinutes = (initialDuration ~/ 60).clamp(0, _maxMinutes);
    final sec = initialDuration % 60;
    final secondIndex = _nearestSecondStepIndex(sec);

    _minuteController = FixedExtentScrollController(initialItem: initialMinutes);
    _secondController = FixedExtentScrollController(initialItem: secondIndex);
  }

  @override
  void dispose() {
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  int _nearestSecondStepIndex(int seconds) {
    var bestIndex = 0;
    var minDiff = 999;
    for (var i = 0; i < _secondSteps.length; i++) {
      final diff = (seconds - _secondSteps[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  void _syncControllersForActiveTab() {
    final current = _selectedTab == 0 ? _normalSeconds : _warmUpSeconds;
    final duration =
        current ?? (_selectedTab == 0 ? _lastNormalNonZero : _lastWarmUpNonZero);

    final minutes = (duration ~/ 60).clamp(0, _maxMinutes);
    final sec = duration % 60;
    final secondIndex = _nearestSecondStepIndex(sec);

    _isProgrammaticSync = true;
    if (_minuteController.hasClients) {
      _minuteController.jumpToItem(minutes);
    }
    if (_secondController.hasClients) {
      _secondController.jumpToItem(secondIndex);
    }
    _isProgrammaticSync = false;
  }

  void _onTabChanged(int index) {
    if (index == _selectedTab) return;
    setState(() {
      _selectedTab = index;
    });
    _syncControllersForActiveTab();
  }

  void _onToggleEnabled(bool enabled) {
    setState(() {
      if (enabled) {
        final last = _selectedTab == 0 ? _lastNormalNonZero : _lastWarmUpNonZero;
        if (_selectedTab == 0) {
          _normalSeconds = last;
        } else {
          _warmUpSeconds = last;
        }
      } else {
        if (_selectedTab == 0) {
          _normalSeconds = null;
        } else {
          _warmUpSeconds = null;
        }
      }
    });
    if (enabled) {
      _syncControllersForActiveTab();
    }
  }

  void _onWheelChanged() {
    if (_isProgrammaticSync) return;
    final current = _selectedTab == 0 ? _normalSeconds : _warmUpSeconds;
    if (current == null) return;

    final minutes = _minuteController.selectedItem.clamp(0, _maxMinutes);
    final secIndex = _secondController.selectedItem.clamp(0, _secondSteps.length - 1);
    final seconds = _secondSteps[secIndex];
    final total = (minutes * 60) + seconds;

    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTab == 0) {
        _normalSeconds = total;
        if (total > 0) _lastNormalNonZero = total;
      } else {
        _warmUpSeconds = total;
        if (total > 0) _lastWarmUpNonZero = total;
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
    final current = _selectedTab == 0 ? _normalSeconds : _warmUpSeconds;
    final isEnabled = current != null;

    return TioEditorSheet(
      title: 'Rest Timer',
      supportingText: 'Set rest duration between sets.',
      actions: TioButton.primary(
        key: const ValueKey('routine-rest-timer-done-button'),
        label: 'Done',
        expand: true,
        onPressed: _onDone,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TioTabSwitcher(
            tabs: const ['Normal set', 'Warm-up Set'],
            selectedIndex: _selectedTab,
            onSelected: _onTabChanged,
          ),
          const SizedBox(height: TioSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.md,
              vertical: TioSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(TioRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTab == 0 ? 'Normal Rest Timer' : 'Warm-up Rest Timer',
                        style: TextStyle(
                          fontSize: TioFontSize.size14,
                          fontWeight: TioFontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.xxs),
                      Text(
                        isEnabled
                            ? RoutineRestTimerFormatter.formatSeconds(current)
                            : 'OFF',
                        style: TextStyle(
                          fontSize: TioFontSize.size13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  key: const ValueKey('routine-rest-timer-switch'),
                  value: isEnabled,
                  onChanged: _onToggleEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.lg),
          if (isEnabled)
            SizedBox(
              height: TioWheelPickerTokens.viewportHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    key: const ValueKey('routine-rest-timer-selection-pill'),
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
                  Row(
                    children: [
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          key: const ValueKey('routine-rest-timer-minutes-wheel'),
                          controller: _minuteController,
                          itemExtent: TioWheelPickerTokens.itemExtent,
                          perspective: TioWheelPickerTokens.perspective,
                          diameterRatio: TioWheelPickerTokens.diameterRatio,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (_) => _onWheelChanged(),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _maxMinutes + 1,
                            builder: (context, index) {
                              final isSelected =
                                  _minuteController.hasClients &&
                                  _minuteController.selectedItem == index;
                              return Center(
                                child: Text(
                                  '$index min',
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
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          key: const ValueKey('routine-rest-timer-seconds-wheel'),
                          controller: _secondController,
                          itemExtent: TioWheelPickerTokens.itemExtent,
                          perspective: TioWheelPickerTokens.perspective,
                          diameterRatio: TioWheelPickerTokens.diameterRatio,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (_) => _onWheelChanged(),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _secondSteps.length,
                            builder: (context, index) {
                              final isSelected =
                                  _secondController.hasClients &&
                                  _secondController.selectedItem == index;
                              return Center(
                                child: Text(
                                  '${_secondSteps[index]} s',
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
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: TioSpacing.xl),
              child: Center(
                child: Text(
                  'Timer is OFF for this category.\nTurn on the switch to set a duration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: TioFontSize.size14,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
