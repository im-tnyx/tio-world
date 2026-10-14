import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_repository.dart';
import '../exercises/exercises_controller.dart';
import '../exercises/exercises_state.dart';
import 'routine_editor_controller.dart';
import 'routine_exercise_picker_controller.dart';
import '../exercises/exercises_page.dart';
import 'routine_exercise_options_sheet.dart';
import 'routine_set_editor_sheet.dart';
import 'routine_set_input_row.dart';
import 'routine_measurement_profile.dart';
import 'routine_composer_screen.dart';

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
    this.viewerMediaGender,
    this.canWrite,
    this.newUuid,
    super.key,
  });

  final Program program;
  final Routine routine;
  final RoutineRepository? routineRepository;
  final RoutineCompositionRepository? compositionRepository;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  /// Profile-resolved by the app; null uses catalog's default media gender.
  final ExerciseMediaGender? viewerMediaGender;
  /// Live opening-session capability, not a cached authorization snapshot.
  final bool Function()? canWrite;
  final WeightUnit? weightUnit;

  /// Test seam only; production uses UUID v4.
  final String Function()? newUuid;

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  RoutineEditorController? _editor;
  RoutineExercisePickerController? _source;
  final Set<String> _invalidSetIds = {};
  final Set<String> _draftRangeEntryIds = {};
  final Set<String> _blankSetIds = {};
  String? _openSetId;

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
    _draftRangeEntryIds.clear();
    _invalidSetIds.clear();
    _blankSetIds.clear();
    _openSetId = null;
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
      userExercises: widget.userExerciseRepository,
      canWrite: widget.canWrite,
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

  Future<void> _addExercise({RoutineCompositionEntry? replacing}) async {
    final editor = _editor;
    if (!_canEdit || editor == null) return;
    final unit = widget.weightUnit;
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (routeContext) => ProviderScope(
          child: ExercisesPage(
            catalogRepository: widget.catalogRepository,
            userExerciseRepository: widget.userExerciseRepository,
            onExerciseSelected: (selected) =>
                Navigator.of(routeContext).pop<Exercise>(selected),
          ),
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
    // The picker freshly verifies owner-scoped Custom and catalog selection.
    if (exercise.status != ExerciseStatus.active) return;
    if (replacing != null) {
      final oldEntries = editor.state.entries
          .where((entry) => entry.id == replacing.id);
      if (oldEntries.length != 1) return;
      final old = oldEntries.single;
      final newId = editor.replacePickedExercise(old.id, exercise);
      if (newId != null) {
        _draftRangeEntryIds.remove(old.id);
        final oldSetIds = old.sets.map((set) => set.id);
        _invalidSetIds.removeAll(oldSetIds);
        _blankSetIds.removeAll(oldSetIds);
        if (oldSetIds.contains(_openSetId)) _openSetId = null;
        final fresh = editor.state.entries.singleWhere((e) => e.id == newId);
        _blankSetIds.add(fresh.sets.single.id);
      }
    } else {
      final entryId = editor.addPickedExercise(exercise);
      if (entryId != null) {
        final setId = editor.addSet(entryId, SetPrescription());
        if (setId != null) _blankSetIds.add(setId);
      }
    }
    // Refresh labels and write-capability from the current owner source.
    // A failed reload disables Update; no premature persistence.
    await _source?.load();
  }

  Future<void> _setEditor(
    RoutineCompositionEntry entry, {
    RoutineCompositionSet? existing,
  }) async {
    final editor = _editor;
    final unit = widget.weightUnit;
    if (!_canEdit || editor == null || unit == null) return;
    ExerciseType? profile;
    for (final item in _source?.state.items ?? <ExerciseListItem>[]) {
      if (item.exercise.ref == entry.exercise) {
        profile = routineEntryMeasurementProfile(
          item.exercise.exerciseType,
          entry.sets,
        );
        break;
      }
    }
    final result = await showTioEditorSheet<SetPrescription>(
      context: context,
      useSafeArea: true,
      builder: (_) => RoutineSetEditorSheet(
        unit: unit,
        initial: existing?.prescription,
        exerciseType: profile,
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

  void _validityChanged(String id, bool valid) {
    if (!mounted) return;
    setState(() {
      if (valid) {
        _blankSetIds.remove(id);
        _invalidSetIds.remove(id);
      } else {
        _invalidSetIds.add(id);
      }
    });
  }

  Future<void> _showExerciseOptions(RoutineCompositionEntry entry) async {
    if (!_canEdit) return;
    final openingEditor = _editor;
    final action = await showRoutineExerciseOptionsSheet(context);
    if (!mounted || !identical(openingEditor, _editor) ||
        !_canEdit || action == null) {
      return;
    }
    if (openingEditor == null ||
        !openingEditor.state.entries.any((current) => current.id == entry.id)) {
      return;
    }
    if (action == RoutineExerciseOption.replace) {
      await _addExercise(replacing: entry);
    } else if (action == RoutineExerciseOption.remove) {
      _removeEntry(entry);
    }
  }

  void _removeEntry(RoutineCompositionEntry entry) {
    if (!_canEdit) return;
    _editor?.removeExercise(entry.id);
    _draftRangeEntryIds.remove(entry.id);
    final ids = entry.sets.map((set) => set.id);
    _invalidSetIds.removeAll(ids);
    _blankSetIds.removeAll(ids);
    if (entry.sets.any((set) => set.id == _openSetId)) _openSetId = null;
  }

  void _removeSet(RoutineCompositionEntry entry, RoutineCompositionSet set) {
    if (!_canEdit) return;
    if (entry.sets.length == 1) {
      _removeEntry(entry);
      return;
    }
    _editor?.removeSet(entry.id, set.id);
    _invalidSetIds.remove(set.id);
    _blankSetIds.remove(set.id);
    if (_openSetId == set.id) _openSetId = null;
  }

  void _addSetInline(RoutineCompositionEntry entry) {
    if (!_canEdit) return;
    if (_openSetId != null) setState(() => _openSetId = null);
    final hadPersistedRange =
        entry.sets.any((set) => set.prescription.isRepRange);
    final id = _editor?.addSet(entry.id, SetPrescription());
    if (id != null) {
      _blankSetIds.add(id);
      // The new nullable Set cannot encode Range until both Reps fields
      // are filled. Keep its editor in Range mode and block mixed writes.
      if (hadPersistedRange) _draftRangeEntryIds.add(entry.id);
    }
  }

  void _setOpen(String id, bool open) {
    if (!mounted) return;
    final next = open ? id : (_openSetId == id ? null : _openSetId);
    if (next != _openSetId) setState(() => _openSetId = next);
  }

  Future<void> _selectSetType(
    RoutineCompositionEntry entry, RoutineCompositionSet set,
  ) async {
    if (!_canEdit) return;
    final type = await showTioEditorSheet<Object>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Select Set Type',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final kind in RoutineSetType.values)
            ListTile(
              key: ValueKey('edit-routine-type-${kind.wireValue}'),
              title: Text(switch (kind) {
                RoutineSetType.normal => 'Normal Set',
                RoutineSetType.warmUp => 'Warm Up Set',
                RoutineSetType.failure => 'Failure Set',
                RoutineSetType.drop => 'Drop Set',
              }),
              trailing: kind == set.prescription.setType
                  ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop<Object>(kind),
            ),
          // Existing Edit functionality still needs a path to Rest and
          // other advanced prescription attributes. Numeric Reps/Weight
          // remain inline; this secondary action preserves Rest editing.
          ListTile(
            key: const ValueKey('edit-routine-set-details'),
            title: const Text('Rest & set details'),
            onTap: () => Navigator.of(sheetContext).pop<Object>('details'),
          ),
          ListTile(
            key: const ValueKey('edit-routine-type-remove'),
            title: const Text('Remove Set'),
            onTap: () => Navigator.of(sheetContext).pop<Object>('remove'),
          ),
        ]),
      ),
    );
    if (!mounted || !_canEdit || type == null) return;
    if (type == 'remove') {
      _removeSet(entry, set);
    } else if (type == 'details') {
      await _setEditor(entry, existing: set);
    } else if (type is RoutineSetType) {
      final current = set.prescription;
      _editor?.editSet(entry.id, set.id, SetPrescription(
        reps: current.reps, repsMax: current.repsMax,
        setType: type, loadKg: current.loadKg,
        distanceMeters: current.distanceMeters,
        durationSeconds: current.durationSeconds,
        restSeconds: current.restSeconds,
      ));
    }
  }

  Future<void> _selectRepetitionMode(RoutineCompositionEntry entry) async {
    if (!_canEdit || entry.sets.isEmpty) return;
    final range = _draftRangeEntryIds.contains(entry.id) ||
        entry.sets.first.prescription.isRepRange;
    final selection = await showTioEditorSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Repetition Options',
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            key: const ValueKey('edit-routine-reps-fixed'),
            title: const Text('Reps'),
            trailing: !range ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(sheetContext).pop<bool>(false),
          ),
          ListTile(
            key: const ValueKey('edit-routine-reps-range'),
            title: const Text('Rep Range'),
            trailing: range ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(sheetContext).pop<bool>(true),
          ),
        ]),
      ),
    );
    if (!mounted || !_canEdit || selection == null) return;
    if (selection) {
      setState(() => _draftRangeEntryIds.add(entry.id));
    } else {
      setState(() => _draftRangeEntryIds.remove(entry.id));
      _editor?.changeRepetitionMode(entry.id, range: false);
    }
  }

  void _reload() {
    _draftRangeEntryIds.clear();
    _invalidSetIds.clear();
    _blankSetIds.clear();
    _openSetId = null;
    _editor?.load();
  }

  bool get _rangeCanSave {
    final editor = _editor;
    if (editor == null) {
      return false;
    }
    for (final entry in editor.state.entries) {
      // Persisted range entries must also be checked even before the user
      // explicitly picks Range in this editing session. Otherwise Update
      // sends mixed ranged/blank Sets rejected by the database RPC.
      if (entry.sets.any((s) => s.prescription.isRepRange) &&
          entry.sets.any((s) => !s.prescription.isRepRange)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    final editor = _editor;
    if (!_canEdit || editor == null ||
        _invalidSetIds.isNotEmpty || !_rangeCanSave) {
      return;
    }
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
    final status = _editor?.state.status;
    final saving = status == RoutineEditorStatus.saving;
    return PopScope(
      canPop: !saving,
      child: RoutineComposerScreen(
        key: const ValueKey('routine-composer-screen'),
        mode: RoutineComposerMode.edit,
        pageKey: const ValueKey('edit-routine-page'),
        cancelKey: const ValueKey('edit-routine-cancel'),
        cancelEnabled: !saving,
        cancel: () => Navigator.of(context).pop<bool>(false),
        submitKey: status == RoutineEditorStatus.ready &&
                widget.weightUnit != null
            ? const ValueKey('edit-routine-update')
            : null,
        onSubmit: _canEdit && _invalidSetIds.isEmpty && _rangeCanSave
            ? _save
            : null,
        content: _body(),
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
      case RoutineEditorStatus.verifying:
      case RoutineEditorStatus.saving:
        return Center(
          key: ValueKey(switch (state.status) {
            RoutineEditorStatus.loading => 'edit-routine-loading',
            RoutineEditorStatus.verifying => 'edit-routine-verifying',
            _ => 'edit-routine-saving',
          }),
          child: CircularProgressIndicator(
            semanticsLabel: switch (state.status) {
              RoutineEditorStatus.loading => 'Loading Routine',
              RoutineEditorStatus.verifying => 'Verifying Custom Exercises',
              _ => 'Updating Routine',
            },
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
            onPressed: _reload,
          ),
        );
      case RoutineEditorStatus.revisionConflict:
        return _Message(
          key: const ValueKey('edit-routine-conflict'),
          message: state.message ?? 'Routine changed elsewhere.',
          action: TioButton.secondary(
            key: const ValueKey('edit-routine-reload'),
            label: 'Reload and discard changes',
            onPressed: _reload,
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
    return RoutineComposerContent(
      mode: RoutineComposerMode.edit,
      scrollKey: const ValueKey('edit-routine-entries'),
      reorderKey: const ValueKey('edit-routine-reorder-exercises'),
      entries: state.entries,
      header: Column(
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
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.all(TioSpacing.sm),
              child: Text(state.message!,
                  style: TextStyle(color: context.tioColors.danger)),
            ),
          if (state.entries.isEmpty)
            const _Message(
              key: ValueKey('edit-routine-empty'),
              message: 'No exercises in this Routine yet.',
            ),
        ],
      ),
      onReorder: (from, to) {
        if (_canEdit) _editor?.moveExercise(from, to);
      },
      itemBuilder: _exerciseCard,
      footer: TioButton.secondary(
        key: const ValueKey('edit-routine-add-exercise'),
        label: 'Add Exercise',
        expand: true,
        onPressed: _canEdit ? () => _addExercise() : null,
      ),
    );
  }

  Widget _exerciseCard(RoutineCompositionEntry entry, int position) {
    Exercise? found;
    for (final item in _source?.state.items ?? <ExerciseListItem>[]) {
      if (item.exercise.ref == entry.exercise) {
        found = item.exercise;
        break;
      }
    }
    final exerciseType = routineEntryMeasurementProfile(
      found?.exerciseType,
      entry.sets,
    );
    return RoutineComposerExerciseCard(
      key: ValueKey('edit-routine-entry-${entry.id}'),
      mode: RoutineComposerMode.edit,
      entry: entry,
      index: position,
      totalEntries: _editor?.state.entries.length ?? 0,
      title: found?.displayName ?? 'Exercise unavailable',
      thumbnailUrl: found == null
          ? null
          : ExercisesController.thumbnailUrlFor(
              found,
              gender: widget.viewerMediaGender,
            ),
      exerciseType: exerciseType,
      showRangeDraft: _draftRangeEntryIds.contains(entry.id),
      unit: widget.weightUnit!,
      enabled: _canEdit,
      moveUp: () => _editor?.moveExercise(position, position - 1),
      moveDown: () => _editor?.moveExercise(position, position + 1),
      showOptions: () => _showExerciseOptions(entry),
      selectRepetitionMode: () => _selectRepetitionMode(entry),
      buildSetRow: (set, index) =>
          _setRow(entry, set, index, exerciseType),
      addSet: () => _addSetInline(entry),
    );
  }

  Widget _setRow(RoutineCompositionEntry entry,
      RoutineCompositionSet set, int index, ExerciseType? exerciseType) =>
      RoutineSetInputRow(
        key: ValueKey('edit-routine-set-${set.id}'),
        set: set,
        index: index,
        normalNumber: entry.sets.take(index + 1)
            .where((s) => s.prescription.setType == RoutineSetType.normal)
            .length,
        unit: widget.weightUnit!,
        enabled: _canEdit,
        exerciseType: exerciseType,
        showRangeDraft: _draftRangeEntryIds.contains(entry.id),
        showPrevious: true,
        startWithBlankReps: _blankSetIds.contains(set.id),
        isOpen: _openSetId == set.id,
        onOpenChanged: (open) => _setOpen(set.id, open),
        onTypePressed: () => _selectSetType(entry, set),
        onChanged: (prescription) {
          if (set.prescription.isRepRange &&
              !prescription.isRepRange) {
            _draftRangeEntryIds.add(entry.id);
          }
          _editor?.editSet(entry.id, set.id, prescription);
        },
        onValidityChanged: (valid) => _validityChanged(set.id, valid),
        onRemove: () => _removeSet(entry, set),
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
