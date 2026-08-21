import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

class TargetsFlowPlanScope extends InheritedWidget {
  const TargetsFlowPlanScope({
    required this.flowPlan,
    required super.child,
    super.key,
  });

  final TargetsFlowPlan flowPlan;

  static TargetsFlowPlan? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TargetsFlowPlanScope>()
        ?.flowPlan;
  }

  @override
  bool updateShouldNotify(TargetsFlowPlanScope oldWidget) =>
      oldWidget.flowPlan.steps != flowPlan.steps;
}

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
    final flow = TargetsFlowPlanScope.maybeOf(context) ?? const TargetsFlowPlan();
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
        const SizedBox(height: TioSpacing.xl),
        child,
        if (errorText case final message?) ...[
          const SizedBox(height: TioSpacing.md),
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
        ? colors.success.withValues(alpha: TioOpacity.opacity12)
        : colors.warning.withValues(alpha: TioOpacity.opacity12);
    final fg = isRecommended ? colors.success : colors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.md,
        vertical: TioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TioRadius.xl),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: TioFontWeight.w600,
            ),
      ),
    );
  }
}
