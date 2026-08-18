import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class TioSheet extends StatelessWidget {
  const TioSheet({
    required this.child,
    super.key,
    this.title,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TioSheetTokens.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TioSheetTokens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: TioSheetTokens.titleGap),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
