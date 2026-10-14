import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_create_repository.dart';
import '../../../domain/repositories/routine_repository.dart';
import 'routine_create_controller.dart';
import '../exercises/exercises_controller.dart';
import '../exercises/exercises_page.dart';
import '../exercises/widgets/exercise_list_row.dart';
import 'routine_exercise_options_sheet.dart';
import 'routine_set_input_row.dart';

/// Full-screen, Program-owned Create draft. Nothing persists until Save
/// calls an atomic Create repository. This is NOT the existing-Routine editor.
class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage({
    required this.program,
    required this.initialName,
    required this.createRepository,
    required this.catalogRepository,
    required this.weightUnit,
    this.userExerciseRepository,
    this.viewerMediaGender,
    this.routineRepository,
    this.compositionRepository,
    this.onUnconfirmedExit,
    this.canWrite,
    this.newUuid,
    super.key,
  });

  final Program program;
  final String initialName;
  final RoutineCreateRepository createRepository;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  /// Resolved at app/profile boundary; null follows catalog default gender.
  final ExerciseMediaGender? viewerMediaGender;
  final RoutineRepository? routineRepository;
  final RoutineCompositionRepository? compositionRepository;
  /// App composition uses this to refresh the Program after an explicitly
  /// unconfirmed Create exit; this does not mean a write was acknowledged.
  final VoidCallback? onUnconfirmedExit;
  final WeightUnit weightUnit;
  final bool Function()? canWrite;
  final String Function()? newUuid;

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  late RoutineCreateController _draft;
  late TextEditingController _name;
  // Presentation-only canonical Exercise snapshots for unsaved entries.
  // Durable composition stores ExerciseRef, never duplicated image data.
  final Map<String, Exercise> _entryExercises = {};
  final Set<String> _invalidSetIds = {};
  // UI-only mode while nullable Reps/Max do not yet encode a saved range.
  final Set<String> _draftRangeEntryIds = {};
  // Newly created Sets have no entered target. The canonical model requires
  // positive Reps, so its internal minimum is not interpreted as user input.
  final Set<String> _untouchedRepSetIds = {};
  String? _openSetId;
  bool _unknownExitPromptOpen = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant CreateRoutinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id ||
        !identical(oldWidget.createRepository, widget.createRepository) ||
        !identical(oldWidget.userExerciseRepository, widget.userExerciseRepository)) {
      _draft.removeListener(_changed);
      _draft.dispose();
      _name.dispose();
      _entryExercises.clear();
      _invalidSetIds.clear();
      _draftRangeEntryIds.clear();
      _untouchedRepSetIds.clear();
      _openSetId = null;
      _bind();
    }
  }

  void _bind() {
    _name = TextEditingController(text: widget.initialName);
    _draft = RoutineCreateController(
      program: widget.program,
      initialName: _name.text,
      repository: widget.createRepository,
      userExercises: widget.userExerciseRepository,
      canWrite: widget.canWrite,
      newUuid: widget.newUuid,
    )..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _draft.removeListener(_changed);
    _draft.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _enabled {
    if (widget.canWrite != null && !widget.canWrite!()) return false;
    return _draft.state.status == RoutineCreateStatus.ready;
  }

  Future<void> _pick() async {
    if (!_enabled) return;
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
    if (!mounted || !_enabled || exercise == null) return;
    final id = _draft.addPickedExercise(exercise);
    if (id != null) {
      _entryExercises[id] = exercise;
      final entry = _draft.state.entries.last;
      for (final set in entry.sets) {
        // A new identified Set has intentionally blank optional targets.
        // Only malformed/partially typed numeric text should block Save.
        _untouchedRepSetIds.add(set.id);
      }
    }
  }

  void _validityChanged(String setId, bool valid) {
    if (!mounted) return;
    setState(() {
      if (valid) {
        _untouchedRepSetIds.remove(setId);
        _invalidSetIds.remove(setId);
      } else {
        _invalidSetIds.add(setId);
      }
    });
  }

  Future<void> _showExerciseOptions(RoutineCompositionEntry entry) async {
    if (!_enabled) return;
    final openingDraft = _draft;
    final remove = await showRoutineExerciseOptionsSheet(context);
    if (!mounted || !identical(openingDraft, _draft) || !_enabled || !remove) {
      return;
    }
    if (!_draft.state.entries.any((current) => current.id == entry.id)) return;
    _removeEntry(entry);
  }

  void _removeEntry(RoutineCompositionEntry entry) {
    if (!_enabled) return;
    if (entry.sets.any((set) => set.id == _openSetId)) _openSetId = null;
    _draft.removeExercise(entry.id);
    _entryExercises.remove(entry.id);
    _draftRangeEntryIds.remove(entry.id);
    final ids = entry.sets.map((set) => set.id);
    _invalidSetIds.removeAll(ids);
    _untouchedRepSetIds.removeAll(ids);
  }

  void _removeSet(RoutineCompositionEntry entry, RoutineCompositionSet set) {
    if (!_enabled) return;
    if (entry.sets.length == 1) {
      // Removing the last Set removes this entire unsaved Exercise, instead
      // of leaving a nameless zero-Set Exercise behind.
      _removeEntry(entry);
      return;
    }
    if (_openSetId == set.id) _openSetId = null;
    _draft.removeSet(entry.id, set.id);
    _invalidSetIds.remove(set.id);
    _untouchedRepSetIds.remove(set.id);
  }

  void _addSet(RoutineCompositionEntry entry) {
    if (!_enabled) return;
    // The reference's Add Set is immediate: no modal or second confirmation.
    if (_openSetId != null) setState(() => _openSetId = null);
    final setId = _draft.addSet(entry.id, SetPrescription());
    if (setId != null) {
      _untouchedRepSetIds.add(setId);
    }
  }

  void _setOpen(String id, bool open) {
    if (!mounted) return;
    final next = open ? id : (_openSetId == id ? null : _openSetId);
    if (next != _openSetId) setState(() => _openSetId = next);
  }

  Future<void> _selectSetType(
    RoutineCompositionEntry entry,
    RoutineCompositionSet set,
  ) async {
    if (!_enabled) return;
    final chosen = await showTioEditorSheet<Object>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Select Set Type',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in RoutineSetType.values)
              ListTile(
                key: ValueKey('routine-type-option-${type.wireValue}'),
                leading: Text(switch (type) {
                  RoutineSetType.normal => '1',
                  RoutineSetType.warmUp => 'W',
                  RoutineSetType.failure => 'F',
                  RoutineSetType.drop => 'D',
                }),
                title: Text(switch (type) {
                  RoutineSetType.normal => 'Normal Set',
                  RoutineSetType.warmUp => 'Warm Up Set',
                  RoutineSetType.failure => 'Failure Set',
                  RoutineSetType.drop => 'Drop Set',
                }),
                trailing: type == set.prescription.setType
                    ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop<Object>(type),
              ),
            ListTile(
              key: const ValueKey('routine-type-remove-set'),
              leading: Icon(Icons.close, color: context.tioColors.danger),
              title: Text('Remove Set',
                style: TextStyle(color: context.tioColors.danger)),
              onTap: () => Navigator.of(sheetContext).pop<Object>('remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || !_enabled || chosen == null) return;
    if (chosen is RoutineSetType) {
      _draft.changeSetType(entry.id, set.id, chosen);
    } else if (chosen == 'remove') {
      _removeSet(entry, set);
    }
  }

  Future<void> _selectRepetitionMode(RoutineCompositionEntry entry) async {
    // Allow choosing the mode before entering any target Reps. Draft Save
    // remains guarded by _invalidSetIds until those fields are valid.
    if (!_enabled) return;
    final isRange = _draftRangeEntryIds.contains(entry.id) ||
        (entry.sets.isNotEmpty &&
         entry.sets.first.prescription.isRepRange);
    final chosen = await showTioEditorSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Repetition Options',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('routine-repetition-fixed'),
              title: const Text('Reps'),
              trailing: !isRange ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop<bool>(false),
            ),
            ListTile(
              key: const ValueKey('routine-repetition-range'),
              title: const Text('Rep Range'),
              trailing: isRange ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop<bool>(true),
            ),
          ],
        ),
      ),
    );
    if (!mounted || !_enabled || chosen == null) return;
    final current = _draft.state.entries.where((e) => e.id == entry.id);
    if (current.length != 1) return;
    // A nullable Set cannot encode a range choice until both bounds are
    // supplied. Keep this selection in UI state, never insert dummy 1 rep.
    if (chosen) {
      setState(() => _draftRangeEntryIds.add(entry.id));
    } else {
      setState(() => _draftRangeEntryIds.remove(entry.id));
      _draft.changeRepetitionMode(entry.id, range: false);
    }
  }

  bool get _rangeCanSave {
    for (final entry in _draft.state.entries) {
      if (!_draftRangeEntryIds.contains(entry.id)) {
        continue;
      }
      final hasFilledRange = entry.sets.any((s) => s.prescription.isRepRange);
      if (hasFilledRange &&
          entry.sets.any((s) => !s.prescription.isRepRange)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    if (!_draft.state.canSave || !_enabled ||
        _invalidSetIds.isNotEmpty || !_rangeCanSave) {
      return;
    }
    final confirmed = await _draft.save();
    if (confirmed && mounted) _closeConfirmed();
  }

  Future<void> _verify() async {
    final routines = widget.routineRepository;
    final compositions = widget.compositionRepository;
    if (routines == null || compositions == null) return;
    final confirmed = await _draft.reconcileUnknown(
      routines: routines, compositions: compositions,
    );
    if (confirmed && mounted) _closeConfirmed();
  }

  void _closeConfirmed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _draft.state.status == RoutineCreateStatus.saved) {
        Navigator.of(context).pop<bool>(true);
      }
    });
  }

  // An RPC can commit before its response is lost. A normal Cancel/Back must
  // not silently discard the frozen mutation and suggest that no write
  // happened. Leaving is deliberate, followed by an owner-scoped list refresh.
  Future<void> _confirmUnknownExit() async {
    if (!mounted || _unknownExitPromptOpen ||
        _draft.state.status != RoutineCreateStatus.outcomeUnknown) {
      return;
    }
    _unknownExitPromptOpen = true;
    try {
      final leave = await showTioConfirmationBottomSheet(
        context: context,
        cardKey: const ValueKey('create-routine-unknown-confirmation'),
        title: 'Routine save not confirmed',
        message: 'This Routine may already have been saved. Check your '
            'Program before creating another Routine.',
        cancelLabel: 'Keep verifying',
        confirmLabel: 'Exit to Program',
      );
      if (!mounted || leave != true ||
          _draft.state.status != RoutineCreateStatus.outcomeUnknown ||
          (widget.canWrite != null && !widget.canWrite!())) {
        return;
      }
      widget.onUnconfirmedExit?.call();
      Navigator.of(context).pop<bool>(false);
    } finally {
      _unknownExitPromptOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final status = _draft.state.status;
    final locked = status == RoutineCreateStatus.saving;
    final canSave = _enabled && _draft.state.canSave &&
        _invalidSetIds.isEmpty && _rangeCanSave;
    return PopScope(
      canPop: !locked && status != RoutineCreateStatus.outcomeUnknown,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && status == RoutineCreateStatus.outcomeUnknown) {
          unawaited(_confirmUnknownExit());
        }
      },
      child: Scaffold(
        key: const ValueKey('create-routine-page'),
        backgroundColor: colors.background,
        appBar: TioAppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          automaticallyImplyLeading: false,
          // The reference uses two visible text actions, not an icon-only
          // back button. Keep them inside the governed top bar so Cancel
          // cannot be clipped to Material's narrow leading-icon slot.
          title: Row(
            children: [
              TextButton(
                key: const ValueKey('create-routine-cancel'),
                onPressed: locked
                    ? null
                    : status == RoutineCreateStatus.outcomeUnknown
                        ? _confirmUnknownExit
                        : () => Navigator.of(context).pop<bool>(false),
                child: const Text('Cancel'),
              ),
              Expanded(
                child: Text(
                  'Create Routine',
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
              TextButton(
                key: const ValueKey('create-routine-save'),
                onPressed: canSave ? _save : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            key: const ValueKey('create-routine-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.lg, TioSpacing.xl,
                  TioSpacing.lg, TioSpacing.none,
                ),
                sliver: SliverList.list(children: [
                  TioInput(
                    key: const ValueKey('create-routine-name'),
                    controller: _name,
                    enabled: _enabled,
                    hint: 'Routine name',
                    textCapitalization: TextCapitalization.words,
                    onChanged: _draft.rename,
                  ),
                  const SizedBox(height: TioSpacing.xl),
                  if (_draft.state.entries.isEmpty) _empty(context),
                ]),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                sliver: SliverReorderableList(
                  key: const ValueKey('create-routine-exercise-reorder-list'),
                  itemCount: _draft.state.entries.length,
                  // SliverReorderableList lifts the dragged item into an
                  // Overlay. Give that proxy its own Material ancestor so
                  // embedded InkWell/IconButton actions remain valid there.
                  // Transparency preserves the approved card appearance.
                  proxyDecorator: (child, _, __) => Material(
                    type: MaterialType.transparency,
                    child: child,
                  ),
                  onReorderStart: (_) => unawaited(HapticFeedback.mediumImpact()),
                  onReorderEnd: (_) => unawaited(HapticFeedback.selectionClick()),
                  // SliverReorderableList supplies the already adjusted
                  // final destination index; controller persists identity.
                  onReorderItem: (from, to) {
                    if (_enabled) _draft.moveExercise(from, to);
                  },
                  itemBuilder: (context, position) =>
                      _exerciseCard(_draft.state.entries[position], position),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.lg, TioSpacing.none,
                  TioSpacing.lg, TioSpacing.xl,
                ),
                sliver: SliverList.list(children: [
              if (status == RoutineCreateStatus.verifying ||
                  status == RoutineCreateStatus.saving)
                Padding(
                  padding: const EdgeInsets.all(TioSpacing.lg),
                  child: Center(
                    child: Text(
                      status == RoutineCreateStatus.verifying
                          ? 'Verifying Custom Exercises'
                          : 'Saving Routine...',
                    ),
                  ),
                ),
              if (_draft.state.message != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TioSpacing.md,
                    ),
                    child: Text(
                      _draft.state.message!,
                      style: TextStyle(color: colors.danger),
                    ),
                  ),
                ),
              if (status == RoutineCreateStatus.outcomeUnknown)
                TioButton.secondary(
                  key: const ValueKey('create-routine-verify'),
                  label: 'Verify saved Routine',
                  onPressed: widget.routineRepository != null &&
                          widget.compositionRepository != null
                      ? _verify
                      : null,
                  expand: true,
                ),
              if (status == RoutineCreateStatus.ready) ...[
                const SizedBox(height: TioSpacing.md),
                TioButton.primary(
                  key: const ValueKey('create-routine-add-exercise'),
                  label: 'Add exercise',
                  expand: true,
                  onPressed: _enabled ? _pick : null,
                ),
              ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Padding(
        key: const ValueKey('create-routine-empty'),
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.fitness_center_outlined,
                size: TioSize.dp64, color: context.tioColors.textSecondary),
            const SizedBox(height: TioSpacing.xl),
            Text(
              'Get started by adding an exercise to your routine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.tioColors.textSecondary),
            ),
            const SizedBox(height: TioSpacing.xxl),
          ],
        ),
      );


  Widget _setRow(
    RoutineCompositionEntry entry,
    RoutineCompositionSet set,
    int index,
  ) =>
      RoutineSetInputRow(
        key: ValueKey('create-routine-set-${set.id}'),
        set: set,
        index: index,
        normalNumber: entry.sets
            .take(index + 1)
            .where((s) => s.prescription.setType == RoutineSetType.normal)
            .length,
        onTypePressed: () => _selectSetType(entry, set),
        unit: widget.weightUnit,
        enabled: _enabled,
        exerciseType: _entryExercises[entry.id]?.exerciseType,
        showRangeDraft: _draftRangeEntryIds.contains(entry.id),
        startWithBlankReps: _untouchedRepSetIds.contains(set.id),
        isOpen: _openSetId == set.id,
        onOpenChanged: (open) => _setOpen(set.id, open),
        onChanged: (prescription) {
          _untouchedRepSetIds.remove(set.id);
          _draft.editSet(entry.id, set.id, prescription);
        },
        onValidityChanged: (valid) => _validityChanged(set.id, valid),
        onRemove: () => _removeSet(entry, set),
      );

  void _moveExerciseFromSemantics(String entryId, int direction) {
    if (!_enabled) return;
    final from = _draft.state.entries.indexWhere((e) => e.id == entryId);
    if (from < 0) return;
    if (_draft.moveExercise(from, from + direction)) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  Widget _exerciseCard(RoutineCompositionEntry entry, int position) {
    final colors = context.tioColors;
    final unit = widget.weightUnit;
    final selected = _entryExercises[entry.id];
    final thumbnail = selected == null
        ? null
        : ExercisesController.thumbnailUrlFor(
            selected,
            gender: widget.viewerMediaGender,
          );
    final range = _draftRangeEntryIds.contains(entry.id) ||
        (entry.sets.isNotEmpty &&
         entry.sets.first.prescription.isRepRange);
    return Padding(
      key: ValueKey('create-routine-entry-${entry.id}'),
      padding: const EdgeInsets.only(bottom: TioSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (thumbnail != null)
                ExerciseThumbnail(url: thumbnail),
              Expanded(
                child: Semantics(
                  key: ValueKey('create-routine-reorder-semantics-${entry.id}'),
                  customSemanticsActions: _enabled
                      ? {
                          if (position > 0)
                            const CustomSemanticsAction(
                              label: 'Move exercise up',
                            ): () => _moveExerciseFromSemantics(entry.id, -1),
                          if (position < _draft.state.entries.length - 1)
                            const CustomSemanticsAction(
                              label: 'Move exercise down',
                            ): () => _moveExerciseFromSemantics(entry.id, 1),
                        }
                      : const {},
                  child: ReorderableDelayedDragStartListener(
                    key: ValueKey('create-routine-drag-${entry.id}'),
                    index: position,
                    enabled: _enabled,
                    child: ColoredBox(
                      color: TioPalette.transparent,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: kMinInteractiveDimension,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selected?.displayName ?? 'Selected Exercise',
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
                key: ValueKey('create-routine-options-${entry.id}'),
                tooltip: 'Exercise options',
                onPressed: _enabled ? () => _showExerciseOptions(entry) : null,
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.md),
          Row(
            children: [
              const SizedBox(
                width: TioSize.dp44,
                child: Text('SET', textAlign: TextAlign.center),
              ),
              const SizedBox(width: TioSpacing.sm),
              if (selected?.exerciseType == ExerciseType.distanceDuration) ...[
                const Expanded(child: Text('KM', textAlign: TextAlign.center)),
                const SizedBox(width: TioSpacing.sm),
                const Expanded(child: Text('TIME', textAlign: TextAlign.center)),
              ] else if (selected?.exerciseType == ExerciseType.duration) ...[
                const Expanded(child: Text('TIME', textAlign: TextAlign.center)),
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
                      key: ValueKey('create-routine-repetition-options-${entry.id}'),
                      onTap: _enabled ? () => _selectRepetitionMode(entry) : null,
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
          for (var i = 0; i < entry.sets.length; i++)
            _setRow(entry, entry.sets[i], i),
          TioButton.supporting(
            key: ValueKey('create-routine-add-set-${entry.id}'),
            label: 'Add Set',
            leading: const Icon(Icons.add),
            expand: true,
            onPressed: _enabled ? () => _addSet(entry) : null,
          ),
        ],
      ),
    );
  }
}
