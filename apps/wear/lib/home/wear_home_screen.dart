import 'package:flutter/material.dart';

class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({super.key});

  static const _tiles = [
    _WearTileData(title: 'Workout Routine', icon: Icons.fitness_center),
    _WearTileData(title: 'Workout This Week', icon: Icons.calendar_month),
    _WearTileData(title: 'Add Food', icon: Icons.restaurant),
    _WearTileData(title: 'Add Water', icon: Icons.water_drop),
    _WearTileData(title: 'View Summary', icon: Icons.insights),
    _WearTileData(title: 'Nutrition', icon: Icons.eco),
    _WearTileData(title: 'Settings', icon: Icons.settings),
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
                  itemCount: _tiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final tile = _tiles[index];
                    return _WearTile(data: tile);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WearTile extends StatelessWidget {
  const _WearTile({required this.data});

  final _WearTileData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data.title} coming soon')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 26),
              const SizedBox(height: 8),
              Text(
                data.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WearTileData {
  const _WearTileData({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
