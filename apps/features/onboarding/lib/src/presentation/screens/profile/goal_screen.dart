import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'goal_choice_card.dart';
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
      description:
          'Select your primary fitness objective. You can also pick supporting goals.',
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
            GoalChoiceCard(
              id: 'goal-${item.goal.name}',
              title: item.title,
              description: item.description,
              svgAsset: item.svgAsset,
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
