import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/domain.dart';
import '../../widgets/goal_choice_card.dart';

class GoalIntentScreen extends StatelessWidget {
  const GoalIntentScreen({
    required this.mode,
    required this.selection,
    required this.onGoalTapped,
    this.errorText,
    this.policy = const GoalIntentSelectionPolicy(),
    super.key,
  });

  final AppMode mode;
  final GoalIntentSelection selection;
  final ValueChanged<GoalIntent> onGoalTapped;
  final String? errorText;
  final GoalIntentSelectionPolicy policy;

  @override
  Widget build(BuildContext context) {
    final goals = policy.optionsFor(mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TioScreenHeader(
          title: 'What do you want to achieve?',
          subtitle: mode == AppMode.nutrition
              ? 'Choose your main goal.'
              : 'Choose your main goal and one supporting goal.',
        ),
        const SizedBox(height: TioSpacing.lg),
        for (final goal in goals) ...[
          GoalChoiceCard(
            id: 'goal-intent-${goal.name}',
            title: _title(goal),
            description: _description(mode, goal),
            svgAsset: _svgAsset(goal),
            isSelected: selection.contains(goal),
            onTap: () {
              HapticFeedback.selectionClick();
              onGoalTapped(goal);
            },
          ),
          const SizedBox(height: TioSpacing.md),
        ],
        if (errorText case final message?)
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: const ValueKey('goal-intent-error'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}

String _title(GoalIntent goal) => switch (goal) {
      GoalIntent.loseWeight => 'Lose weight',
      GoalIntent.gainWeight => 'Gain weight',
      GoalIntent.maintainWeight => 'Maintain weight',
      GoalIntent.recomposition => 'Recomposition',
      GoalIntent.buildMuscle => 'Build muscle',
      GoalIntent.getStronger => 'Get stronger',
      GoalIntent.improveEndurance => 'Improve endurance',
      GoalIntent.stayFit => 'Stay fit',
    };

String _description(AppMode mode, GoalIntent goal) => switch (goal) {
      GoalIntent.loseWeight => mode == AppMode.workout
          ? 'Burn fat through consistent training'
          : 'Burn fat and reach a healthier weight',
      GoalIntent.gainWeight => 'Gain weight in a healthy way',
      GoalIntent.maintainWeight => 'Keep your weight steady',
      GoalIntent.recomposition => 'Lose fat and build lean mass',
      GoalIntent.buildMuscle => 'Gain muscle size and strength',
      GoalIntent.getStronger => 'Improve strength and performance',
      GoalIntent.improveEndurance => 'Build stamina and conditioning',
      GoalIntent.stayFit => 'Maintain fitness and overall health',
    };

String _svgAsset(GoalIntent goal) => switch (goal) {
      GoalIntent.loseWeight => 'assets/svg_icon/ic_fire.svg',
      GoalIntent.gainWeight => 'assets/svg_icon/ic_abs.svg',
      GoalIntent.maintainWeight => 'assets/svg_icon/ic_keep_fit.svg',
      GoalIntent.recomposition => 'assets/svg_icon/ic_muscle.svg',
      GoalIntent.buildMuscle => 'assets/svg_icon/ic_abs.svg',
      GoalIntent.getStronger => 'assets/svg_icon/ic_muscle.svg',
      GoalIntent.improveEndurance => 'assets/svg_icon/ic_heart.svg',
      GoalIntent.stayFit => 'assets/svg_icon/ic_keep_fit.svg',
    };
