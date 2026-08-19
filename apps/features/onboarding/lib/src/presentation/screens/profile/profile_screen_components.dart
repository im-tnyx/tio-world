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
          const SizedBox(height: TioSpacing.lg),
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
          const SizedBox(height: TioSpacing.md),
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
    final colors = context.tioColors;

    return Semantics(
      button: true,
      selected: selected,
      label: description == null ? title : '$title. $description',
      child: Material(
        color: selected
            ? colors.primary.withValues(
                alpha: TioCardTokens.selectedContainerAlpha,
              )
            : colors.surface,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: InkWell(
          key: ValueKey(id),
          onTap: onTap,
          borderRadius: BorderRadius.circular(TioCardTokens.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: TioDuration.ms150),
            padding: const EdgeInsets.all(TioSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outlineStrong.withValues(
                        alpha: TioOpacity.opacity35,
                      ),
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
                  const SizedBox(width: TioSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected ? colors.primary : colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size16,
                        ),
                      ),
                      if (description case final desc?) ...[
                        const SizedBox(height: TioSpacing.xs),
                        Text(
                          desc,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: TioFontSize.size13,
                            height: TioLineHeight.height130,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: TioSpacing.md),
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
