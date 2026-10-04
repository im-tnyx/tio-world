import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../exercises_state.dart';

/// One canonical Exercise row.
///
/// Catalog rows stay non-interactive until Exercise Detail lands. User-created
/// rows may provide [onTap] to enter their existing edit flow and carry a
/// presentation-only `Custom` badge; both remain canonical [Exercise] items.
class ExerciseListRow extends StatelessWidget {
  const ExerciseListRow({
    required this.item,
    super.key,
    this.onTap,
  });

  final ExerciseListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final thumbnailUrl = item.thumbnailUrl;
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.sm,
      ),
      child: Row(
        children: [
          if (thumbnailUrl != null)
            ExerciseThumbnail(
              key: ValueKey('exercise-thumbnail-${item.exercise.ref.value}'),
              url: thumbnailUrl,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                    fontSize: TioFontSize.size15,
                  ),
                ),
                if (item.metadata != null || item.isCustom) ...[
                  const SizedBox(height: TioSpacing.xxs),
                  Wrap(
                    spacing: TioSpacing.sm,
                    runSpacing: TioSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item.metadata case final metadata?)
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: TioFontSize.size13,
                          ),
                        ),
                      if (item.isCustom)
                        _CustomBadge(
                          key: ValueKey(
                            'exercise-custom-badge-${item.exercise.ref.value}',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: TioSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              size: TioSize.dp24,
              color: colors.textSecondary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return MergeSemantics(child: body);
    }

    return Semantics(
      button: true,
      onTap: onTap,
      child: Material(
        color: TioPalette.transparent,
        child: InkWell(
          onTap: onTap,
          child: MergeSemantics(child: body),
        ),
      ),
    );
  }
}

class _CustomBadge extends StatelessWidget {
  const _CustomBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(TioRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.sm,
          vertical: TioSpacing.xxs,
        ),
        child: Text(
          'Custom',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioFontSize.size13,
            fontWeight: TioFontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Exercise image plus its gap to the text, removed entirely if the image
/// cannot load so the row falls back to text-only.
class ExerciseThumbnail extends StatefulWidget {
  const ExerciseThumbnail({required this.url, super.key});

  static const size = TioSize.dp56;

  final Uri url;

  @override
  State<ExerciseThumbnail> createState() => _ExerciseThumbnailState();
}

class _ExerciseThumbnailState extends State<ExerciseThumbnail> {
  bool _failed = false;

  @override
  void didUpdateWidget(ExerciseThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _failed = false;
  }

  void _markFailed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: TioSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TioRadius.sm),
        child: ColoredBox(
          color: context.tioColors.surfaceVariant,
          child: Image.network(
            widget.url.toString(),
            width: ExerciseThumbnail.size,
            height: ExerciseThumbnail.size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) {
              _markFailed();
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
