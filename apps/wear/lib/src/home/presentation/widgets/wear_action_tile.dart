import 'package:flutter/material.dart';

import '../../domain/wear_home_tile.dart';

class WearActionTile extends StatelessWidget {
  const WearActionTile({
    required this.tile,
    required this.onSelected,
    super.key,
  });

  final WearHomeTile tile;
  final ValueChanged<WearHomeTileAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onSelected(tile.action),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tile.icon, size: 26),
              const SizedBox(height: 8),
              Text(
                tile.title,
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
