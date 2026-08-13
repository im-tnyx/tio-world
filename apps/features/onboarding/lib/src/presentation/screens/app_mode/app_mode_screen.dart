import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

class AppModeScreen extends StatelessWidget {
  const AppModeScreen({
    required this.selectedMode,
    required this.onModeSelected,
    super.key,
    this.enabled = true,
  });

  final AppMode? selectedMode;
  final ValueChanged<AppMode> onModeSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'How will you use Tio?',
          subtitle: 'Choose the experience you want to start with. This '
              'shapes your setup steps and guided navigation, and you can '
              'change it later in Settings.',
        ),
        const SizedBox(height: TioSpacing.extraLarge),
        for (final mode in AppMode.values) ...[
          _ModeChoiceCard(
            mode: mode,
            selected: selectedMode == mode,
            onTap: enabled ? () => onModeSelected(mode) : null,
          ),
          const SizedBox(height: TioSpacing.medium),
        ],
        const SizedBox(height: TioSpacing.small),
        Stack(
          children: [
            for (final mode in AppMode.values)
              ExcludeSemantics(
                excluding: selectedMode != mode,
                child: AnimatedOpacity(
                  key: selectedMode == mode
                      ? const ValueKey('app-mode-next-setup')
                      : null,
                  opacity: selectedMode == mode ? 1 : 0,
                  duration: context.tioMotion.fast,
                  child: Text(
                    _nextSetupText(mode),
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

class _ModeChoiceCard extends StatelessWidget {
  const _ModeChoiceCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      button: true,
      selected: selected,
      label: '${_label(mode)} mode. ${_description(mode)}',
      child: InkWell(
        key: ValueKey('app-mode-${mode.storageValue}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radiusLarge),
        child: AnimatedContainer(
          duration: context.tioMotion.fast,
          padding: const EdgeInsets.all(TioSpacing.extraLarge),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.radiusLarge),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineStrong,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon(mode),
                color: selected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: TioSpacing.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(mode),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: TioSpacing.small),
                    Text(
                      _description(mode),
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

String _nextSetupText(AppMode mode) {
  return switch (mode) {
    AppMode.workout =>
      'Next, Tio will focus setup on training preferences and workout goals.',
    AppMode.nutrition =>
      'Next, Tio will focus setup on nutrition targets and meal preferences.',
    AppMode.hybrid =>
      'Next, Tio will include both workout and nutrition setup.',
  };
}

String _label(AppMode mode) {
  return switch (mode) {
    AppMode.workout => 'Workout',
    AppMode.nutrition => 'Nutrition',
    AppMode.hybrid => 'Hybrid',
  };
}

String _description(AppMode mode) {
  return switch (mode) {
    AppMode.workout => 'Training, routines, workout history, and progress.',
    AppMode.nutrition => 'Meals, water, nutrition targets, and progress.',
    AppMode.hybrid =>
      'Workout and nutrition together in one guided experience.',
  };
}

IconData _icon(AppMode mode) {
  return switch (mode) {
    AppMode.workout => Icons.fitness_center,
    AppMode.nutrition => Icons.restaurant,
    AppMode.hybrid => Icons.all_inclusive,
  };
}
