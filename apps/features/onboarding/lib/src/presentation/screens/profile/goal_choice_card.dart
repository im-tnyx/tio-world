import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Shared visual contract for onboarding goal-choice cards.
///
/// Keep this composition pixel-compatible with the existing Profile Goal cards
/// so Body Goal can reuse the same interaction and visual language.
class GoalChoiceCard extends StatelessWidget {
  const GoalChoiceCard({
    required this.id,
    required this.title,
    required this.description,
    required this.svgAsset,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String id;
  final String title;
  final String description;
  final String svgAsset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Material(
      color: isSelected
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
          padding: const EdgeInsets.all(TioCardTokens.padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TioCardTokens.radius),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outlineStrong.withValues(
                      alpha: TioCardTokens.unselectedOutlineAlpha,
                    ),
              width: isSelected
                  ? TioCardTokens.selectedBorderWidth
                  : TioCardTokens.unselectedBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    svgAsset,
                    package: 'tio_core',
                    width: TioSize.dp24,
                    height: TioSize.dp24,
                    colorFilter: ColorFilter.mode(
                      isSelected ? colors.primary : colors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: TioFontSize.size16,
                        fontWeight: isSelected
                            ? TioFontWeight.w600
                            : TioFontWeight.w500,
                        color: isSelected
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: TioSize.dp24,
                    color: isSelected ? colors.primary : colors.outlineStrong,
                  ),
                ],
              ),
              const SizedBox(height: TioSpacing.xs),
              Text(
                description,
                style: TextStyle(
                  fontSize: TioFontSize.size14,
                  color: colors.textSecondary,
                  height: TioLineHeight.height130,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
