import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class SpecialEventScreen extends StatelessWidget {
  const SpecialEventScreen({
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
      stepId: WorkoutStepId.specialEvent,
      flowPlan: flowPlan,
      title: 'Are you training for a special event?',
      description:
          'Optional: add an event or milestone if you want Tio to understand the context of your training goal.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TioInput(
            key: const ValueKey('workout-special-event-input'),
            value: value,
            onChanged: onChanged,
            label: 'Special event',
            hint: 'Event or milestone',
            helperText: 'Optional',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: TioSpacing.medium),
          Text(
            'Leave this blank if you are not preparing for anything specific.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tioColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
