import 'package:flutter/material.dart';
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
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.trainingDays,
      flowPlan: flowPlan,
      title: 'Which days can you train?',
      description:
          'Pick every day that realistically fits your routine. Tio will use this availability later when building your schedule.',
      errorText: errorText,
      child: Column(
        children: [
          for (final day in WorkoutTrainingDay.values) ...[
            WorkoutChoiceCard(
              id: 'training-day-${day.name}',
              title: _label(day),
              description: 'Available for training',
              icon: _icon(day),
              selected: selectedDays.contains(day),
              selectionStyle: WorkoutSelectionStyle.multi,
              onTap: () => onToggled(day),
            ),
            if (day != WorkoutTrainingDay.values.last)
              const SizedBox(height: TioSpacing.medium),
          ],
          const SizedBox(height: TioSpacing.small),
          Text(
            'You can choose one day or several days.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tioColors.textSecondary,
                ),
          ),
        ],
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

IconData _icon(WorkoutTrainingDay day) => switch (day) {
      WorkoutTrainingDay.monday => Icons.looks_one_outlined,
      WorkoutTrainingDay.tuesday => Icons.looks_two_outlined,
      WorkoutTrainingDay.wednesday => Icons.looks_3_outlined,
      WorkoutTrainingDay.thursday => Icons.looks_4_outlined,
      WorkoutTrainingDay.friday => Icons.looks_5_outlined,
      WorkoutTrainingDay.saturday => Icons.calendar_view_week_outlined,
      WorkoutTrainingDay.sunday => Icons.today_outlined,
    };
