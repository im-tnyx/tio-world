import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../device/wear_display_shape.dart';
import 'model/wear_home_tile.dart';
import 'widgets/wear_action_tile.dart';

class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({
    this.appMode,
    this.displayShape = WearDisplayShape.rectangular,
    super.key,
  });

  final AppMode? appMode;
  final WearDisplayShape displayShape;

  static const tiles = [
    WearHomeTile(
      title: 'Workout Routine',
      icon: Icons.fitness_center,
      action: WearHomeTileAction.workoutRoutine,
      requiredDestination: AppDestination.workout,
    ),
    WearHomeTile(
      title: 'Workout This Week',
      icon: Icons.calendar_month,
      action: WearHomeTileAction.workoutThisWeek,
      requiredDestination: AppDestination.workout,
    ),
    WearHomeTile(
      title: 'Add Food',
      icon: Icons.restaurant,
      action: WearHomeTileAction.addFood,
      requiredDestination: AppDestination.nutrition,
    ),
    WearHomeTile(
      title: 'Add Water',
      icon: Icons.water_drop,
      action: WearHomeTileAction.addWater,
      requiredDestination: AppDestination.nutrition,
    ),
    WearHomeTile(
      title: 'View Summary',
      icon: Icons.insights,
      action: WearHomeTileAction.viewSummary,
      requiredDestination: AppDestination.progress,
    ),
    WearHomeTile(
      title: 'Nutrition',
      icon: Icons.eco,
      action: WearHomeTileAction.nutrition,
      requiredDestination: AppDestination.nutrition,
    ),
    WearHomeTile(
      title: 'Settings',
      icon: Icons.settings,
      action: WearHomeTileAction.settings,
    ),
  ];

  static List<WearHomeTile> tilesForMode(AppMode? mode) {
    if (mode == null) return tiles;

    final destinations = mode.guidedDestinations.toSet();
    return tiles
        .where(
          (tile) =>
              tile.requiredDestination == null ||
              destinations.contains(tile.requiredDestination),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visibleTiles = tilesForMode(appMode);
    final size = MediaQuery.sizeOf(context);
    final horizontalInset = wearHorizontalSafeInset(
      shortestSide: size.shortestSide,
      shape: displayShape,
      baselineInset: TioSpacing.md,
    );

    return Scaffold(
      backgroundColor: TioPalette.black,
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: TioSize.dp10,
          ),
          itemCount: visibleTiles.length + 1,
          separatorBuilder: (context, index) =>
              const SizedBox(height: TioSpacing.sm),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: TioSpacing.xs,
                  bottom: TioSpacing.xxs,
                ),
                child: Text(
                  'Tio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: TioFontWeight.w800,
                      ),
                ),
              );
            }

            final tile = visibleTiles[index - 1];
            return WearActionTile(
              tile: tile,
              onSelected: (action) => _showComingSoon(context, tile.title),
            );
          },
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title coming soon')),
    );
  }
}
