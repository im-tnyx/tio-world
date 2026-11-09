import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Shows the bottom sheet to edit a workout duration in whole-minute steps.
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

/// Bottom sheet for choosing a duration from 0 through 300 minutes.
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
  static const int _maxMinutes = 300;

  late int _selectedMinutes;
  late final FixedExtentScrollController _wheelController;
  late final bool _initialDurationExceedsMaximum;
  bool _changedOutOfRangeSelection = false;

  @override
  void initState() {
    super.initState();
    final totalSeconds = widget.initialDuration.inSeconds;
    final nonNegativeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final roundedMinutes = (nonNegativeSeconds + 30) ~/ 60;
    _initialDurationExceedsMaximum = totalSeconds > _maxMinutes * 60;
    _selectedMinutes = roundedMinutes.clamp(0, _maxMinutes);
    _wheelController = FixedExtentScrollController(
      initialItem: _selectedMinutes,
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _onDone() {
    if (_initialDurationExceedsMaximum && !_changedOutOfRangeSelection) {
      return;
    }
    Navigator.of(context).pop(Duration(minutes: _selectedMinutes));
  }

  static String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}min';
  }

  static String _formatExactDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds ~/ 60) % 60;
    final seconds = totalSeconds % 60;
    if (hours == 0 && minutes == 0) return '${seconds}sec';
    if (hours == 0) return '${minutes}min ${seconds}sec';
    return '${hours}h ${minutes}min ${seconds}sec';
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
            Center(
              child: Container(
                width: TioSize.dp40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(
                    alpha: TioOpacity.opacity40,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.md),
            Text(
              'Workout Duration',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: TioFontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TioSpacing.lg),
            if (_initialDurationExceedsMaximum) ...[
              Text(
                'Current duration: ${_formatExactDuration(widget.initialDuration)}. '
                'Choose a new value to change it.',
                key: const ValueKey('workout-duration-over-limit-notice'),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TioSpacing.sm),
            ],
            SizedBox(
              height: TioWheelPickerTokens.viewportHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    key: const ValueKey('workout-duration-selection-pill'),
                    height: TioWheelPickerTokens.selectionHeight,
                    margin: const EdgeInsets.symmetric(
                      horizontal:
                          TioWheelPickerTokens.selectionHorizontalMargin,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withAlpha(
                        TioWheelPickerTokens.selectionSurfaceAlpha,
                      ),
                      borderRadius: BorderRadius.circular(TioRadius.md),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    key: const ValueKey('workout-duration-wheel'),
                    controller: _wheelController,
                    itemExtent: TioWheelPickerTokens.itemExtent,
                    perspective: TioWheelPickerTokens.perspective,
                    diameterRatio: TioWheelPickerTokens.diameterRatio,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMinutes = index;
                        if (_initialDurationExceedsMaximum) {
                          _changedOutOfRangeSelection = true;
                        }
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _maxMinutes + 1,
                      builder: (context, index) {
                        final isSelected = _selectedMinutes == index;
                        return Center(
                          child: Text(
                            _formatMinutes(index),
                            key: ValueKey('workout-duration-option-$index'),
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
            const SizedBox(height: TioSpacing.lg),
            TioButton.primary(
              key: const ValueKey('workout-duration-picker-done'),
              label: 'Done',
              expand: true,
              onPressed:
                  _initialDurationExceedsMaximum && !_changedOutOfRangeSelection
                      ? null
                      : _onDone,
            ),
          ],
        ),
      ),
    );
  }
}
