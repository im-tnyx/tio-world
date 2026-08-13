import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

class ProfileScreenScaffold extends StatelessWidget {
  const ProfileScreenScaffold({
    required this.stepId,
    required this.title,
    required this.description,
    required this.child,
    super.key,
    this.errorText,
  });

  final ProfileStepId stepId;
  final String title;
  final String description;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    const flow = ProfileFlowPlan();
    final stepNumber = flow.indexOf(stepId) + 1;
    final stepCount = ProfileFlowPlan.orderedSteps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Profile step $stepNumber of $stepCount, $title',
          value: '$stepNumber of $stepCount',
          header: true,
          container: true,
          explicitChildNodes: true,
          child: TioScreenHeader(
            title: title,
            subtitle: description,
          ),
        ),
        const SizedBox(height: TioSpacing.extraLarge),
        child,
        if (errorText case final message?) ...[
          const SizedBox(height: TioSpacing.medium),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: ValueKey('profile-${stepId.name}-error'),
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

class ProfileChoiceCard extends StatelessWidget {
  const ProfileChoiceCard({
    required this.id,
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: description == null ? title : '$title. $description',
      child: TioCard(
        key: ValueKey('profile-choice-$id'),
        variant: selected ? TioCardVariant.elevated : TioCardVariant.outlined,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (description case final details?) ...[
                    const SizedBox(height: TioSpacing.small),
                    Text(
                      details,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tioColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: TioSpacing.medium),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected
                  ? context.tioColors.primary
                  : context.tioColors.outlineStrong,
            ),
          ],
        ),
      ),
    );
  }
}

String profileNumberValue(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
