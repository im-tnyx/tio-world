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
          'Choose the structure you prefer. This captures your preference only; program generation stays in the Workout domain.',
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
        'Let Tio choose a split from your goals, schedule, and experience.',
      WorkoutSplit.fullBody => 'Train the whole body across each main session.',
      WorkoutSplit.upperLower =>
        'Alternate upper-body and lower-body focused sessions.',
      WorkoutSplit.ppl => 'Separate push, pull, and legs across the week.',
      WorkoutSplit.bodyPart => 'Use more isolated muscle-group training days.',
    };
