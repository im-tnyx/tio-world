import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({
    required this.selectedGoals,
    required this.onToggled,
    super.key,
    this.userName = '',
    this.errorText,
  });

  final Set<ProfileGoal> selectedGoals;
  final ValueChanged<ProfileGoal> onToggled;
  final String userName;
  final String? errorText;

  static const _goals = [
    _GoalItem(
      goal: ProfileGoal.buildMuscle,
      title: 'Build muscle',
      description: 'Gain strength and lean muscle mass',
      svgAsset: 'assets/svg_icon/ic_abs.svg',
      isMainGoal: true,
    ),
    _GoalItem(
      goal: ProfileGoal.loseWeight,
      title: 'Lose weight',
      description: 'Burn fat and improve metabolic health',
      svgAsset: 'assets/svg_icon/ic_fire.svg',
      isMainGoal: true,
    ),
    _GoalItem(
      goal: ProfileGoal.keepFit,
      title: 'Keep fit',
      description: 'Maintain energy, longevity, and overall wellness',
      svgAsset: 'assets/svg_icon/ic_keep_fit.svg',
      isMainGoal: true,
    ),
    _GoalItem(
      goal: ProfileGoal.boostStrength,
      title: 'Boost strength',
      description: 'Focus on raw power and athletic performance',
      svgAsset: 'assets/svg_icon/ic_muscle.svg',
      isMainGoal: false,
    ),
    _GoalItem(
      goal: ProfileGoal.manageStress,
      title: 'Manage stress',
      description: 'Enhance recovery, mobility, and mindfulness',
      svgAsset: 'assets/svg_icon/ic_yoga.svg',
      isMainGoal: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final hasPrimary = _goals
        .where((item) => item.isMainGoal)
        .any((item) => selectedGoals.contains(item.goal));

    final displayName = userName.trim().isNotEmpty ? userName.trim() : 'there';
    final titleText = "Hi $displayName 👋, what's your main goal?";

    return ProfileScreenScaffold(
      stepId: ProfileStepId.goal,
      title: titleText,
      description: 'Select your primary fitness objective. You can also pick supporting goals.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            !hasPrimary ? 'Please select a primary goal' : '',
            style: TextStyle(
              fontSize: TioFontSize.size12,
              fontWeight: TioFontWeight.w600,
              color: colors.primary,
              height: TioLineHeight.height150,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          for (final item in _goals) ...[
            _GoalCard(
              item: item,
              isSelected: selectedGoals.contains(item.goal),
              onTap: () {
                HapticFeedback.selectionClick();
                onToggled(item.goal);
              },
            ),
            const SizedBox(height: TioSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _GoalItem item;
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
        key: ValueKey('goal-${item.goal.name}'),
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
                    item.svgAsset,
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

class _GoalItem {
  const _GoalItem({
    required this.goal,
    required this.title,
    required this.description,
    required this.svgAsset,
    required this.isMainGoal,
  });

  final ProfileGoal goal;
  final String title;
  final String description;
  final String svgAsset;
  final bool isMainGoal;
}
