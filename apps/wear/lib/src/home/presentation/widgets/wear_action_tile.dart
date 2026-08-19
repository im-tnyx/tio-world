import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../model/wear_home_tile.dart';

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
      color: TioPalette.gray022,
      borderRadius: BorderRadius.circular(TioSize.dp22),
      child: InkWell(
        borderRadius: BorderRadius.circular(TioSize.dp22),
        onTap: () => onSelected(tile.action),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSize.dp14,
            vertical: TioSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: TioSize.dp36,
                height: TioSize.dp36,
                decoration: BoxDecoration(
                  color: TioPalette.gray036,
                  borderRadius: BorderRadius.circular(TioSize.dp18),
                ),
                child: Icon(tile.icon, size: TioSize.dp20),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: Text(
                  tile.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: TioFontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
