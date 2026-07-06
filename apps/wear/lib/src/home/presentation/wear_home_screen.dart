import 'package:flutter/material.dart';

import '../domain/wear_home_tile.dart';
import 'widgets/wear_action_tile.dart';

class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({super.key});

  static const tiles = [
    WearHomeTile(title: 'Workout Routine', icon: Icons.fitness_center, action: WearHomeTileAction.workoutRoutine),
    WearHomeTile(title: 'Workout This Week', icon: Icons.calendar_month, action: WearHomeTileAction.workoutThisWeek),
    WearHomeTile(title: 'Add Food', icon: Icons.restaurant, action: WearHomeTileAction.addFood),
    WearHomeTile(title: 'Add Water', icon: Icons.water_drop, action: WearHomeTileAction.addWater),
    WearHomeTile(title: 'View Summary', icon: Icons.insights, action: WearHomeTileAction.viewSummary),
    WearHomeTile(title: 'Nutrition', icon: Icons.eco, action: WearHomeTileAction.nutrition),
    WearHomeTile(title: 'Settings', icon: Icons.settings, action: WearHomeTileAction.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: tiles.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  'Tio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
