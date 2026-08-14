import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({
    required this.selectedEquipment,
    required this.flowPlan,
    required this.onToggled,
    super.key,
    this.errorText,
  });

  final Set<WorkoutEquipment> selectedEquipment;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutEquipment> onToggled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.equipment,
      flowPlan: flowPlan,
      title: 'What equipment do you have at home?',
      description:
          'Pick every option you can reliably use so Tio can avoid recommending unavailable movements.',
      errorText: errorText,
      child: Column(
        children: [
          for (final equipment in WorkoutEquipment.values) ...[
            WorkoutChoiceCard(
              id: 'equipment-${equipment.name}',
              title: _label(equipment),
              description: _description(equipment),
              icon: _icon(equipment),
              selected: selectedEquipment.contains(equipment),
              selectionStyle: WorkoutSelectionStyle.multi,
              onTap: () => onToggled(equipment),
            ),
            if (equipment != WorkoutEquipment.values.last)
              const SizedBox(height: TioSpacing.medium),
          ],
        ],
      ),
    );
  }
}

String _label(WorkoutEquipment equipment) => switch (equipment) {
      WorkoutEquipment.dumbbells => 'Dumbbells',
      WorkoutEquipment.bench => 'Bench',
      WorkoutEquipment.mat => 'Mat',
      WorkoutEquipment.barbell => 'Barbell',
      WorkoutEquipment.bands => 'Resistance bands',
      WorkoutEquipment.kettlebell => 'Kettlebell',
    };

String _description(WorkoutEquipment equipment) => switch (equipment) {
      WorkoutEquipment.dumbbells => 'Best for strength work and accessory lifts.',
      WorkoutEquipment.bench => 'Useful for presses, rows, and supported movements.',
      WorkoutEquipment.mat => 'Helpful for floor work, mobility, and core training.',
      WorkoutEquipment.barbell => 'Supports heavier compound lifting at home.',
      WorkoutEquipment.bands => 'Good for scalable resistance and warm-ups.',
      WorkoutEquipment.kettlebell => 'Useful for swings, carries, and conditioning.',
    };

IconData _icon(WorkoutEquipment equipment) => switch (equipment) {
      WorkoutEquipment.dumbbells => Icons.fitness_center,
      WorkoutEquipment.bench => Icons.event_seat_outlined,
      WorkoutEquipment.mat => Icons.crop_16_9_outlined,
      WorkoutEquipment.barbell => Icons.sports_gymnastics_outlined,
      WorkoutEquipment.bands => Icons.sync_alt_outlined,
      WorkoutEquipment.kettlebell => Icons.sports_handball_outlined,
    };
