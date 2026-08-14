import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class ExperienceLevelScreen extends StatelessWidget {
  const ExperienceLevelScreen({
    required this.selectedLevel,
    required this.flowPlan,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final WorkoutExperienceLevel? selectedLevel;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutExperienceLevel> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.experienceLevel,
      flowPlan: flowPlan,
      title: 'How experienced are you with training?',
      description:
          'This helps Tio tune exercise complexity, pacing, and coaching detail.',
      errorText: errorText,
      child: Column(
        children: [
          for (final level in WorkoutExperienceLevel.values) ...[
            WorkoutChoiceCard(
              id: 'experience-${level.name}',
              title: _label(level),
              description: _description(level),
              icon: _icon(level),
              selected: selectedLevel == level,
              selectionStyle: WorkoutSelectionStyle.single,
              onTap: () => onSelected(level),
            ),
            if (level != WorkoutExperienceLevel.values.last)
              const SizedBox(height: TioSpacing.medium),
          ],
        ],
      ),
    );
  }
}

String _label(WorkoutExperienceLevel level) => switch (level) {
      WorkoutExperienceLevel.fresh => 'Fresh start',
      WorkoutExperienceLevel.beginner => 'Beginner',
      WorkoutExperienceLevel.intermediate => 'Intermediate',
      WorkoutExperienceLevel.advanced => 'Advanced',
    };

String _description(WorkoutExperienceLevel level) => switch (level) {
      WorkoutExperienceLevel.fresh =>
        'You are new to structured workouts and want extra guidance.',
      WorkoutExperienceLevel.beginner =>
        'You have some experience and are rebuilding consistency.',
      WorkoutExperienceLevel.intermediate =>
        'You train regularly and can handle moderate progression.',
      WorkoutExperienceLevel.advanced =>
        'You want more demanding structure and stronger progression.',
    };

IconData _icon(WorkoutExperienceLevel level) => switch (level) {
      WorkoutExperienceLevel.fresh => Icons.flag_outlined,
      WorkoutExperienceLevel.beginner => Icons.trending_up_outlined,
      WorkoutExperienceLevel.intermediate => Icons.insights_outlined,
      WorkoutExperienceLevel.advanced => Icons.rocket_launch_outlined,
    };
