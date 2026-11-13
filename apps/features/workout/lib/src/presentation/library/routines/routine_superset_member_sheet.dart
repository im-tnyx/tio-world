import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

final class RoutineSupersetMemberCandidate {
  const RoutineSupersetMemberCandidate({
    required this.entryId,
    required this.title,
  });

  final String entryId;
  final String title;
}

Future<String?> showRoutineSupersetMemberSheet(
  BuildContext context, {
  required List<RoutineSupersetMemberCandidate> candidates,
}) =>
    showTioEditorSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (_) => RoutineSupersetMemberSheet(candidates: candidates),
    );

class RoutineSupersetMemberSheet extends StatelessWidget {
  const RoutineSupersetMemberSheet({
    required this.candidates,
    super.key,
  });

  final List<RoutineSupersetMemberCandidate> candidates;

  @override
  Widget build(BuildContext context) => TioEditorSheet(
        key: const ValueKey('routine-superset-member-sheet'),
        title: 'Select Superset Exercise',
        content: candidates.isEmpty
            ? const Padding(
                key: ValueKey('routine-superset-empty'),
                padding: EdgeInsets.all(TioSpacing.lg),
                child: Text(
                  'There are no eligible exercises. Add another exercise first.',
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final candidate in candidates)
                    ListTile(
                      key: ValueKey(
                        'routine-superset-candidate-${candidate.entryId}',
                      ),
                      title: Text(candidate.title),
                      onTap: () => Navigator.of(context)
                          .pop<String>(candidate.entryId),
                    ),
                ],
              ),
      );
}
