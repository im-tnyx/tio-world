import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../exercises_state.dart';

/// One non-interactive Exercise row: thumbnail, name, metadata.
///
/// Rows have no tap, icon, chevron or action until Exercise Detail exists.
/// Without a usable image the row is text-only, never a broken placeholder.
class ExerciseListRow extends StatelessWidget {
  const ExerciseListRow({required this.item, super.key});

  final ExerciseListItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final thumbnailUrl = item.thumbnailUrl;

    return MergeSemantics(
      child: Padding(
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
                  if (item.metadata case final metadata?) ...[
                    const SizedBox(height: TioSpacing.xxs),
                    Text(
                      metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: TioFontSize.size13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
