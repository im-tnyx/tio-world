import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class WelcomeFeatureTile extends StatelessWidget {
  const WelcomeFeatureTile({
    required this.title,
    required this.description,
    required this.iconWidget,
    super.key,
  });

  final String title;
  final String description;
  final Widget iconWidget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: TioSize.dp32,
          height: TioSize.dp32,
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: TioSize.dp10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: TioFontSize.size10_5,
            fontWeight: TioFontWeight.w800,
            letterSpacing: TioLetterSpacing.positive08,
          ).copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: TioSize.dp6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: TioFontSize.size9_5,
            fontWeight: TioFontWeight.w400,
            height: TioLineHeight.height130,
          ).copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
