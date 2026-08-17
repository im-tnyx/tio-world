import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class WorkoutSplitScreen extends StatelessWidget {
  const WorkoutSplitScreen({
    required this.selectedSplit,
    required this.flowPlan,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final WorkoutSplit? selectedSplit;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutSplit> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.workoutSplit,
      flowPlan: flowPlan,
      title: 'What workout split fits you?',
      description:
          'Choose how you want to divide your training sessions across the week for optimal recovery.',
      errorText: errorText,
      child: Column(
        children: [
          for (final split in WorkoutSplit.values) ...[
            WorkoutChoiceCard(
              id: 'workout-split-${split.name}',
              title: _label(split),
              description: _description(split),
              selected: selectedSplit == split,
              selectionStyle: WorkoutSelectionStyle.single,
              onTap: () => onSelected(split),
            ),
            if (split != WorkoutSplit.values.last)
              const SizedBox(height: TioSpacing.medium),
          ],
        ],
      ),
    );
  }
}

String _label(WorkoutSplit split) => switch (split) {
      WorkoutSplit.auto => 'Auto recommend',
      WorkoutSplit.fullBody => 'Full body',
      WorkoutSplit.upperLower => 'Upper / lower',
      WorkoutSplit.ppl => 'Push / pull / legs',
      WorkoutSplit.bodyPart => 'Body part split',
    };

String _description(WorkoutSplit split) => switch (split) {
      WorkoutSplit.auto =>
        'Let Tio recommend the optimal routine tailored to your goals and weekly schedule.',
      WorkoutSplit.fullBody =>
        'Target all major muscle groups in each session with built-in recovery days.',
      WorkoutSplit.upperLower =>
        'Alternate between upper-body and lower-body workouts for balanced volume.',
      WorkoutSplit.ppl =>
        'Separate pushing movements, pulling exercises, and leg training across the week.',
      WorkoutSplit.bodyPart =>
        'Focus on specific individual muscle groups on dedicated training days.',
    };
