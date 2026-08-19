import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen(
      {required this.selectedGender,
      required this.onSelected,
      super.key,
      this.errorText});

  final ProfileGender? selectedGender;
  final ValueChanged<ProfileGender> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.gender,
      title: 'How do you describe your gender?',
      description: 'This helps personalize relevant health guidance.',
      errorText: errorText,
      child: Column(
        children: [
          for (final gender in ProfileGender.values) ...[
            ProfileChoiceCard(
              id: 'gender-${gender.name}',
              title: _label(gender),
              selected: selectedGender == gender,
              onTap: () => onSelected(gender),
            ),
            const SizedBox(height: TioSpacing.md),
          ],
        ],
      ),
    );
  }
}

String _label(ProfileGender gender) => switch (gender) {
      ProfileGender.male => 'Male',
      ProfileGender.female => 'Female',
      ProfileGender.other => 'Other',
    };
