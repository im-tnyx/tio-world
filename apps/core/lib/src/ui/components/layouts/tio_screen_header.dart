import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class TioScreenHeader extends StatelessWidget {
  const TioScreenHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final textTheme = TioTheme.typography(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.headlineSmall?.copyWith(color: colors.textPrimary)),
              if (subtitle != null) ...[
                SizedBox(height: TioTheme.spacing.small),
                Text(subtitle!, style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
