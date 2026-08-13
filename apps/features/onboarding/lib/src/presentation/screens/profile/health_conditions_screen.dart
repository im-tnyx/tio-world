import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class HealthConditionsScreen extends StatelessWidget {
  const HealthConditionsScreen({
    required this.selectedConditions,
    required this.otherText,
    required this.onToggled,
    required this.onOtherTextChanged,
    super.key,
    this.errorText,
  });

  final Set<ProfileHealthCondition> selectedConditions;
  final String otherText;
  final ValueChanged<ProfileHealthCondition> onToggled;
  final ValueChanged<String> onOtherTextChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final showsOther =
        selectedConditions.contains(ProfileHealthCondition.other);

    return ProfileScreenScaffold(
      stepId: ProfileStepId.healthConditions,
      title: 'Any health conditions to consider?',
      description:
          'This step is optional. Select all that apply, or choose None.',
      child: Column(
        children: [
          for (final condition in ProfileHealthCondition.values) ...[
            ProfileChoiceCard(
              id: 'health-${condition.name}',
              title: _label(condition),
              selected: selectedConditions.contains(condition),
              onTap: () => onToggled(condition),
            ),
            const SizedBox(height: TioSpacing.medium),
          ],
          if (showsOther)
            TioInput(
              key: const ValueKey('profile-other-health-input'),
              value: otherText,
              onChanged: onOtherTextChanged,
              label: 'Other condition',
              hint: 'Add a short description',
              errorText: errorText,
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
        ],
      ),
    );
  }
}

String _label(ProfileHealthCondition condition) => switch (condition) {
      ProfileHealthCondition.none => 'None',
      ProfileHealthCondition.diabetes => 'Diabetes',
      ProfileHealthCondition.hypertension => 'Hypertension',
      ProfileHealthCondition.lowBloodPressure => 'Low blood pressure',
      ProfileHealthCondition.other => 'Other',
    };
