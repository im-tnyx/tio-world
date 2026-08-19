import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class FocusAreasScreen extends StatelessWidget {
  const FocusAreasScreen({
    required this.selectedAreas,
    required this.flowPlan,
    required this.onToggled,
    super.key,
    this.gender,
    this.errorText,
  });

  final Set<WorkoutFocusArea> selectedAreas;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutFocusArea> onToggled;
  final ProfileGender? gender;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.focusAreas,
      flowPlan: flowPlan,
      title: 'What specific areas do you want to focus on?',
      description:
          'Pick one or more priorities. Choosing Full body keeps every major area selected together.',
      errorText: errorText,
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: WorkoutFocusArea.values.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: TioSize.dp10,
          mainAxisSpacing: TioSpacing.md,
          // Grid composition ratio stays local to this screen.
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final area = WorkoutFocusArea.values[index];
          final isSelected = selectedAreas.contains(area);

          return _FocusAreaCard(
            area: area,
            isSelected: isSelected,
            gender: gender,
            onTap: () {
              HapticFeedback.selectionClick();
              onToggled(area);
            },
            colors: colors,
            textTheme: textTheme,
          );
        },
      ),
    );
  }
}

class _FocusAreaCard extends StatelessWidget {
  const _FocusAreaCard({
    required this.area,
    required this.isSelected,
    required this.gender,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  final WorkoutFocusArea area;
  final bool isSelected;
  final ProfileGender? gender;
  final VoidCallback onTap;
  final TioColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath(area, gender);

    return Semantics(
      button: true,
      selected: isSelected,
      label: _label(area),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('workout-choice-focus-${area.name}'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(TioCardTokens.radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imagePath,
                      package: 'tio_core',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          _fallbackIcon(area),
                          size: TioSize.dp32,
                          color: isSelected
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        color: colors.primary.withValues(
                          alpha: TioOpacity.opacity20,
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: TioDuration.ms180),
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
                    ),
                    if (isSelected)
                      Positioned(
                        top: TioSize.dp6,
                        right: TioSize.dp6,
                        child: Container(
                          width: TioSize.dp20,
                          height: TioSize.dp20,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: TioFontSize.size13,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: TioSize.dp6),
          Text(
            _label(area),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontSize: TioFontSize.size13,
              fontWeight: isSelected
                  ? TioFontWeight.w600
                  : TioFontWeight.w500,
              color: isSelected ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

String _imagePath(WorkoutFocusArea area, ProfileGender? gender) {
  final isFemale = gender == ProfileGender.female;
  final subfolder = isFemale ? 'female' : 'male';

  return switch (area) {
    WorkoutFocusArea.fullBody =>
      'assets/image/specific_focus_area/$subfolder/full_body.webp',
    WorkoutFocusArea.shoulders =>
      'assets/image/specific_focus_area/$subfolder/shoulders.webp',
    WorkoutFocusArea.arms =>
      'assets/image/specific_focus_area/$subfolder/arms.webp',
    WorkoutFocusArea.back =>
      'assets/image/specific_focus_area/$subfolder/back.webp',
    WorkoutFocusArea.chest =>
      'assets/image/specific_focus_area/$subfolder/chest.webp',
    WorkoutFocusArea.abs =>
      'assets/image/specific_focus_area/$subfolder/abs.webp',
    WorkoutFocusArea.glutes =>
      'assets/image/specific_focus_area/female/glutes.webp',
    WorkoutFocusArea.legs =>
      'assets/image/specific_focus_area/$subfolder/legs.webp',
    WorkoutFocusArea.cardio =>
      'assets/image/specific_focus_area/$subfolder/cardio.png',
  };
}

String _label(WorkoutFocusArea area) => switch (area) {
      WorkoutFocusArea.fullBody => 'Full Body',
      WorkoutFocusArea.shoulders => 'Shoulders',
      WorkoutFocusArea.arms => 'Arms',
      WorkoutFocusArea.back => 'Back',
      WorkoutFocusArea.chest => 'Chest',
      WorkoutFocusArea.abs => 'Abs',
      WorkoutFocusArea.glutes => 'Glutes',
      WorkoutFocusArea.legs => 'Legs',
      WorkoutFocusArea.cardio => 'Cardio',
    };

IconData _fallbackIcon(WorkoutFocusArea area) => switch (area) {
      WorkoutFocusArea.fullBody => Icons.accessibility_new_outlined,
      WorkoutFocusArea.shoulders => Icons.pan_tool_outlined,
      WorkoutFocusArea.arms => Icons.sports_mma_outlined,
      WorkoutFocusArea.back => Icons.keyboard_capslock_outlined,
      WorkoutFocusArea.chest => Icons.favorite_border,
      WorkoutFocusArea.abs => Icons.crop_portrait_outlined,
      WorkoutFocusArea.glutes => Icons.hiking_outlined,
      WorkoutFocusArea.legs => Icons.directions_run_outlined,
      WorkoutFocusArea.cardio => Icons.monitor_heart_outlined,
    };
