import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

/// Pure Onboarding App Mode Screen focused on simple, welcoming selection.
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
        const SizedBox(height: TioSpacing.xl),

        for (final mode in AppMode.values) ...[
          _ModeChoiceCard(
            mode: mode,
            selected: selectedMode == mode,
            onTap: enabled ? () => onModeSelected(mode) : null,
          ),
          const SizedBox(height: TioSpacing.md),
        ],
        const SizedBox(height: TioSpacing.sm),
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
                  duration: const Duration(milliseconds: TioDuration.ms200),
                  child: Text(
                    _nextSetupText(mode),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size13,
                      fontWeight: TioFontWeight.w400,
                    ),
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
      child: Material(
        color: selected
            ? colors.primary.withValues(
                alpha: TioCardTokens.selectedContainerAlpha,
              )
            : colors.surface,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: InkWell(
          key: ValueKey('app-mode-${mode.storageValue}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(TioCardTokens.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: TioDuration.ms200),
            padding: const EdgeInsets.all(TioSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outlineStrong.withValues(
                        alpha: TioOpacity.opacity35,
                      ),
                width: TioStroke.width1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: TioSize.dp44,
                  height: TioSize.dp44,
                  decoration: BoxDecoration(
                    color: (selected ? colors.primary : colors.textSecondary)
                        .withAlpha(
                          selected ? TioAlpha.alpha20 : TioAlpha.alpha12,
                        ),
                    borderRadius: BorderRadius.circular(TioRadius.md),
                  ),
                  child: Icon(
                    _icon(mode),
                    size: TioSize.dp22,
                    color: selected ? colors.primary : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: TioSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(mode),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size16,
                        ),
                      ),
                      const SizedBox(height: TioSize.dp3),
                      Text(
                        _description(mode),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: TioFontSize.size12,
                          fontWeight: TioFontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TioSpacing.md),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.outlineStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _nextSetupText(AppMode mode) {
  return switch (mode) {
    AppMode.workout =>
      'Next, Tio will focus setup on your workout routine and preferences.',
    AppMode.nutrition =>
      'Next, Tio will focus setup on nutrition targets and meal preferences.',
    AppMode.hybrid =>
      'Next, Tio will set up your workout preferences, then nutrition targets.',
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
    AppMode.workout =>
      'Focus entirely on workouts, routines, and training history.',
    AppMode.nutrition =>
      'Focus on daily calories, macros, and nutrition logging.',
    AppMode.hybrid =>
      'Complete experience with combined workout and nutrition tracking.',
  };
}

IconData _icon(AppMode mode) {
  return switch (mode) {
    AppMode.workout => Icons.fitness_center_rounded,
    AppMode.nutrition => Icons.restaurant_menu_rounded,
    AppMode.hybrid => Icons.bolt_rounded,
  };
}
