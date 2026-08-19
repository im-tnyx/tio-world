import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class ExperienceLevelScreen extends StatelessWidget {
  const ExperienceLevelScreen({
    required this.selectedLevel,
    required this.flowPlan,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final WorkoutExperienceLevel? selectedLevel;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutExperienceLevel> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.experienceLevel,
      flowPlan: flowPlan,
      title: "What's your experience with strength training?",
      description:
          'This helps Tio tune exercise complexity, pacing, and coaching detail.',
      errorText: errorText,
      child: Column(
        children: [
          for (final level in WorkoutExperienceLevel.values) ...[
            _ExperienceCard(
              level: level,
              isSelected: selectedLevel == level,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(level);
              },
              colors: colors,
              textTheme: textTheme,
            ),
            if (level != WorkoutExperienceLevel.values.last)
              const SizedBox(height: TioSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  final WorkoutExperienceLevel level;
  final bool isSelected;
  final VoidCallback onTap;
  final TioColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${_title(level)}. ${_years(level)}. ${_description(level)}',
      child: Material(
        color: isSelected
            ? colors.primary.withValues(
                alpha: TioCardTokens.selectedContainerAlpha,
              )
            : colors.surface,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: InkWell(
          key: ValueKey('workout-choice-experience-${level.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(TioCardTokens.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: TioDuration.ms180),
            padding: const EdgeInsets.all(TioSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : colors.outlineStrong.withValues(
                        alpha: TioCardTokens.unselectedOutlineAlpha,
                      ),
                width: isSelected
                    ? TioCardTokens.selectedBorderWidth
                    : TioCardTokens.unselectedBorderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LevelSignalIcon(
                      level: _levelNumber(level),
                      isSelected: isSelected,
                    ),
                    const SizedBox(width: TioSize.dp10),
                    Expanded(
                      child: Text(
                        _title(level),
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: TioFontSize.size16,
                          fontWeight: isSelected
                              ? TioFontWeight.w700
                              : TioFontWeight.w600,
                          color: isSelected
                              ? colors.primary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TioSize.dp10,
                        vertical: TioSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary
                            : colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(TioRadius.full),
                      ),
                      child: Text(
                        _years(level),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: TioFontSize.size11,
                          fontWeight: TioFontWeight.w700,
                          letterSpacing: TioLetterSpacing.positive06,
                          color: isSelected
                              ? colors.onPrimary
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSize.dp6),
                Text(
                  _description(level),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: TioFontSize.size13,
                    height: TioLineHeight.height135,
                    color: isSelected
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LevelSignalIcon extends StatelessWidget {
  const LevelSignalIcon({
    required this.level,
    required this.isSelected,
    super.key,
  });

  final int level;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final activeColor = isSelected ? colors.primary : colors.textPrimary;
    final inactiveColor = colors.outlineStrong.withValues(
      alpha: TioOpacity.opacity35,
    );

    return SizedBox(
      height: TioSize.dp22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Signal-bar dimensions are a one-off icon composition, not a
          // reusable design-token family.
          for (var i = 1; i <= 4; i++) ...[
            Container(
              width: 3.5,
              height: 6.0 + (i * 4.0),
              decoration: BoxDecoration(
                color: i <= level ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            if (i < 4) const SizedBox(width: 2.5),
          ],
        ],
      ),
    );
  }
}

int _levelNumber(WorkoutExperienceLevel level) => switch (level) {
      WorkoutExperienceLevel.fresh => 1,
      WorkoutExperienceLevel.beginner => 2,
      WorkoutExperienceLevel.intermediate => 3,
      WorkoutExperienceLevel.advanced => 4,
    };

String _title(WorkoutExperienceLevel level) => switch (level) {
      WorkoutExperienceLevel.fresh => 'Fresh Start',
      WorkoutExperienceLevel.beginner => 'Beginner',
      WorkoutExperienceLevel.intermediate => 'Intermediate',
      WorkoutExperienceLevel.advanced => 'Advanced',
    };

String _years(WorkoutExperienceLevel level) => switch (level) {
      WorkoutExperienceLevel.fresh => '0 YEARS',
      WorkoutExperienceLevel.beginner => '0-1 YEARS',
      WorkoutExperienceLevel.intermediate => '1-3 YEARS',
      WorkoutExperienceLevel.advanced => '3+ YEARS',
    };

String _description(WorkoutExperienceLevel level) => switch (level) {
      WorkoutExperienceLevel.fresh => 'Just getting started and need guidance.',
      WorkoutExperienceLevel.beginner => 'Still learning the basics.',
      WorkoutExperienceLevel.intermediate =>
        'Building strength and consistency.',
      WorkoutExperienceLevel.advanced =>
        'Refining technique and progressing.',
    };
