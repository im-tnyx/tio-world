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
    this.showHeader = true,
  });

  final ProfileStepId stepId;
  final String title;
  final String description;
  final Widget child;
  final String? errorText;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    const flow = ProfileFlowPlan();
    final stepNumber = flow.indexOf(stepId) + 1;
    final stepCount = ProfileFlowPlan.orderedSteps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
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
          const SizedBox(height: TioSpacing.large),
        ] else ...[
          Semantics(
            label: 'Profile step $stepNumber of $stepCount, $title',
            value: '$stepNumber of $stepCount',
            header: true,
            container: true,
            child: const SizedBox.shrink(),
          ),
        ],
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
    this.description,
    required this.selected,
    required this.onTap,
    this.leading,
    super.key,
  });

  final String id;
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

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
          key: ValueKey(id),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
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
                      if (description case final desc?) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
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
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
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

String profileNumberValue(double? value) {
  if (value == null) return '';
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}
