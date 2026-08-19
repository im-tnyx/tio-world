import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({
    required this.selectedActivity,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final ProfileActivityLevel? selectedActivity;
  final ValueChanged<ProfileActivityLevel> onSelected;
  final String? errorText;

  static const _options = [
    _ActivityItem(
      level: ProfileActivityLevel.sedentary,
      title: 'Sedentary',
      description: 'I have a desk job and mostly sit.',
      steps: '<3K STEPS',
      icon: Icons.computer_outlined,
    ),
    _ActivityItem(
      level: ProfileActivityLevel.light,
      title: 'Light',
      description: 'I do occasional light activity.',
      steps: '3-7K STEPS',
      icon: Icons.directions_car_outlined,
    ),
    _ActivityItem(
      level: ProfileActivityLevel.active,
      title: 'Active',
      description: 'I move and exercise regularly.',
      steps: '7-10K STEPS',
      icon: Icons.directions_walk_outlined,
    ),
    _ActivityItem(
      level: ProfileActivityLevel.veryActive,
      title: 'Very Active',
      description: 'I perform intense physical activity.',
      steps: '10K+ STEPS',
      icon: Icons.directions_run_outlined,
    ),
    _ActivityItem(
      level: ProfileActivityLevel.dynamic,
      title: 'Dynamic',
      description: 'My activity changes day to day.',
      steps: '5-20K STEPS',
      icon: Icons.directions_bike_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.activity,
      title: "What's your typical day like?",
      description: 'This helps us calculate the calories you burn naturally.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in _options) ...[
            _ActivityCard(
              item: item,
              isSelected: selectedActivity == item.level,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(item.level);
              },
            ),
            const SizedBox(height: TioSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _ActivityItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? colors.primary.withValues(
              alpha: TioCardTokens.selectedContainerAlpha,
            )
          : colors.surface,
      borderRadius: BorderRadius.circular(TioCardTokens.radius),
      child: InkWell(
        key: ValueKey('activity-${item.level.name}'),
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
                  Icon(
                    item.icon,
                    size: TioSize.dp24,
                    color: isSelected
                        ? colors.primary
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: Text(
                      item.title,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TioSize.dp10,
                      vertical: TioSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : (isDark ? TioPalette.white : colors.surfaceRaised),
                      borderRadius: BorderRadius.circular(TioRadius.full),
                    ),
                    child: Text(
                      item.steps,
                      style: TextStyle(
                        fontSize: TioFontSize.size11,
                        fontWeight: TioFontWeight.w700,
                        letterSpacing: TioLetterSpacing.positive05,
                        color: isSelected
                            ? colors.background
                            : (isDark ? TioPalette.black : colors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TioSpacing.xs),
              Text(
                item.description,
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

class _ActivityItem {
  const _ActivityItem({
    required this.level,
    required this.title,
    required this.description,
    required this.steps,
    required this.icon,
  });

  final ProfileActivityLevel level;
  final String title;
  final String description;
  final String steps;
  final IconData icon;
}
