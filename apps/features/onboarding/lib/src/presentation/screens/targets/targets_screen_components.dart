import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

class TargetsScreenScaffold extends StatelessWidget {
  const TargetsScreenScaffold({
    required this.stepId,
    required this.title,
    required this.description,
    required this.child,
    super.key,
    this.errorText,
  });

  final TargetStepId stepId;
  final String title;
  final String description;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    const flow = TargetsFlowPlan();
    final stepNumber = flow.indexOf(stepId) + 1;
    final stepCount = flow.stepCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Target step $stepNumber of $stepCount, $title',
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
              key: ValueKey('targets-${stepId.name}-error'),
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

class TargetsStatusChip extends StatelessWidget {
  const TargetsStatusChip({
    required this.label,
    required this.isRecommended,
    super.key,
  });

  final String label;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final bg = isRecommended
        ? colors.success.withValues(alpha: 0.12)
        : colors.warning.withValues(alpha: 0.12);
    final fg = isRecommended ? colors.success : colors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.medium,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TioRadius.extraLarge),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );

  }
}
