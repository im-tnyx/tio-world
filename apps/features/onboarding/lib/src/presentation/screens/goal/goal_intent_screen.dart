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
              : 'Choose your focus. Add up to two training goals.',
        ),
        const SizedBox(height: TioSpacing.lg),
        for (final goal in goals) ...[
          GoalChoiceCard(
            id: 'goal-intent-${goal.name}',
            title: _title(mode, goal),
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

String _title(AppMode mode, GoalIntent goal) => switch (goal) {
      GoalIntent.loseWeight =>
        mode == AppMode.nutrition ? 'Lose weight' : 'Fat Loss',
      GoalIntent.gainWeight => 'Gain weight',
      GoalIntent.maintainWeight => 'Maintain weight',
      GoalIntent.recomposition => 'Recomposition',
      GoalIntent.buildMuscle => 'Build muscle',
      GoalIntent.getStronger => 'Boost strength',
      GoalIntent.improveEndurance => 'Improve endurance',
      GoalIntent.stayFit => 'Keep fit',
    };

String _description(AppMode mode, GoalIntent goal) => switch (goal) {
      GoalIntent.loseWeight => mode == AppMode.nutrition
          ? 'Reduce body weight and body fat'
          : 'Reduce body fat while supporting lean mass',
      GoalIntent.gainWeight => 'Gain body weight gradually and healthily',
      GoalIntent.maintainWeight => 'Keep your current weight stable',
      GoalIntent.recomposition => 'Lose fat and build lean mass',
      GoalIntent.buildMuscle => 'Increase muscle size and lean mass',
      GoalIntent.getStronger => 'Improve strength and lifting performance',
      GoalIntent.improveEndurance => 'Improve cardio, stamina and conditioning',
      GoalIntent.stayFit => 'Maintain overall fitness, energy and health',
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
