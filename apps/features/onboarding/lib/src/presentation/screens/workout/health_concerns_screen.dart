import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class HealthConcernsScreen extends StatelessWidget {
  const HealthConcernsScreen({
    required this.value,
    required this.flowPlan,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final String value;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.healthConcerns,
      flowPlan: flowPlan,
      title: 'Any workout concerns to note?',
      description:
          'Optional: share anything Tio should keep in mind for your training context. This stays in-memory only in this slice.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TioInput(
            key: const ValueKey('workout-health-concerns-input'),
            value: value,
            onChanged: onChanged,
            label: 'Health concerns',
            hint: 'Anything you want Tio to keep in mind',
            helperText: 'Optional',
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            maxLines: 6,
          ),
          const SizedBox(height: TioSpacing.medium),
          Text(
            'You can leave this blank if there is nothing to add.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tioColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
