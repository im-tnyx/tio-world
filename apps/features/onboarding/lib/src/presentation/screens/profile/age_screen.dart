import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class AgeScreen extends StatelessWidget {
  const AgeScreen({
    required this.value,
    required this.onChanged,
    this.onContinue,
    this.isBusy = false,
    super.key,
    this.errorText,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onContinue;
  final bool isBusy;
  final String? errorText;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  DateTime get _selectedDate => value ?? DateTime.now();

  int get _calculatedAge {
    final now = DateTime.now();
    int age = now.year - _selectedDate.year;
    if (now.month < _selectedDate.month ||
        (now.month == _selectedDate.month && now.day < _selectedDate.day)) {
      age--;
    }
    return age;
  }

  String get _displayFormattedDate {
    final monthName = _monthNames[_selectedDate.month - 1];
    return '${_selectedDate.day} $monthName ${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return ProfileScreenScaffold(
      stepId: ProfileStepId.age,
      title: 'When were you born?',
      description: 'Age supports safer personalized recommendations.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Large Bold Date Display (Syncs with 44px across Height & Weight)
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _displayFormattedDate,
                key: const ValueKey('profile-date-of-birth-display'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dynamic Age Badge (Horizontally Centered)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(TioRadius.full),
              ),
              child: Text(
                '$_calculatedAge years old',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
