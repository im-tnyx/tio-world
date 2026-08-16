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
    final colors = TioTheme.colors(context);
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
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
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
                    // Photo image
                    Image.asset(
                      imagePath,
                      package: 'tio_core',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          _fallbackIcon(area),
                          size: 32,
                          color: isSelected ? colors.primary : colors.textSecondary,
                        ),
                      ),
                    ),

                    // Primary tint overlay when selected
                    if (isSelected)
                      Container(
                        color: colors.primary.withValues(alpha: 0.20),
                      ),

                    // Border outline
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
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

                    // Check circle in top-right corner
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 13,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _label(area),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
      // Female has glutes.webp; male falls back to female glutes asset or legs
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
