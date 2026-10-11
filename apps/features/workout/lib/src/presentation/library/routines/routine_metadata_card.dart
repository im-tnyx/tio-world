import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

/// Shared presentation for one Program-owned Routine metadata row.
///
/// Rendering here does not own or mutate Routine data; the owning Program
/// controller supplies the identity and optional action.
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
    return TioCard(
      padding: EdgeInsets.zero,
      child: TioSettingsNavigationRow(
        leading: const TioSettingsLeadingIcon(
          icon: Icons.fitness_center_outlined,
        ),
        title: routine.name,
        supportingText: supportingText,
        showChevron: false,
        onTap: onTap,
      ),
    );
  }
}
