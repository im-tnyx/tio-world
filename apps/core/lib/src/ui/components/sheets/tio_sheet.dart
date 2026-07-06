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
    final colors = TioTheme.colors(context);
    final textTheme = TioTheme.typography(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(TioTheme.radius.extraLarge)),
      child: Padding(
        padding: EdgeInsets.all(TioTheme.spacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: textTheme.titleLarge?.copyWith(color: colors.textPrimary)),
              SizedBox(height: TioTheme.spacing.medium),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
