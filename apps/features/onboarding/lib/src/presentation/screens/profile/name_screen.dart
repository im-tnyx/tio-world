import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class NameScreen extends StatelessWidget {
  const NameScreen(
      {required this.value,
      required this.onChanged,
      super.key,
      this.errorText});

  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.name,
      title: 'What should Tio call you?',
      description: 'Use the name you want to see throughout your experience.',
      child: TioInput(
        key: const ValueKey('profile-name-input'),
        value: value,
        onChanged: onChanged,
        label: 'Name',
        hint: 'Your name',
        errorText: errorText,
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
