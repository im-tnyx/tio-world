import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import 'model/wear_home_tile.dart';
import 'widgets/wear_action_tile.dart';

class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({super.key});

  static const tiles = [
    WearHomeTile(
      title: 'Workout Routine',
      icon: Icons.fitness_center,
      action: WearHomeTileAction.workoutRoutine,
    ),
    WearHomeTile(
      title: 'Workout This Week',
      icon: Icons.calendar_month,
      action: WearHomeTileAction.workoutThisWeek,
    ),
    WearHomeTile(
      title: 'Add Food',
      icon: Icons.restaurant,
      action: WearHomeTileAction.addFood,
    ),
    WearHomeTile(
      title: 'Add Water',
      icon: Icons.water_drop,
      action: WearHomeTileAction.addWater,
    ),
    WearHomeTile(
      title: 'View Summary',
      icon: Icons.insights,
      action: WearHomeTileAction.viewSummary,
    ),
    WearHomeTile(
      title: 'Nutrition',
      icon: Icons.eco,
      action: WearHomeTileAction.nutrition,
    ),
    WearHomeTile(
      title: 'Settings',
      icon: Icons.settings,
      action: WearHomeTileAction.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TioPalette.black,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.md,
            vertical: TioSize.dp10,
          ),
          itemCount: tiles.length + 1,
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

            final tile = tiles[index - 1];
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
