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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  itemCount: tiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    return WearActionTile(
                      tile: tiles[index],
                      onSelected: (action) => _showComingSoon(context, tiles[index].title),
                    );
                  },
                ),
              ),
            ],
          ),
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
