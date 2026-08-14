import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class FocusAreasScreen extends StatelessWidget {
  const FocusAreasScreen({
    required this.selectedAreas,
    required this.flowPlan,
    required this.onToggled,
    super.key,
    this.errorText,
  });

  final Set<WorkoutFocusArea> selectedAreas;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutFocusArea> onToggled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.focusAreas,
      flowPlan: flowPlan,
      title: 'Which areas do you want to focus on?',
      description:
          'Pick one or more priorities. Choosing Full body keeps every major area selected together.',
      errorText: errorText,
      child: Column(
        children: [
          for (final area in WorkoutFocusArea.values) ...[
            WorkoutChoiceCard(
              id: 'focus-${area.name}',
              title: _label(area),
              description: _description(area),
              icon: _icon(area),
              selected: selectedAreas.contains(area),
              selectionStyle: WorkoutSelectionStyle.multi,
              onTap: () => onToggled(area),
            ),
            if (area != WorkoutFocusArea.values.last)
              const SizedBox(height: TioSpacing.medium),
          ],
        ],
      ),
    );
  }
}

String _label(WorkoutFocusArea area) => switch (area) {
      WorkoutFocusArea.fullBody => 'Full body',
      WorkoutFocusArea.shoulders => 'Shoulders',
      WorkoutFocusArea.arms => 'Arms',
      WorkoutFocusArea.back => 'Back',
      WorkoutFocusArea.chest => 'Chest',
      WorkoutFocusArea.abs => 'Abs',
      WorkoutFocusArea.glutes => 'Glutes',
      WorkoutFocusArea.legs => 'Legs',
      WorkoutFocusArea.cardio => 'Cardio',
    };

String _description(WorkoutFocusArea area) => switch (area) {
      WorkoutFocusArea.fullBody =>
        'Keep every major muscle group in the plan together.',
      WorkoutFocusArea.shoulders => 'Pressing stability, delts, and upper-body balance.',
      WorkoutFocusArea.arms => 'Biceps, triceps, and direct arm emphasis.',
      WorkoutFocusArea.back => 'Posture, pulling strength, and upper-back support.',
      WorkoutFocusArea.chest => 'Pressing strength and chest development.',
      WorkoutFocusArea.abs => 'Core control, bracing, and trunk endurance.',
      WorkoutFocusArea.glutes => 'Hip drive, glute strength, and lower-body support.',
      WorkoutFocusArea.legs => 'Quads, hamstrings, calves, and lower-body strength.',
      WorkoutFocusArea.cardio => 'Conditioning, stamina, and heart-rate work.',
    };

IconData _icon(WorkoutFocusArea area) => switch (area) {
      WorkoutFocusArea.fullBody => Icons.accessibility_new_outlined,
      WorkoutFocusArea.shoulders => Icons.pan_tool_outlined,
      WorkoutFocusArea.arms => Icons.sports_mma_outlined,
      WorkoutFocusArea.back => Icons.keyboard_capslock_outlined,
      WorkoutFocusArea.chest => Icons.favorite_border,
      WorkoutFocusArea.abs => Icons.crop_portrait_outlined,
      WorkoutFocusArea.glutes => Icons.hiking_outlined,
      WorkoutFocusArea.legs => Icons.directions_run_outlined,
      WorkoutFocusArea.cardio => Icons.monitor_heart_outlined,
    };
