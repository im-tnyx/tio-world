import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Represents a selectable activity type with category grouping.
class WorkoutActivityType {
  const WorkoutActivityType({
    required this.name,
    required this.category,
    required this.icon,
  });

  final String name;
  final String category;
  final IconData icon;

  static const List<WorkoutActivityType> all = [
    // Strength & Resistance
    WorkoutActivityType(
      name: 'Weight Training',
      category: 'Strength & Resistance',
      icon: Icons.fitness_center_rounded,
    ),
    WorkoutActivityType(
      name: 'Powerlifting',
      category: 'Strength & Resistance',
      icon: Icons.sports_gymnastics_rounded,
    ),
    WorkoutActivityType(
      name: 'Bodyweight / Calisthenics',
      category: 'Strength & Resistance',
      icon: Icons.accessibility_new_rounded,
    ),

    // Cardio & Endurance
    WorkoutActivityType(
      name: 'Running',
      category: 'Cardio & Endurance',
      icon: Icons.directions_run_rounded,
    ),
    WorkoutActivityType(
      name: 'Cardio',
      category: 'Cardio & Endurance',
      icon: Icons.favorite_rounded,
    ),
    WorkoutActivityType(
      name: 'Cycling',
      category: 'Cardio & Endurance',
      icon: Icons.directions_bike_rounded,
    ),
    WorkoutActivityType(
      name: 'Walking',
      category: 'Cardio & Endurance',
      icon: Icons.directions_walk_rounded,
    ),

    // High Intensity & Hybrid
    WorkoutActivityType(
      name: 'HIIT',
      category: 'High Intensity & Hybrid',
      icon: Icons.flash_on_rounded,
    ),
    WorkoutActivityType(
      name: 'Hybrid',
      category: 'High Intensity & Hybrid',
      icon: Icons.sync_alt_rounded,
    ),
    WorkoutActivityType(
      name: 'Circuit Training',
      category: 'High Intensity & Hybrid',
      icon: Icons.loop_rounded,
    ),

    // Mobility & Recovery
    WorkoutActivityType(
      name: 'Yoga',
      category: 'Mobility & Recovery',
      icon: Icons.self_improvement_rounded,
    ),
    WorkoutActivityType(
      name: 'Pilates',
      category: 'Mobility & Recovery',
      icon: Icons.spa_rounded,
    ),
    WorkoutActivityType(
      name: 'Stretching',
      category: 'Mobility & Recovery',
      icon: Icons.nordic_walking_rounded,
    ),
  ];

  static List<String> get categories {
    final seen = <String>{};
    final result = <String>[];
    for (final item in all) {
      if (seen.add(item.category)) {
        result.add(item.category);
      }
    }
    return result;
  }

  static List<WorkoutActivityType> forCategory(String category) {
    return all.where((item) => item.category == category).toList();
  }
}

/// Shows the bottom sheet to select a grouped activity type.
Future<String?> showWorkoutActivityTypeSheet({
  required BuildContext context,
  required String currentActivityType,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => WorkoutActivityTypeSheet(
      currentActivityType: currentActivityType,
      onSelected: (selected) => Navigator.of(sheetContext).pop(selected),
    ),
  );
}

class WorkoutActivityTypeSheet extends StatelessWidget {
  const WorkoutActivityTypeSheet({
    required this.currentActivityType,
    required this.onSelected,
    super.key,
  });

  final String currentActivityType;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final categories = WorkoutActivityType.categories;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TioRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.lg,
          TioSpacing.md,
          TioSpacing.lg,
          TioSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: TioSize.dp40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: TioOpacity.opacity40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.md),

            // Sheet Title
            Text(
              'Activity Type',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: TioFontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TioSpacing.xs),
            Text(
              'Select the category that best describes your workout',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TioSpacing.md),

            // Grouped Options List
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final category in categories) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: TioSpacing.md,
                          bottom: TioSpacing.xs,
                          left: TioSpacing.xs,
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: TioFontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant.withValues(alpha: TioOpacity.opacity35),
                          borderRadius: BorderRadius.circular(TioRadius.lg),
                        ),
                        child: Column(
                          children: [
                            for (final item
                                in WorkoutActivityType.forCategory(category))
                              InkWell(
                                key: ValueKey(
                                  'activity-type-option-${item.name.toLowerCase().replaceAll(' ', '-')}',
                                ),
                                borderRadius:
                                    BorderRadius.circular(TioRadius.lg),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSelected(item.name);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: TioSpacing.md,
                                    vertical: TioSpacing.sm + 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: TioSize.dp34,
                                        height: TioSize.dp34,
                                        decoration: BoxDecoration(
                                          color: item.name == currentActivityType
                                              ? colors.primary
                                                  .withValues(alpha: TioOpacity.opacity15)
                                              : colors.surfaceVariant,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item.icon,
                                          size: TioSize.dp18,
                                          color: item.name == currentActivityType
                                              ? colors.primary
                                              : colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: TioSpacing.md),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight:
                                                item.name == currentActivityType
                                                    ? TioFontWeight.w600
                                                    : TioFontWeight.w400,
                                            color: item.name ==
                                                    currentActivityType
                                                ? colors.textPrimary
                                                : colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (item.name == currentActivityType)
                                        Icon(
                                          Icons.check_rounded,
                                          size: TioSize.dp20,
                                          color: colors.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
