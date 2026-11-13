import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Resolves a stable accent from a Routine group label such as `A1` or `B2`.
Color supersetGroupColor(BuildContext context, String memberLabel) {
  final match = RegExp(r'^[A-Z]+').firstMatch(memberLabel);
  if (match == null) return Theme.of(context).colorScheme.primary;

  var groupIndex = 0;
  for (final codeUnit in match.group(0)!.codeUnits) {
    groupIndex = groupIndex * 26 + codeUnit - 64;
  }

  final colorScheme = Theme.of(context).colorScheme;
  final groupColors = [
    colorScheme.primary,
    colorScheme.secondary,
    colorScheme.tertiary,
  ];
  return groupColors[(groupIndex - 1) % groupColors.length];
}

/// Small decorative membership marker shared by picker rows and exercise cards.
class SupersetGroupMarker extends StatelessWidget {
  const SupersetGroupMarker({
    required this.groupLabel,
    required this.height,
    super.key,
  });

  final String groupLabel;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          key: ValueKey('superset-group-marker-$groupLabel'),
          width: TioSize.dp4,
          height: height,
          decoration: BoxDecoration(
            color: supersetGroupColor(context, groupLabel),
            borderRadius: BorderRadius.circular(TioRadius.full),
          ),
        ),
      );
}
