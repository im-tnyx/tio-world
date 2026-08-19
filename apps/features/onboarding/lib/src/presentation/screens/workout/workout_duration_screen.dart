import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class WorkoutDurationScreen extends StatelessWidget {
  const WorkoutDurationScreen({
    required this.selectedDuration,
    required this.flowPlan,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final WorkoutDuration? selectedDuration;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutDuration> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.workoutDuration,
      flowPlan: flowPlan,
      title: 'How long should workouts be?',
      description:
          'Choose the session length that best matches your real availability.',
      errorText: errorText,
      child: Column(
        children: [
          for (final duration in WorkoutDuration.values) ...[
            WorkoutChoiceCard(
              id: 'workout-duration-${duration.name}',
              title: _label(duration),
              description: _description(duration),
              selected: selectedDuration == duration,
              selectionStyle: WorkoutSelectionStyle.single,
              onTap: () => onSelected(duration),
            ),
            if (duration != WorkoutDuration.values.last)
              const SizedBox(height: TioSpacing.md),
          ],
        ],
      ),
    );
  }
}

String _label(WorkoutDuration duration) => switch (duration) {
      WorkoutDuration.auto => 'Auto recommend',
      WorkoutDuration.thirtyMinutes => '30 minutes',
      WorkoutDuration.sixtyMinutes => '60 minutes',
      WorkoutDuration.ninetyMinutes => '90 minutes',
      WorkoutDuration.oneHundredTwentyMinutes => '120 minutes',
    };

String _description(WorkoutDuration duration) => switch (duration) {
      WorkoutDuration.auto =>
        'Let Tio recommend a duration from your goals and weekly schedule.',
      WorkoutDuration.thirtyMinutes => 'Short, efficient sessions.',
      WorkoutDuration.sixtyMinutes =>
        'Balanced session length for most routines.',
      WorkoutDuration.ninetyMinutes => 'Longer sessions with more volume.',
      WorkoutDuration.oneHundredTwentyMinutes => 'Extended training blocks.',
    };
