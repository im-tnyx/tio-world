import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/routine_rest_timer_preset.dart';
import '../../domain/repositories/routine_composition_repository.dart';
import '../../domain/repositories/routine_notes_repository.dart';
import '../library/exercises/widgets/exercise_list_row.dart';
import '../library/routines/exercise_notes_inline.dart';
import '../library/routines/routine_notes_controller.dart';
import '../library/routines/routine_notes_save_bridge.dart';

/// Presentation mode for the shared [WorkoutExerciseCard].
enum WorkoutExerciseCardMode { create, edit, log }

/// Unified exercise card used across Routine Creator, Routine Editor, and Active Workout Log.
///
/// Keeps screens dumb and clean by centralizing:
/// - Exercise thumbnail/avatar and title
/// - Three-dots exercise options menu
/// - Rest timer pill and inline notes
/// - Column headers (with responsive RPE and execution checkmark in log mode)
/// - Set rows composition and "+ Add Set" button
class WorkoutExerciseCard extends StatelessWidget {
  const WorkoutExerciseCard({
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
    required this.buildSetRow,
    required this.addSet,
    this.moveUp,
    this.moveDown,
    this.showOptions,
    this.selectRepetitionMode,
    this.restPreset = const RoutineRestTimerPreset(),
    this.onConfigureRestTimer,
    this.routineId,
    this.routineNotesRepository,
    this.routineNotesOwnerId,
    this.isRoutineNotesSessionCurrent,
    this.onNoteDraftsChanged,
    this.initialNoteDrafts = const [],
    this.readOnlyNoteDraftIds = const {},
    this.notesEnabled,
    this.controllerRegistry,
    this.showRpe = false,
    this.supersetLabel,
    this.keyPrefix,
    super.key,
  });

  final WorkoutExerciseCardMode mode;
  final RoutineCompositionEntry entry;
  final int index;
  final int totalEntries;
  final String title;
  final Uri? thumbnailUrl;
  final ExerciseType? exerciseType;
  final bool showRangeDraft;
  final WeightUnit unit;
  final bool enabled;
  final VoidCallback? moveUp;
  final VoidCallback? moveDown;
  final VoidCallback? showOptions;
  final VoidCallback? selectRepetitionMode;
  final Widget Function(RoutineCompositionSet set, int index) buildSetRow;
  final VoidCallback addSet;
  final RoutineRestTimerPreset restPreset;
  final VoidCallback? onConfigureRestTimer;
  final RoutineId? routineId;
  final RoutineNotesRepository? routineNotesRepository;
  final String? routineNotesOwnerId;
  final RoutineNotesSessionIsCurrent? isRoutineNotesSessionCurrent;
  final ValueChanged<List<ExerciseNoteDraftSnapshot>>? onNoteDraftsChanged;
  final List<ExerciseNoteDraftSnapshot> initialNoteDrafts;
  final Set<String> readOnlyNoteDraftIds;
  final bool? notesEnabled;
  final RoutineNotesControllerRegistry? controllerRegistry;
  final bool showRpe;
  final String? supersetLabel;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isEdit = mode == WorkoutExerciseCardMode.edit;
    final isLog = mode == WorkoutExerciseCardMode.log;
    // PREVIOUS is only a placeholder today. At compact RPE-on widths,
    // leave more width for the primary numeric inputs.
    final compactRpe = isLog &&
        showRpe &&
        MediaQuery.sizeOf(context).width < 360;
    final prefix = isLog
        ? (keyPrefix ?? 'active-workout-exercise')
        : isEdit
            ? 'edit-routine'
            : 'create-routine';
    final range = showRangeDraft ||
        (entry.sets.isNotEmpty && entry.sets.first.prescription.isRepRange);
    Widget pad(Widget child) => isLog
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
            child: child,
          )
        : child;

    return Padding(
      padding: EdgeInsets.only(bottom: isLog ? TioSpacing.md : TioSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pad(
            Row(
              children: [
                if (thumbnailUrl != null)
                  ExerciseThumbnail(url: thumbnailUrl!),
              Expanded(
                child: Semantics(
                  key: ValueKey('$prefix-reorder-semantics-${entry.id}'),
                  customSemanticsActions: enabled && !isLog && moveUp != null && moveDown != null
                      ? {
                          if (index > 0)
                            const CustomSemanticsAction(
                              label: 'Move exercise up',
                            ): moveUp!,
                          if (index < totalEntries - 1)
                            const CustomSemanticsAction(
                              label: 'Move exercise down',
                            ): moveDown!,
                        }
                      : const {},
                  child: isLog
                      ? ColoredBox(
                          color: TioPalette.transparent,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: kMinInteractiveDimension,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _exerciseHeading(
                                context,
                                title: title,
                                label: supersetLabel,
                                titleColor: colors.primary,
                                titleWeight: TioFontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : ReorderableDelayedDragStartListener(
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
                              child: _exerciseHeading(
                                context,
                                title: title,
                                label: supersetLabel,
                                titleColor: colors.textPrimary,
                                titleWeight: TioFontWeight.w500,
                              ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              IconButton(
                key: ValueKey(isLog
                    ? '$prefix-options-${entry.id}'
                    : isEdit
                        ? 'edit-routine-entry-options-${entry.id}'
                        : 'create-routine-options-${entry.id}'),
                tooltip: 'Exercise options',
                onPressed: enabled ? showOptions : null,
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          ),
          pad(
            ExerciseNotesInline(
            key: ValueKey(
              '$prefix-exercise-notes-${entry.id}-${entry.exercise.value}',
            ),
            exerciseRef: entry.exercise,
            isWorkoutLog: isLog,
            routineId: routineId,
            repository: routineNotesRepository,
            ownerId: routineNotesOwnerId,
            isSessionCurrent: isRoutineNotesSessionCurrent,
            enabled: notesEnabled ?? enabled,
            draftKey: entry.id,
            initialDrafts: initialNoteDrafts,
            readOnlyDraftIds: readOnlyNoteDraftIds,
            onDraftsChanged: onNoteDraftsChanged,
            controllerRegistry: controllerRegistry,
            restControl: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Semantics(
                button: true,
                label: RoutineRestTimerFormatter.formatSemantics(
                  normalSeconds: restPreset.normalRestSeconds,
                  warmUpSeconds: restPreset.warmUpRestSeconds,
                ),
                child: Material(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(TioRadius.full),
                  child: InkWell(
                    key: ValueKey('$prefix-rest-timer-${entry.id}'),
                    borderRadius: BorderRadius.circular(TioRadius.full),
                    onTap: enabled ? onConfigureRestTimer : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TioSpacing.md,
                        vertical: TioSpacing.xs + 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: TioSize.dp16,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: TioSpacing.xs),
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: TioFontSize.size13,
                                  fontWeight: TioFontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: restPreset.normalRestSeconds != null
                                        ? 'Rest: ${RoutineRestTimerFormatter.formatSeconds(restPreset.normalRestSeconds!)}'
                                        : restPreset.warmUpRestSeconds != null
                                            ? 'Rest: '
                                            : 'Rest: OFF',
                                  ),
                                  if (restPreset.warmUpRestSeconds != null) ...[
                                    if (restPreset.normalRestSeconds != null)
                                      const TextSpan(text: ' '),
                                    TextSpan(
                                      text:
                                          '(${RoutineRestTimerFormatter.formatSeconds(restPreset.warmUpRestSeconds!)})',
                                      style: TextStyle(
                                        color: entry.sets.any((s) =>
                                                s.prescription.setType ==
                                                RoutineSetType.warmUp)
                                            ? colors.warning
                                            : colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
          pad(
            Row(
              children: [
                const SizedBox(
                  width: TioSize.dp38,
                  child: Text('SET', textAlign: TextAlign.center),
                ),
              const SizedBox(width: TioSpacing.sm),
              // Keep header and Set row aligned if the compact RPE-on
              // layout omits the currently unavailable PREVIOUS placeholder.
              if (!compactRpe) ...[
                const SizedBox(
                  width: TioSize.dp64,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('PREVIOUS'),
                  ),
                ),
                const SizedBox(width: TioSpacing.sm),
              ],
              if (isLog && exerciseType == ExerciseType.distanceDuration) ...[
                const Expanded(
                  child: Text('KM', textAlign: TextAlign.center),
                ),
                const SizedBox(width: TioSpacing.sm),
                const Expanded(
                  child: Text('TIME', textAlign: TextAlign.center),
                ),
                if (showRpe) ...[
                  const SizedBox(width: TioSpacing.sm),
                  const SizedBox(
                    width: TioSize.dp44,
                    child: Text('RPE', textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(width: TioSpacing.sm),
                const SizedBox(
                  width: TioSize.dp40,
                  child: Text('✓', textAlign: TextAlign.center),
                ),
              ] else if (isLog && exerciseType == ExerciseType.duration) ...[
                const Expanded(
                  child: Text('TIME', textAlign: TextAlign.center),
                ),
                if (showRpe) ...[
                  const SizedBox(width: TioSpacing.sm),
                  const SizedBox(
                    width: TioSize.dp44,
                    child: Text('RPE', textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(width: TioSpacing.sm),
                const SizedBox(
                  width: TioSize.dp40,
                  child: Text('✓', textAlign: TextAlign.center),
                ),
              ] else if (isLog) ...[
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth < TioSize.dp64
                            ? const Text('KG', textAlign: TextAlign.center)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fitness_center_rounded,
                                      size: TioSize.dp14),
                                  SizedBox(width: TioSpacing.xxs),
                                  Text('KG', textAlign: TextAlign.center),
                                ],
                              ),
                  ),
                ),
                const SizedBox(width: TioSpacing.sm),
                const Expanded(
                  child: Text('REPS', textAlign: TextAlign.center),
                ),
                if (showRpe) ...[
                  const SizedBox(width: TioSpacing.sm),
                  const SizedBox(
                    width: TioSize.dp44,
                    child: Text('RPE', textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(width: TioSpacing.sm),
                const SizedBox(
                  width: TioSize.dp40,
                  child: Text('✓', textAlign: TextAlign.center),
                ),
              ] else if (exerciseType == ExerciseType.distanceDuration) ...[
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
          ),
          // Match the header-to-Set spacing across Create and Edit.
          const SizedBox(height: TioSpacing.sm),
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
          pad(
            TioButton.supporting(
              key: ValueKey('$prefix-add-set-${entry.id}'),
            label: 'Add Set',
            leading: const Icon(Icons.add),
            expand: true,
            semanticLabel:
                entry.sets.length >= RoutineCompositionLimits.maxSetsPerExercise
                    ? 'Add Set: maximum 8 Sets per Exercise reached'
                    : null,
            onPressed: enabled &&
                    entry.sets.length <
                        RoutineCompositionLimits.maxSetsPerExercise
                ? addSet
                : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseHeading(
    BuildContext context, {
    required String title,
    required String? label,
    required Color titleColor,
    required FontWeight titleWeight,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: TioFontSize.size16,
              fontWeight: titleWeight,
              color: titleColor,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: TioSpacing.xxs),
            Text(
              'SUPERSET $label',
              key: ValueKey('superset-member-label-$label'),
              style: TextStyle(
                color: context.tioColors.primary,
                fontSize: TioFontSize.size11,
                fontWeight: TioFontWeight.w700,
              ),
            ),
          ],
        ],
      );
}

/// Backwards-compatible aliases for Routine Composer callers.
typedef RoutineComposerExerciseCard = WorkoutExerciseCard;
typedef RoutineComposerMode = WorkoutExerciseCardMode;
