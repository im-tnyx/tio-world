import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen(
      {required this.selectedGoals,
      required this.onToggled,
      super.key,
      this.errorText});

  final Set<ProfileGoal> selectedGoals;
  final ValueChanged<ProfileGoal> onToggled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.goal,
      title: 'What is your main goal?',
      description:
          'Choose one primary goal. You can also add supporting goals.',
      errorText: errorText,
      child: Column(
        children: [
          for (final goal in ProfileGoal.values) ...[
            ProfileChoiceCard(
              id: 'goal-${goal.name}',
              title: _label(goal),
              description: ProfileStepValidator.primaryGoals.contains(goal)
                  ? 'Primary goal'
                  : 'Supporting goal',
              selected: selectedGoals.contains(goal),
              onTap: () => onToggled(goal),
            ),
            const SizedBox(height: TioSpacing.medium),
          ],
        ],
      ),
    );
  }
}

String _label(ProfileGoal goal) => switch (goal) {
      ProfileGoal.buildMuscle => 'Build muscle',
      ProfileGoal.loseWeight => 'Lose weight',
      ProfileGoal.keepFit => 'Keep fit',
      ProfileGoal.boostStrength => 'Boost strength',
      ProfileGoal.manageStress => 'Manage stress',
    };
