import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen(
      {required this.selectedActivity,
      required this.onSelected,
      super.key,
      this.errorText});

  final ProfileActivityLevel? selectedActivity;
  final ValueChanged<ProfileActivityLevel> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.activity,
      title: 'How active is a typical day?',
      description: 'Choose the option that best matches your usual routine.',
      errorText: errorText,
      child: Column(
        children: [
          for (final activity in ProfileActivityLevel.values) ...[
            ProfileChoiceCard(
              id: 'activity-${activity.name}',
              title: _label(activity),
              description: _description(activity),
              selected: selectedActivity == activity,
              onTap: () => onSelected(activity),
            ),
            const SizedBox(height: TioSpacing.medium),
          ],
        ],
      ),
    );
  }
}

String _label(ProfileActivityLevel activity) => switch (activity) {
      ProfileActivityLevel.sedentary => 'Sedentary',
      ProfileActivityLevel.light => 'Light',
      ProfileActivityLevel.active => 'Active',
      ProfileActivityLevel.veryActive => 'Very active',
      ProfileActivityLevel.dynamic => 'Dynamic',
    };

String _description(ProfileActivityLevel activity) => switch (activity) {
      ProfileActivityLevel.sedentary => 'Mostly seated with little movement.',
      ProfileActivityLevel.light => 'Some walking and light daily movement.',
      ProfileActivityLevel.active => 'Regular walking or planned activity.',
      ProfileActivityLevel.veryActive =>
        'Hard exercise or active work most days.',
      ProfileActivityLevel.dynamic =>
        'High and varied movement throughout the day.',
    };
