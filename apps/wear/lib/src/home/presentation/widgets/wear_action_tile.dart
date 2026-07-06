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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(tile.icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tile.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
