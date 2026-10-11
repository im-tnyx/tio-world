import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

/// One canonical Routine rendered as a standalone Core card.
///
/// A Library instance is read-only; Program Detail supplies the real rename
/// action and its supporting label. No second Routine source of truth exists.
class RoutineMetadataCard extends StatelessWidget {
  const RoutineMetadataCard({
    required this.routine,
    super.key,
    this.supportingText,
    this.onTap,
  });

  final Routine routine;
  final String? supportingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.fitness_center_outlined, color: colors.textSecondary),
          const SizedBox(width: TioSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioFontSize.size15,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
                if (supportingText != null)
                  Text(
                    supportingText!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size12,
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            PopupMenuButton<String>(
              key: ValueKey('routine-menu-${routine.id.value}'),
              tooltip: 'Routine options',
              onSelected: (value) {
                if (value == 'edit') onTap?.call();
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
              ],
              icon: Icon(
                Icons.more_vert_rounded,
                color: colors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
