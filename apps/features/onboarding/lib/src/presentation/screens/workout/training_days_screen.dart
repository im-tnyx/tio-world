import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class TrainingDaysScreen extends StatelessWidget {
  const TrainingDaysScreen({
    required this.selectedDays,
    required this.flowPlan,
    required this.onToggled,
    super.key,
    this.errorText,
  });

  final Set<WorkoutTrainingDay> selectedDays;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutTrainingDay> onToggled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final textTheme = Theme.of(context).textTheme;

    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.trainingDays,
      flowPlan: flowPlan,
      title: 'Which days can you train?',
      description:
          'Pick every day that realistically fits your routine. Tio will use this availability to build your schedule.',
      errorText: errorText,
      child: Column(
        children: [
          for (final day in WorkoutTrainingDay.values) ...[
            _TrainingDayCard(
              day: day,
              isSelected: selectedDays.contains(day),
              onTap: () {
                HapticFeedback.selectionClick();
                onToggled(day);
              },
              colors: colors,
              textTheme: textTheme,
            ),
            if (day != WorkoutTrainingDay.values.last)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _TrainingDayCard extends StatelessWidget {
  const _TrainingDayCard({
    required this.day,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  final WorkoutTrainingDay day;
  final bool isSelected;
  final VoidCallback onTap;
  final TioColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: _label(day),
      child: Material(
        color: isSelected
            ? colors.primary.withValues(alpha: TioCardTokens.selectedContainerAlpha)
            : colors.surface,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: InkWell(
          key: ValueKey('workout-choice-training-day-${day.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(TioCardTokens.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.large,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : colors.outlineStrong.withValues(
                        alpha: TioCardTokens.unselectedOutlineAlpha,
                      ),
                width: isSelected
                    ? TioCardTokens.selectedBorderWidth
                    : TioCardTokens.unselectedBorderWidth,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label(day),
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.outlineStrong.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: colors.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _label(WorkoutTrainingDay day) => switch (day) {
      WorkoutTrainingDay.monday => 'Monday',
      WorkoutTrainingDay.tuesday => 'Tuesday',
      WorkoutTrainingDay.wednesday => 'Wednesday',
      WorkoutTrainingDay.thursday => 'Thursday',
      WorkoutTrainingDay.friday => 'Friday',
      WorkoutTrainingDay.saturday => 'Saturday',
      WorkoutTrainingDay.sunday => 'Sunday',
    };
