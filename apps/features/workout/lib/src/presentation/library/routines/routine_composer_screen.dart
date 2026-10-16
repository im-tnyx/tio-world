import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/models/routine_composition_limits.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../exercises/widgets/exercise_list_row.dart';

/// One rendered Routine composition screen for Create and Edit.
/// Persistence, navigation and auth gates remain with the owning controller.
enum RoutineComposerMode { create, edit }

class RoutineComposerScreen extends StatefulWidget {
  const RoutineComposerScreen({
    required this.mode,
    required this.pageKey,
    required this.cancelKey,
    required this.cancel,
    required this.cancelEnabled,
    required this.content,
    this.submitKey,
    this.onSubmit,
    super.key,
  });

  final RoutineComposerMode mode;
  final Key pageKey;
  final Key cancelKey;
  final VoidCallback? cancel;
  final bool cancelEnabled;
  final Widget content;
  final Key? submitKey;
  final VoidCallback? onSubmit;

  @override
  State<RoutineComposerScreen> createState() => _RoutineComposerScreenState();
}

/// Keep the focus policy for both builder modes in one screen.
/// Mobile keyboard Back can hide the IME while leaving a numeric field focused.
class _RoutineComposerScreenState extends State<RoutineComposerScreen>
    with WidgetsBindingObserver {
  double? _previousKeyboardInset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial keyboard absence is not a dismissal event.
    _previousKeyboardInset ??= View.of(context).viewInsets.bottom;
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final keyboardInset = View.of(context).viewInsets.bottom;
    final previousInset = _previousKeyboardInset;
    _previousKeyboardInset = keyboardInset;

    // Do not dismiss another route's input (e.g. the Exercise picker).
    if (previousInset != null &&
        previousInset > 0 &&
        keyboardInset == 0 &&
        ModalRoute.of(context)?.isCurrent == true) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isEdit = widget.mode == RoutineComposerMode.edit;
    return Scaffold(
      key: widget.pageKey,
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            TextButton(
              key: widget.cancelKey,
              onPressed: widget.cancelEnabled ? widget.cancel : null,
              child: const Text('Cancel'),
            ),
            Expanded(
              child: Text(
                isEdit ? 'Edit Routine' : 'Create Routine',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: TioFontSize.size20,
                  fontWeight: TioFontWeight.w800,
                ),
              ),
            ),
            // One action slot for both modes; distinct controllers still own
            // the guarded Save/Update command, but the screen stays identical.
            if (isEdit && widget.submitKey == null)
              const SizedBox(width: TioSize.dp64)
            else
              TextButton(
                key: widget.submitKey,
                onPressed: widget.onSubmit,
                child: Text(isEdit ? 'Update' : 'Save'),
              ),
          ],
        ),
      ),
      body: SafeArea(child: widget.content),
    );
  }
}

/// The only Routine builder scroll/reorder composition.
/// Callers supply controller-owned data and callbacks, not duplicate layout.
class RoutineComposerContent extends StatelessWidget {
  const RoutineComposerContent({
    required this.mode,
    required this.scrollKey,
    required this.reorderKey,
    required this.header,
    required this.entries,
    required this.itemBuilder,
    required this.onReorder,
    required this.footer,
    super.key,
  });

  final RoutineComposerMode mode;
  final Key scrollKey;
  final Key reorderKey;
  final Widget header;
  final List<RoutineCompositionEntry> entries;
  final Widget Function(RoutineCompositionEntry entry, int index) itemBuilder;
  final void Function(int from, int to) onReorder;
  final Widget footer;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        key: scrollKey,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              TioSpacing.lg,
              mode == RoutineComposerMode.create
                  ? TioSpacing.xl
                  : TioSpacing.md,
              TioSpacing.lg,
              TioSpacing.none,
            ),
            sliver: SliverToBoxAdapter(child: header),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
            sliver: SliverReorderableList(
              key: reorderKey,
              itemCount: entries.length,
              // Preserve Material for the controls while a row is in Overlay.
              proxyDecorator: (child, _, __) => Material(
                type: MaterialType.transparency,
                child: child,
              ),
              onReorderStart: (_) => unawaited(HapticFeedback.mediumImpact()),
              onReorderEnd: (_) => unawaited(HapticFeedback.selectionClick()),
              onReorderItem: onReorder,
              itemBuilder: (context, index) =>
                  itemBuilder(entries[index], index),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              TioSpacing.lg,
              TioSpacing.none,
              TioSpacing.lg,
              TioSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(child: footer),
          ),
        ],
      );
}

/// Create/Edit share one Exercise card, Set header and Add Set layout.
/// Only the Edit mode shows the approved read-only PREVIOUS column.
class RoutineComposerExerciseCard extends StatelessWidget {
  const RoutineComposerExerciseCard({
    required this.mode,
    required this.entry,
    required this.index,
    required this.totalEntries,
    required this.title,
    required this.thumbnailUrl,
    required this.exerciseType,
    required this.showRangeDraft,
    required this.unit,
    required this.enabled,
    required this.moveUp,
    required this.moveDown,
    required this.showOptions,
    required this.selectRepetitionMode,
    required this.buildSetRow,
    required this.addSet,
    super.key,
  });

  final RoutineComposerMode mode;
  final RoutineCompositionEntry entry;
  final int index;
  final int totalEntries;
  final String title;
  final Uri? thumbnailUrl;
  final ExerciseType? exerciseType;
  final bool showRangeDraft;
  final WeightUnit unit;
  final bool enabled;
  final VoidCallback moveUp;
  final VoidCallback moveDown;
  final VoidCallback showOptions;
  final VoidCallback selectRepetitionMode;
  final Widget Function(RoutineCompositionSet set, int index) buildSetRow;
  final VoidCallback addSet;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isEdit = mode == RoutineComposerMode.edit;
    final prefix = isEdit ? 'edit-routine' : 'create-routine';
    final range = showRangeDraft ||
        (entry.sets.isNotEmpty &&
            entry.sets.first.prescription.isRepRange);
    return Padding(
      padding: const EdgeInsets.only(bottom: TioSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (thumbnailUrl != null)
                ExerciseThumbnail(url: thumbnailUrl!),
              Expanded(
                child: Semantics(
                  key: ValueKey('$prefix-reorder-semantics-${entry.id}'),
                  customSemanticsActions: enabled
                      ? {
                          if (index > 0)
                            const CustomSemanticsAction(
                              label: 'Move exercise up',
                            ): moveUp,
                          if (index < totalEntries - 1)
                            const CustomSemanticsAction(
                              label: 'Move exercise down',
                            ): moveDown,
                        }
                      : const {},
                  child: ReorderableDelayedDragStartListener(
                    key: ValueKey('$prefix-drag-${entry.id}'),
                    index: index,
                    enabled: enabled,
                    child: ColoredBox(
                      color: TioPalette.transparent,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: kMinInteractiveDimension,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: TioFontSize.size20,
                              fontWeight: TioFontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: ValueKey(isEdit
                    ? 'edit-routine-entry-options-${entry.id}'
                    : 'create-routine-options-${entry.id}'),
                tooltip: 'Exercise options',
                onPressed: enabled ? showOptions : null,
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.md),
          Row(
            children: [
              const SizedBox(
                width: TioSize.dp38,
                child: Text('SET', textAlign: TextAlign.center),
              ),
              const SizedBox(width: TioSpacing.sm),
              if (isEdit) ...[
                const SizedBox(
                  width: TioSize.dp64,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('PREVIOUS'),
                  ),
                ),
                const SizedBox(width: TioSpacing.sm),
              ],
              if (exerciseType == ExerciseType.distanceDuration) ...[
                const Expanded(
                  child: Text('KM', textAlign: TextAlign.center),
                ),
                const SizedBox(width: TioSpacing.sm),
                const Expanded(
                  child: Text('TIME', textAlign: TextAlign.center),
                ),
              ] else if (exerciseType == ExerciseType.duration) ...[
                const Expanded(
                  child: Text('TIME', textAlign: TextAlign.center),
                ),
              ] else ...[
                Expanded(
                  flex: range ? 2 : 1,
                  child: Text(
                    unit == WeightUnit.kg ? 'KG' : 'LB',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: TioSpacing.sm),
                Expanded(
                  flex: range ? 3 : 1,
                  child: Semantics(
                    button: true,
                    label: 'Repetition Options',
                    child: InkWell(
                      key: ValueKey(
                        '$prefix-repetition-options-${entry.id}',
                      ),
                      onTap: enabled ? selectRepetitionMode : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: TioSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                range ? 'REP RANGE' : 'REPS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isEdit) const SizedBox(height: TioSpacing.sm),
          // Historical >40-Set rows remain readable, not truncated by the
          // current 8-Set creation guard.
          if (entry.sets.length > 40)
            SizedBox(
              height: TioSize.dp200,
              child: ListView.builder(
                key: ValueKey('edit-routine-set-list-${entry.id}'),
                primary: false,
                itemCount: entry.sets.length,
                itemBuilder: (context, i) => buildSetRow(entry.sets[i], i),
              ),
            )
          else
            for (var i = 0; i < entry.sets.length; i++)
              buildSetRow(entry.sets[i], i),
          if (isEdit) const SizedBox(height: TioSpacing.xs),
          TioButton.supporting(
            key: ValueKey('$prefix-add-set-${entry.id}'),
            label: 'Add Set',
            leading: const Icon(Icons.add),
            expand: true,
            semanticLabel: entry.sets.length >=
                    RoutineCompositionLimits.maxSetsPerExercise
                ? 'Add Set: maximum 8 Sets per Exercise reached'
                : null,
            onPressed: enabled &&
                    entry.sets.length <
                        RoutineCompositionLimits.maxSetsPerExercise
                ? addSet
                : null,
          ),
        ],
      ),
    );
  }
}
