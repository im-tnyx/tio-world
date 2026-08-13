import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class AgeScreen extends StatelessWidget {
  const AgeScreen(
      {required this.value,
      required this.onChanged,
      super.key,
      this.errorText});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      stepId: ProfileStepId.age,
      title: 'When were you born?',
      description:
          'Age supports safer recommendations. It stays in this in-memory draft.',
      errorText: errorText,
      child: TioCard(
        variant: TioCardVariant.outlined,
        onTap: () => _pickDate(context),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined),
            const SizedBox(width: TioSpacing.medium),
            Expanded(
              child: Text(
                value == null ? 'Choose date of birth' : _formatDate(value!),
                key: const ValueKey('profile-date-of-birth-value'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(ProfileStepValidator.oldestBirthYear);
    final lastDate = DateTime(now.year, now.month, now.day);
    var initialDate = value ?? DateTime(2003, 4, 15);
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selected != null) onChanged(selected);
  }
}

String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
