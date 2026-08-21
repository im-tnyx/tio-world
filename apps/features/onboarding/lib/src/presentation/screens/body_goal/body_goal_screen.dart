import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import '../../widgets/goal_choice_card.dart';

class BodyGoalScreen extends StatelessWidget {
  const BodyGoalScreen({
    required this.selectedGoal,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final BodyGoal? selectedGoal;
  final ValueChanged<BodyGoal> onSelected;
  final String? errorText;

  static const _goals = [
    _BodyGoalItem(
      goal: BodyGoal.loseWeight,
      title: 'Lose weight',
      description: 'Reduce body weight with a sustainable plan',
      svgAsset: 'assets/svg_icon/ic_fire.svg',
    ),
    _BodyGoalItem(
      goal: BodyGoal.gainWeight,
      title: 'Gain weight',
      description: 'Increase body weight with steady, healthy progress',
      svgAsset: 'assets/svg_icon/ic_abs.svg',
    ),
    _BodyGoalItem(
      goal: BodyGoal.maintainWeight,
      title: 'Maintain weight',
      description: 'Keep your weight stable while supporting overall fitness',
      svgAsset: 'assets/svg_icon/ic_keep_fit.svg',
    ),
    _BodyGoalItem(
      goal: BodyGoal.bodyRecomposition,
      title: 'Body recomposition',
      description: 'Improve body composition while focusing on strength and fitness',
      svgAsset: 'assets/svg_icon/ic_muscle.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: "What's your body goal?",
          subtitle: 'Choose the goal that best matches what you want to achieve.',
        ),
        const SizedBox(height: TioSpacing.lg),
        for (final item in _goals) ...[
          GoalChoiceCard(
            id: 'body-goal-${item.goal.name}',
            title: item.title,
            description: item.description,
            svgAsset: item.svgAsset,
            isSelected: selectedGoal == item.goal,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(item.goal);
            },
          ),
          const SizedBox(height: TioSpacing.md),
        ],
        if (errorText case final message?) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: const ValueKey('body-goal-error'),
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

class _BodyGoalItem {
  const _BodyGoalItem({
    required this.goal,
    required this.title,
    required this.description,
    required this.svgAsset,
  });

  final BodyGoal goal;
  final String title;
  final String description;
  final String svgAsset;
}
