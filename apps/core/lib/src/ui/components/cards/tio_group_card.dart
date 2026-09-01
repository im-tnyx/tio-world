import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Neutral, non-selectable surface that groups related settings content.
///
/// This deliberately has no padding or selection state. Callers compose their
/// rows and separators as children so their existing geometry remains intact.
class TioGroupCard extends StatelessWidget {
  const TioGroupCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tioColors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
