import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../widgets/superset_group_marker.dart';

final class RoutineSupersetMemberCandidate {
  const RoutineSupersetMemberCandidate({
    required this.entryId,
    required this.title,
    this.supersetLabel,
  });

  final String entryId;
  final String title;
  final String? supersetLabel;

  bool get isAlreadyGrouped => supersetLabel != null;
}

Future<String?> showRoutineSupersetMemberSheet(
  BuildContext context, {
  required String initiatingExerciseTitle,
  required List<RoutineSupersetMemberCandidate> candidates,
}) =>
    showTioEditorSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (_) => RoutineSupersetMemberSheet(
        initiatingExerciseTitle: initiatingExerciseTitle,
        candidates: candidates,
      ),
    );

class RoutineSupersetMemberSheet extends StatelessWidget {
  const RoutineSupersetMemberSheet({
    required this.initiatingExerciseTitle,
    required this.candidates,
    super.key,
  });

  final String initiatingExerciseTitle;
  final List<RoutineSupersetMemberCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioEditorSheet(
      key: const ValueKey('routine-superset-member-sheet'),
      title: 'Superset',
      supportingText: '$initiatingExerciseTitle with…',
      pinHeader: true,
      content: candidates.isEmpty
          ? const Padding(
              key: ValueKey('routine-superset-empty'),
              padding: EdgeInsets.all(TioSpacing.lg),
              child: Text(
                'Add a second exercise first. A Superset needs at least two exercises.',
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  key: const ValueKey('routine-superset-candidate-divider-top'),
                  height: TioStroke.width05,
                  thickness: TioStroke.width05,
                  color: Theme.of(context).dividerColor,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: ListView.separated(
                    key: const ValueKey('routine-superset-candidate-list'),
                    shrinkWrap: true,
                    primary: false,
                    padding: EdgeInsets.zero,
                    itemCount: candidates.length,
                    separatorBuilder: (context, index) => Divider(
                      key: ValueKey(
                        'routine-superset-candidate-divider-${index + 1}',
                      ),
                      height: TioStroke.width05,
                      thickness: TioStroke.width05,
                      color: Theme.of(context).dividerColor,
                    ),
                    itemBuilder: (context, index) =>
                        _candidateRow(context, candidates[index], colors),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _candidateRow(
    BuildContext context,
    RoutineSupersetMemberCandidate candidate,
    TioColors colors,
  ) =>
      ListTile(
        key: ValueKey('routine-superset-candidate-${candidate.entryId}'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.sm,
        ),
        minLeadingWidth: TioSize.dp4,
        horizontalTitleGap: TioSpacing.xs,
        leading: candidate.supersetLabel == null
            ? null
            : SupersetGroupMarker(
                key: ValueKey(
                  'routine-superset-candidate-accent-${candidate.entryId}',
                ),
                groupLabel: candidate.supersetLabel!,
                height: TioSize.dp40,
              ),
        title: Semantics(
          key: ValueKey(
            'routine-superset-candidate-semantics-${candidate.entryId}',
          ),
          label: candidate.supersetLabel == null
              ? candidate.title
              : '${candidate.title}, already in Superset ${_groupName(candidate.supersetLabel!)}',
          excludeSemantics: true,
          child: Text(candidate.title),
        ),
        trailing: Icon(
          candidate.isAlreadyGrouped
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: candidate.supersetLabel == null
              ? colors.primary
              : supersetGroupColor(context, candidate.supersetLabel!),
        ),
        onTap: candidate.isAlreadyGrouped
            ? null
            : () => Navigator.of(context).pop<String>(candidate.entryId),
      );
}

String _groupName(String memberLabel) =>
    memberLabel.replaceFirst(RegExp(r'\d+$'), '');
