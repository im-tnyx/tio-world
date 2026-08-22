import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import '../profile/profile_screen_components.dart';

class NutritionProfileScreenScaffold extends StatelessWidget {
  const NutritionProfileScreenScaffold({
    required this.stepId,
    required this.title,
    required this.description,
    required this.child,
    super.key,
    this.errorText,
  });

  final NutritionProfileStepId stepId;
  final String title;
  final String description;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    const flow = NutritionProfileFlowPlan();
    final stepNumber = flow.indexOf(stepId) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label:
              'Nutrition profile step $stepNumber of ${flow.stepCount}, $title',
          value: '$stepNumber of ${flow.stepCount}',
          header: true,
          container: true,
          explicitChildNodes: true,
          child: TioScreenHeader(title: title, subtitle: description),
        ),
        const SizedBox(height: TioSpacing.lg),
        child,
        if (errorText case final message?) ...[
          const SizedBox(height: TioSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: ValueKey('nutrition-profile-${stepId.name}-error'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class NutritionProfileChoiceCard extends StatelessWidget {
  const NutritionProfileChoiceCard({
    required this.id,
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String id;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileChoiceCard(
      id: id,
      title: title,
      selected: selected,
      onTap: onTap,
    );
  }
}
