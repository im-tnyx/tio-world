import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

class WorkoutIntroScreen extends StatelessWidget {
  const WorkoutIntroScreen({
    required this.selectedChoice,
    required this.onChoiceSelected,
    super.key,
    this.enabled = true,
  });

  final WorkoutIntroChoice? selectedChoice;
  final ValueChanged<WorkoutIntroChoice> onChoiceSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'Create your workout plan?',
          subtitle: 'Answer a few quick questions to personalize your workouts '
              'now, or skip this for later and continue with nutrition setup.',
        ),
        const SizedBox(height: TioSpacing.xl),
        for (final choice in WorkoutIntroChoice.values) ...[
          _WorkoutIntroChoiceCard(
            choice: choice,
            selected: selectedChoice == choice,
            onTap: enabled ? () => onChoiceSelected(choice) : null,
          ),
          const SizedBox(height: TioSpacing.md),
        ],
        const SizedBox(height: TioSpacing.sm),
        Stack(
          children: [
            for (final choice in WorkoutIntroChoice.values)
              ExcludeSemantics(
                excluding: selectedChoice != choice,
                child: AnimatedOpacity(
                  key: selectedChoice == choice
                      ? const ValueKey('workout-intro-next-setup')
                      : null,
                  opacity: selectedChoice == choice ? 1 : 0,
                  duration: context.tioMotion.fast,
                  child: Text(
                    _nextSetupText(choice),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WorkoutIntroChoiceCard extends StatelessWidget {
  const _WorkoutIntroChoiceCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final WorkoutIntroChoice choice;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      button: true,
      selected: selected,
      label: '${_label(choice)}. ${_description(choice)}',
      child: InkWell(
        key: ValueKey('workout-intro-${choice.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TioRadius.lg),
        child: AnimatedContainer(
          duration: context.tioMotion.fast,
          padding: const EdgeInsets.all(TioSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(TioRadius.lg),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineStrong,
              width: TioStroke.width2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon(choice),
                color: selected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: TioSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(choice),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      _description(choice),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.outlineStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _label(WorkoutIntroChoice choice) {
  return switch (choice) {
    WorkoutIntroChoice.setupNow => 'Yes, set it up now',
    WorkoutIntroChoice.later => 'I\'ll do this later',
  };
}

String _description(WorkoutIntroChoice choice) {
  return switch (choice) {
    WorkoutIntroChoice.setupNow =>
      'We will ask about your training style, schedule, equipment, and focus.',
    WorkoutIntroChoice.later =>
      'Tio will skip workout preferences for now and continue with nutrition.',
  };
}

String _nextSetupText(WorkoutIntroChoice choice) {
  return switch (choice) {
    WorkoutIntroChoice.setupNow =>
      'Next, Tio will collect your workout preferences before nutrition setup.',
    WorkoutIntroChoice.later =>
      'Next, Tio will continue directly to nutrition setup.',
  };
}

IconData _icon(WorkoutIntroChoice choice) {
  return switch (choice) {
    WorkoutIntroChoice.setupNow => Icons.fitness_center,
    WorkoutIntroChoice.later => Icons.schedule,
  };
}
