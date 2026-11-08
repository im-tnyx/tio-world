import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Shows the bottom sheet to edit workout duration with 3-drum wheels (Hours, Minutes, Seconds).
Future<Duration?> showWorkoutDurationPickerSheet({
  required BuildContext context,
  required Duration initialDuration,
}) {
  return showModalBottomSheet<Duration>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => WorkoutDurationPickerSheet(
      initialDuration: initialDuration,
    ),
  );
}

/// Bottom sheet for picking workout duration with Hours, Minutes, and Seconds wheels.
class WorkoutDurationPickerSheet extends StatefulWidget {
  const WorkoutDurationPickerSheet({
    required this.initialDuration,
    super.key,
  });

  final Duration initialDuration;

  @override
  State<WorkoutDurationPickerSheet> createState() =>
      _WorkoutDurationPickerSheetState();
}

class _WorkoutDurationPickerSheetState
    extends State<WorkoutDurationPickerSheet> {
  static const int _maxHours = 24; // 0..23
  static const int _maxMinutes = 60; // 0..59
  static const int _maxSeconds = 60; // 0..59

  late int _selectedHours;
  late int _selectedMinutes;
  late int _selectedSeconds;

  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;
  late final FixedExtentScrollController _secondsController;

  @override
  void initState() {
    super.initState();
    final totalSeconds = widget.initialDuration.inSeconds;
    if (totalSeconds < 0) {
      _selectedHours = 0;
      _selectedMinutes = 0;
      _selectedSeconds = 0;
    } else {
      _selectedHours = widget.initialDuration.inHours.clamp(0, _maxHours - 1);
      _selectedMinutes =
          (widget.initialDuration.inMinutes % 60).clamp(0, _maxMinutes - 1);
      _selectedSeconds =
          (widget.initialDuration.inSeconds % 60).clamp(0, _maxSeconds - 1);
    }

    _hoursController =
        FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController =
        FixedExtentScrollController(initialItem: _selectedMinutes);
    _secondsController =
        FixedExtentScrollController(initialItem: _selectedSeconds);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _onDone() {
    final result = Duration(
      hours: _selectedHours,
      minutes: _selectedMinutes,
      seconds: _selectedSeconds,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TioRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.lg,
          TioSpacing.md,
          TioSpacing.lg,
          TioSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: TioSize.dp40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.md),

            // Title
            Text(
              'Workout Duration',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: TioFontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TioSpacing.lg),

            // Column Headers
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Hours',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: TioFontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Minutes',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: TioFontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Seconds',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: TioFontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.sm),

            // Wheels
            SizedBox(
              height: TioWheelPickerTokens.viewportHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center selection pill
                  Container(
                    key: const ValueKey('workout-duration-selection-pill'),
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

                  // Three drums
                  Row(
                    children: [
                      // Hours wheel
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          key: const ValueKey('workout-duration-hours-wheel'),
                          controller: _hoursController,
                          itemExtent: TioWheelPickerTokens.itemExtent,
                          perspective: TioWheelPickerTokens.perspective,
                          diameterRatio: TioWheelPickerTokens.diameterRatio,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedHours = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _maxHours,
                            builder: (context, index) {
                              final isSelected = _selectedHours == index;
                              return Center(
                                child: Text(
                                  '$index',
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

                      // Minutes wheel
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          key: const ValueKey('workout-duration-minutes-wheel'),
                          controller: _minutesController,
                          itemExtent: TioWheelPickerTokens.itemExtent,
                          perspective: TioWheelPickerTokens.perspective,
                          diameterRatio: TioWheelPickerTokens.diameterRatio,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMinutes = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _maxMinutes,
                            builder: (context, index) {
                              final isSelected = _selectedMinutes == index;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
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

                      // Seconds wheel
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          key: const ValueKey('workout-duration-seconds-wheel'),
                          controller: _secondsController,
                          itemExtent: TioWheelPickerTokens.itemExtent,
                          perspective: TioWheelPickerTokens.perspective,
                          diameterRatio: TioWheelPickerTokens.diameterRatio,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSeconds = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _maxSeconds,
                            builder: (context, index) {
                              final isSelected = _selectedSeconds == index;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
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
            ),
            const SizedBox(height: TioSpacing.lg),

            // Done button
            TioButton.primary(
              key: const ValueKey('workout-duration-picker-done'),
              label: 'Done',
              expand: true,
              onPressed: _onDone,
            ),
          ],
        ),
      ),
    );
  }
}
