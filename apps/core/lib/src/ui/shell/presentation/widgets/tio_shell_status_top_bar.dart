import 'package:flutter/material.dart';

import '../../../../theme/tokens/effects/tio_elevation.dart';
import '../../../../theme/tokens/foundation/tio_spacing.dart';

class TioShellStatusTopBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TioShellStatusTopBar({
    required this.title,
    required this.statusLabel,
    required this.statusKey,
    required this.days,
    required this.scrollOpacity,
    super.key,
  }) : assert(days == null || days >= 0);

  final String title;
  final String statusLabel;
  final Key statusKey;
  final int? days;
  final double scrollOpacity;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final opacity = scrollOpacity.clamp(0, 1).toDouble();
    final colorScheme = Theme.of(context).colorScheme;
    final visibleDays = days != null && days! > 0 ? days : null;
    final semanticsLabel = visibleDays == null
        ? statusLabel
        : '$statusLabel, $visibleDays day${visibleDays == 1 ? '' : 's'}';

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: TioSpacing.lg,
      title: Text(title),
      shape: null,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: TioElevation.none,
      backgroundColor: colorScheme.surface.withValues(alpha: opacity),
      elevation: TioElevation.none,
      actions: [
        Tooltip(
          message: semanticsLabel,
          child: Semantics(
            key: statusKey,
            label: semanticsLabel,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.lg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_outlined),
                    if (visibleDays case final value?) ...[
                      const SizedBox(width: TioSpacing.sm),
                      Text(value.toString()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
