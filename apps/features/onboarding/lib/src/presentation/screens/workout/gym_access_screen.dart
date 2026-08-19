import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class GymAccessScreen extends StatelessWidget {
  const GymAccessScreen({
    required this.selectedAccess,
    required this.flowPlan,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final WorkoutGymAccess? selectedAccess;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutGymAccess> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.gymAccess,
      flowPlan: flowPlan,
      title: 'Where will you mostly work out?',
      description:
          'This decides whether Tio should ask about home equipment before building your plan.',
      errorText: errorText,
      child: Column(
        children: [
          WorkoutChoiceCard(
            id: 'gym-access-gym',
            title: 'Gym access',
            description: 'You can train in a gym with standard equipment.',
            icon: Icons.fitness_center,
            selected: selectedAccess == WorkoutGymAccess.gym,
            selectionStyle: WorkoutSelectionStyle.single,
            onTap: () => onSelected(WorkoutGymAccess.gym),
          ),
          const SizedBox(height: TioSpacing.md),
          WorkoutChoiceCard(
            id: 'gym-access-home',
            title: 'Home workouts',
            description:
                'You mostly train at home, so Tio should ask about the equipment you already have.',
            icon: Icons.home_outlined,
            selected: selectedAccess == WorkoutGymAccess.home,
            selectionStyle: WorkoutSelectionStyle.single,
            onTap: () => onSelected(WorkoutGymAccess.home),
          ),
        ],
      ),
    );
  }
}
