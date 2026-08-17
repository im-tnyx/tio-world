import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

class WorkoutScreenScaffold extends StatelessWidget {
  const WorkoutScreenScaffold({
    required this.stepId,
    required this.flowPlan,
    required this.title,
    required this.child,
    super.key,
    this.description,
    this.errorText,
  });

  final WorkoutStepId stepId;
  final WorkoutFlowPlan flowPlan;
  final String title;
  final String? description;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final stepNumber = flowPlan.indexOf(stepId) + 1;
    final stepCount = flowPlan.stepCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Workout step $stepNumber of $stepCount, $title',
          value: '$stepNumber of $stepCount',
          header: true,
          container: true,
          explicitChildNodes: true,
          child: TioScreenHeader(
            title: title,
            subtitle: description,
          ),
        ),
        const SizedBox(height: TioSpacing.large),
        child,
        if (errorText case final message?) ...[
          const SizedBox(height: TioSpacing.medium),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: ValueKey('workout-${stepId.name}-error'),
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

enum WorkoutSelectionStyle { single, multi }

class WorkoutChoiceCard extends StatelessWidget {
  const WorkoutChoiceCard({
    required this.id,
    required this.title,
    required this.selected,
    required this.selectionStyle,
    required this.onTap,
    super.key,
    this.description,
    this.icon,
  });

  final String id;
  final String title;
  final String? description;
  final bool selected;
  final WorkoutSelectionStyle selectionStyle;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      button: true,
      selected: selected,
      label: description == null ? title : '$title. $description',
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: TioCardTokens.selectedContainerAlpha)
            : colors.surface,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: InkWell(
          key: ValueKey('workout-choice-$id'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(TioCardTokens.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(TioSpacing.large),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outlineStrong.withValues(alpha: 0.35),
                width: selected
                    ? TioCardTokens.selectedBorderWidth
                    : TioCardTokens.unselectedBorderWidth,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      icon,
                      color: selected
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.medium),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected ? colors.primary : colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (description case final details?) ...[
                        const SizedBox(height: TioSpacing.small),
                        Text(
                          details,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: TioSpacing.medium),
                Icon(
                  switch (selectionStyle) {
                    WorkoutSelectionStyle.single => selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    WorkoutSelectionStyle.multi => selected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  },
                  color: selected ? colors.primary : colors.outlineStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
