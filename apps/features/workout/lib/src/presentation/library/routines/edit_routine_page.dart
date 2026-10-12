import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_repository.dart';
import '../exercises/exercises_state.dart';
import 'routine_editor_controller.dart';
import 'routine_exercise_picker_controller.dart';
import 'routine_exercise_picker_page.dart';
import 'routine_set_editor_sheet.dart';

/// Separate Program-owned Routine editor; Detail and Rename stay unchanged.
/// Returns true only after a confirmed save or read-verified mutation.
class EditRoutinePage extends StatefulWidget {
  const EditRoutinePage({
    required this.program,
    required this.routine,
    required this.routineRepository,
    required this.compositionRepository,
    required this.catalogRepository,
    required this.weightUnit,
    this.userExerciseRepository,
    this.newUuid,
    super.key,
  });

  final Program program;
  final Routine routine;
  final RoutineRepository? routineRepository;
  final RoutineCompositionRepository? compositionRepository;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final WeightUnit? weightUnit;

  /// Test seam only; production uses UUID v4.
  final String Function()? newUuid;

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  RoutineEditorController? _editor;
  RoutineExercisePickerController? _source;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant EditRoutinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id ||
        oldWidget.routine.id != widget.routine.id ||
        !identical(oldWidget.routineRepository, widget.routineRepository) ||
        !identical(oldWidget.compositionRepository,
            widget.compositionRepository) ||
        !identical(oldWidget.catalogRepository, widget.catalogRepository) ||
        !identical(
            oldWidget.userExerciseRepository, widget.userExerciseRepository)) {
      _bind(); // Revokes any previous account's in-memory data and callbacks.
    }
  }

  void _bind() {
    _editor
      ?..removeListener(_changed)
      ..dispose();
    _source
      ?..removeListener(_changed)
      ..dispose();
    _editor = null;
    _source = null;

    final routines = widget.routineRepository;
    final compositions = widget.compositionRepository;
    if (routines == null ||
        compositions == null ||
        widget.routine.programId != widget.program.id) {
      return;
    }
    final editor = RoutineEditorController(
      program: widget.program,
      routine: widget.routine,
      routines: routines,
      compositions: compositions,
      newUuid: widget.newUuid,
    )..addListener(_changed);
    final source = RoutineExercisePickerController(
      catalogRepository: widget.catalogRepository,
      userExerciseRepository: widget.userExerciseRepository,
    )..addListener(_changed);
    _editor = editor;
    _source = source;
    editor.load();
    source.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _editor
      ?..removeListener(_changed)
      ..dispose();
    _source
      ?..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  bool get _canEdit {
    final editor = _editor;
    if (editor == null ||
        !editor.state.canEdit ||
        widget.weightUnit == null ||
        _source?.state.status != RoutineExercisePickerStatus.ready) {
      return false;
    }
    return widget.userExerciseRepository != null ||
        !editor.state.entries.any(
          (entry) => entry.exercise is UserCreatedExerciseRef,
        );
  }

  Future<void> _addExercise() async {
    final editor = _editor;
    if (!_canEdit || editor == null) return;
    final unit = widget.weightUnit;
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => RoutineExercisePickerPage(
          catalogRepository: widget.catalogRepository,
          userExerciseRepository: widget.userExerciseRepository,
        ),
      ),
    );
    if (!mounted ||
        !identical(editor, _editor) ||
        !_canEdit ||
        unit != widget.weightUnit ||
        exercise == null) {
      return;
    }
    // The picker validates selection against its own freshly loaded,
    // owner-scoped catalog/Custom snapshot before returning this Exercise.
    // The editor's initial _source snapshot can be older (e.g. another
    // device created a Custom Exercise while this screen stayed open).
    // Do not reject a valid picker result against that stale snapshot.
    if (exercise.status != ExerciseStatus.active) return;
    editor.addPickedExercise(exercise);
    // Refresh labels and write-capability from the current source. A failed
    // reload disables Update until Retry; the draft stays unsaved.
    _source?.load();
  }

  Future<void> _setEditor(
    RoutineCompositionEntry entry, {
    RoutineCompositionSet? existing,
  }) async {
    final editor = _editor;
    final unit = widget.weightUnit;
    if (!_canEdit || editor == null || unit == null) return;
    final result = await showTioEditorSheet<SetPrescription>(
      context: context,
      useSafeArea: true,
      builder: (_) => RoutineSetEditorSheet(
        unit: unit,
        initial: existing?.prescription,
      ),
    );
    if (!mounted ||
        !identical(editor, _editor) ||
        !_canEdit ||
        unit != widget.weightUnit ||
        result == null) {
      return;
    }
    if (existing == null) {
      editor.addSet(entry.id, result);
    } else {
      editor.editSet(entry.id, existing.id, result);
    }
  }

  Future<void> _save() async {
    final editor = _editor;
    if (!_canEdit || editor == null) return;
    final confirmed = await editor.update();
    if (mounted &&
        identical(editor, _editor) &&
        confirmed &&
        editor.state.status == RoutineEditorStatus.saved) {
      _finishConfirmed();
    }
  }

  Future<void> _verifyUnknown() async {
    final editor = _editor;
    if (editor == null ||
        editor.state.status != RoutineEditorStatus.outcomeUnknown) {
      return;
    }
    final confirmed = await editor.reconcileUnknown();
    if (mounted && identical(editor, _editor) && confirmed) {
      _finishConfirmed();
    }
  }

  // PopScope was blocking exit while the request was in flight. Wait for
  // the saved-state rebuild before requesting route pop.
  void _finishConfirmed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editor?.state.status == RoutineEditorStatus.saved) {
        Navigator.of(context).pop<bool>(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final status = _editor?.state.status;
    final saving = status == RoutineEditorStatus.saving;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        key: const ValueKey('edit-routine-page'),
        backgroundColor: colors.background,
        appBar: TioAppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          leading: IconButton(
            key: const ValueKey('edit-routine-cancel'),
            tooltip: 'Cancel and discard draft',
            icon: const Icon(Icons.close_rounded),
            color: colors.textPrimary,
            onPressed: saving
                ? null
                : () => Navigator.of(context).pop<bool>(false),
          ),
          title: Text(
            'Edit Routine',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w800,
              fontSize: TioFontSize.size20,
            ),
          ),
        ),
        body: SafeArea(child: _body()),
        bottomNavigationBar: status == RoutineEditorStatus.ready &&
                widget.weightUnit != null
            ? SafeArea(
                minimum: const EdgeInsets.all(TioSpacing.lg),
                child: TioButton.primary(
                  key: const ValueKey('edit-routine-update'),
                  label: 'Update',
                  expand: true,
                  onPressed: _canEdit ? _save : null,
                ),
              )
            : null,
      ),
    );
  }

  Widget _body() {
    final state = _editor?.state;
    if (state == null || widget.weightUnit == null) {
      return const _Message(
        key: ValueKey('edit-routine-unavailable'),
        message: 'Routine editing is unavailable until your account and units are ready.',
      );
    }
    switch (state.status) {
      case RoutineEditorStatus.loading:
      case RoutineEditorStatus.saving:
        return Center(
          key: ValueKey(state.status == RoutineEditorStatus.loading
              ? 'edit-routine-loading'
              : 'edit-routine-saving'),
          child: CircularProgressIndicator(
            semanticsLabel: state.status == RoutineEditorStatus.loading
                ? 'Loading Routine'
                : 'Updating Routine',
          ),
        );
      case RoutineEditorStatus.notFound:
        return const _Message(
          key: ValueKey('edit-routine-not-found'),
          message: 'This Routine is no longer available in this Program.',
        );
      case RoutineEditorStatus.loadFailed:
        return _Message(
          key: const ValueKey('edit-routine-load-failed'),
          message: state.message ?? 'Could not load Routine.',
          action: TioButton.secondary(
            label: 'Try again',
            onPressed: _editor?.load,
          ),
        );
      case RoutineEditorStatus.revisionConflict:
        return _Message(
          key: const ValueKey('edit-routine-conflict'),
          message: state.message ?? 'Routine changed elsewhere.',
          action: TioButton.secondary(
            key: const ValueKey('edit-routine-reload'),
            label: 'Reload and discard changes',
            onPressed: _editor?.load,
          ),
        );
      case RoutineEditorStatus.outcomeUnknown:
        return _Message(
          key: const ValueKey('edit-routine-unknown'),
          message: state.message ??
              'Update may have saved. Do not retry without verification.',
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TioButton.primary(
                key: const ValueKey('edit-routine-verify'),
                label: 'Check saved data',
                onPressed: _verifyUnknown,
              ),
              const SizedBox(height: TioSpacing.sm),
              TioButton.secondary(
                label: 'Close without retry',
                onPressed: () => Navigator.of(context).pop<bool>(false),
              ),
            ],
          ),
        );
      case RoutineEditorStatus.saved:
        return const _Message(message: 'Routine updated.');
      case RoutineEditorStatus.ready:
        return _list(state);
    }
  }

  Widget _list(RoutineEditorState state) {
    final sourceStatus = _source?.state.status;
    return ListView.builder(
      key: const ValueKey('edit-routine-entries'),
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md,
      ),
      itemCount: state.entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.routine.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: TioSpacing.md),
              if (sourceStatus != RoutineExercisePickerStatus.ready)
                _Message(
                  key: const ValueKey('edit-routine-source-unavailable'),
                  message: sourceStatus == RoutineExercisePickerStatus.failed
                      ? 'Could not verify Exercises. Try again.'
                      : 'Loading Exercises...',
                  action: sourceStatus == RoutineExercisePickerStatus.failed
                      ? TioButton.secondary(
                          key: const ValueKey('edit-routine-source-retry'),
                          label: 'Try again',
                          onPressed: _source?.load,
                        )
                      : null,
                ),
              if (widget.userExerciseRepository == null &&
                  state.entries.any((e) =>
                      e.exercise is UserCreatedExerciseRef))
                const _Message(
                  message: 'Custom Exercises are unavailable for this account.',
                ),
              TioButton.secondary(
                key: const ValueKey('edit-routine-add-exercise'),
                label: 'Add Exercise',
                expand: true,
                onPressed: _canEdit ? _addExercise : null,
              ),
              if (state.message != null)
                Padding(
                  padding: const EdgeInsets.all(TioSpacing.sm),
                  child: Text(
                    state.message!,
                    style: TextStyle(color: context.tioColors.danger),
                  ),
                ),
              if (state.entries.isEmpty)
                const _Message(
                  key: ValueKey('edit-routine-empty'),
                  message: 'No exercises in this Routine yet.',
                ),
              const SizedBox(height: TioSpacing.md),
            ],
          );
        }

        final entry = state.entries[index - 1];
        Exercise? found;
        for (final item in _source?.state.items ?? <ExerciseListItem>[]) {
          if (item.exercise.ref == entry.exercise) {
            found = item.exercise;
            break;
          }
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: TioSpacing.sm),
          child: TioCard(
            key: ValueKey('edit-routine-entry-${entry.id}'),
            child: _EntryCard(
              entry: entry,
              title: found?.displayName ?? 'Exercise unavailable',
              index: index,
              unit: widget.weightUnit!,
              enabled: _canEdit,
              hasPrevious: index > 1,
              hasNext: index < state.entries.length,
              moveUp: () => _editor?.moveExercise(index - 1, index - 2),
              moveDown: () => _editor?.moveExercise(index - 1, index),
              remove: () => _editor?.removeExercise(entry.id),
              addSet: () => _setEditor(entry),
              editSet: (set) => _setEditor(entry, existing: set),
              removeSet: (set) => _editor?.removeSet(entry.id, set.id),
              moveSet: (from, to) => _editor?.moveSet(entry.id, from, to),
            ),
          ),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.title,
    required this.index,
    required this.unit,
    required this.enabled,
    required this.hasPrevious,
    required this.hasNext,
    required this.moveUp,
    required this.moveDown,
    required this.remove,
    required this.addSet,
    required this.editSet,
    required this.removeSet,
    required this.moveSet,
  });

  final RoutineCompositionEntry entry;
  final String title;
  final int index;
  final WeightUnit unit;
  final bool enabled;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback moveUp;
  final VoidCallback moveDown;
  final VoidCallback remove;
  final VoidCallback addSet;
  final ValueChanged<RoutineCompositionSet> editSet;
  final ValueChanged<RoutineCompositionSet> removeSet;
  final void Function(int, int) moveSet;

  Widget _row(BuildContext context, int index) {
    final set = entry.sets[index];
    final label = <String>['${set.prescription.reps} reps'];
    if (set.prescription.loadKg != null) {
      label.add(UnitFormatters.formatWeight(set.prescription.loadKg!, unit));
    }
    if (set.prescription.restSeconds != null) {
      label.add('${set.prescription.restSeconds} sec rest');
    }
    return Column(
      key: ValueKey('edit-routine-set-${set.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set ${index + 1} · ${label.join(' · ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.tioColors.textSecondary),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              key: ValueKey('edit-routine-set-up-${set.id}'),
              tooltip: 'Move Set up',
              onPressed: enabled && index > 0
                  ? () => moveSet(index, index - 1)
                  : null,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
            IconButton(
              key: ValueKey('edit-routine-set-down-${set.id}'),
              tooltip: 'Move Set down',
              onPressed: enabled && index < entry.sets.length - 1
                  ? () => moveSet(index, index + 1)
                  : null,
              icon: const Icon(Icons.arrow_downward_rounded),
            ),
            IconButton(
              key: ValueKey('edit-routine-set-edit-${set.id}'),
              tooltip: 'Edit Set',
              onPressed: enabled ? () => editSet(set) : null,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              key: ValueKey('edit-routine-set-remove-${set.id}'),
              tooltip: 'Remove Set',
              onPressed: enabled ? () => removeSet(set) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$index. $title',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Row(
            children: [
              IconButton(
                key: ValueKey('edit-routine-entry-up-${entry.id}'),
                tooltip: 'Move Exercise up',
                onPressed: enabled && hasPrevious ? moveUp : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              IconButton(
                key: ValueKey('edit-routine-entry-down-${entry.id}'),
                tooltip: 'Move Exercise down',
                onPressed: enabled && hasNext ? moveDown : null,
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
              const Spacer(),
              IconButton(
                key: ValueKey('edit-routine-entry-remove-${entry.id}'),
                tooltip: 'Remove Exercise',
                onPressed: enabled ? remove : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (entry.sets.length > 40)
            SizedBox(
              height: TioSize.dp200,
              child: ListView.builder(
                key: ValueKey('edit-routine-set-list-${entry.id}'),
                primary: false,
                itemCount: entry.sets.length,
                itemBuilder: (context, index) => _row(context, index),
              ),
            )
          else
            for (var i = 0; i < entry.sets.length; i++) _row(context, i),
          if (entry.sets.isEmpty)
            Text(
              'No sets prescribed',
              style: TextStyle(color: context.tioColors.textSecondary),
            ),
          const SizedBox(height: TioSpacing.sm),
          TioButton.secondary(
            key: ValueKey('edit-routine-add-set-${entry.id}'),
            label: 'Add Set',
            onPressed: enabled ? addSet : null,
          ),
        ],
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.action, super.key});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.tioColors.textSecondary),
              ),
              if (action != null) ...[
                const SizedBox(height: TioSpacing.md),
                action!,
              ],
            ],
          ),
        ),
      );
}
