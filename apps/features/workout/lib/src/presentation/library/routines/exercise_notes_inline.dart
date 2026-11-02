import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_notes_repository.dart';
import 'routine_notes_controller.dart';
import 'routine_notes_save_bridge.dart';

final _canonicalOwnerId = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const _maxInlineNotes = 4;

final class _ExerciseNoteDraft {
  _ExerciseNoteDraft({
    required this.id,
    required this.onChanged,
    String text = '',
    this.type = RoutineNoteType.pinnedExercise,
  })  : controller = TextEditingController(text: text),
        focusNode = FocusNode() {
    controller.addListener(onChanged);
  }

  final String id;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  RoutineNoteType type;

  void dispose() {
    controller.removeListener(onChanged);
    focusNode.dispose();
    controller.dispose();
  }
}

/// Inline Exercise Notes surface shared by the Create and Edit Routine cards.
///
/// The draft is local until the surrounding Routine is saved. The Exercise
/// scope is canonical and therefore reusable across the owner's Routines
/// without copying a Routine identity into the Note.
final class ExerciseNotesInline extends StatefulWidget {
  const ExerciseNotesInline({
    required this.exerciseRef,
    required this.routineId,
    required this.restControl,
    required this.repository,
    required this.ownerId,
    required this.isSessionCurrent,
    required this.enabled,
    this.draftKey,
    this.initialDrafts = const [],
    this.onDraftsChanged,
    this.controllerRegistry,
    super.key,
  });

  final ExerciseRef exerciseRef;
  final RoutineId? routineId;
  final Widget restControl;
  final RoutineNotesRepository? repository;
  final String? ownerId;
  final RoutineNotesSessionIsCurrent? isSessionCurrent;
  final bool enabled;
  final String? draftKey;
  final List<ExerciseNoteDraftSnapshot> initialDrafts;
  final ValueChanged<List<ExerciseNoteDraftSnapshot>>? onDraftsChanged;
  final RoutineNotesControllerRegistry? controllerRegistry;

  @override
  State<ExerciseNotesInline> createState() => _ExerciseNotesInlineState();
}

final class _ExerciseNotesInlineState extends State<ExerciseNotesInline>
    with AutomaticKeepAliveClientMixin<ExerciseNotesInline> {
  RoutineNotesController? _controller;
  var _controllerOwned = false;
  final List<_ExerciseNoteDraft> _drafts = [];
  late RoutineNoteScope _scope;
  var _draftSequence = 0;

  @override
  bool get wantKeepAlive => true;

  bool get _available =>
      widget.repository != null &&
      widget.ownerId != null &&
      _canonicalOwnerId.hasMatch(widget.ownerId!) &&
      widget.isSessionCurrent != null;

  bool get _previewOnly =>
      kDebugMode &&
      (!_available || _controller?.state.status == RoutineNotesStatus.failed);

  @override
  void initState() {
    super.initState();
    _scope = RoutineNoteScope.exercise(widget.exerciseRef);
    _restoreDrafts();
    _bind();
  }

  @override
  void didUpdateWidget(covariant ExerciseNotesInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseRef != widget.exerciseRef ||
        oldWidget.draftKey != widget.draftKey ||
        !identical(oldWidget.repository, widget.repository) ||
        !identical(oldWidget.controllerRegistry, widget.controllerRegistry) ||
        oldWidget.ownerId != widget.ownerId ||
        (oldWidget.isSessionCurrent == null) !=
            (widget.isSessionCurrent == null)) {
      _disposeDrafts();
      _restoreDrafts();
      _publishDrafts();
      _scope = RoutineNoteScope.exercise(widget.exerciseRef);
      _bind();
    } else if (!identical(
        oldWidget.isSessionCurrent, widget.isSessionCurrent)) {
      final callback = widget.isSessionCurrent;
      if (callback != null) {
        _controller?.updateSessionIsCurrent(callback);
      }
    }
  }

  void _bind({RoutineNoteScope? scope}) {
    _releaseController();
    _controller = null;
    _controllerOwned = false;
    if (!_available) return;
    if (scope != null) _scope = scope;

    final controller = widget.controllerRegistry?.controllerFor(
          scope: _scope,
          repository: widget.repository!,
          ownerId: widget.ownerId!,
          isSessionCurrent: widget.isSessionCurrent!,
        ) ??
        RoutineNotesController.forScope(
          scope: _scope,
          repository: widget.repository!,
          ownerId: widget.ownerId!,
          isSessionCurrent: widget.isSessionCurrent!,
        );
    controller.addListener(_changed);
    _controller = controller;
    _controllerOwned = widget.controllerRegistry == null;
    if (widget.controllerRegistry == null) unawaited(controller.load());
  }

  void _releaseController() {
    final controller = _controller;
    if (controller == null) return;
    controller.removeListener(_changed);
    if (_controllerOwned) controller.dispose();
    _controllerOwned = false;
  }

  void _publishDrafts() {
    final callback = widget.onDraftsChanged;
    if (callback == null) return;
    callback([
      for (final draft in _drafts)
        ExerciseNoteDraftSnapshot(
          draftId: _publishedDraftId(draft.id),
          exerciseRef: widget.exerciseRef,
          type: draft.type,
          body: draft.controller.text,
        ),
    ]);
  }

  Future<void> _changeDraftType(int index) async {
    final draft = _drafts[index];
    final selection = await _chooseType(
      context,
      draft.type,
      widget.routineId,
      allowDelete: true,
    );
    if (!mounted || selection == null) return;
    if (selection is _DeleteNoteSelection) {
      _deleteDraft(index);
      return;
    }
    if (selection is! RoutineNoteType || selection == draft.type) return;
    final type = selection;
    final routineId = widget.routineId;
    if (type == RoutineNoteType.pinnedRoutine && routineId == null) return;
    draft.type = type;
    setState(() {});
    _publishDrafts();
  }

  void _deleteDraft(int index) {
    final draft = _drafts.removeAt(index);
    draft.dispose();
    setState(() {});
    _publishDrafts();
  }

  Future<void> _changeSavedType(RoutineNote note) async {
    final selection = await _chooseType(
      context,
      note.type,
      widget.routineId,
      allowDelete: true,
    );
    if (!mounted || selection == null) return;
    if (selection is _DeleteNoteSelection) {
      await _delete(note);
      return;
    }
    if (selection is! RoutineNoteType || selection == note.type) return;
    final routineId = widget.routineId;
    if (selection == RoutineNoteType.pinnedRoutine && routineId == null) {
      return;
    }
    final destination = selection == RoutineNoteType.pinnedRoutine
        ? RoutineNoteScope.routine(routineId!)
        : RoutineNoteScope.exercise(widget.exerciseRef);
    await _controller?.transfer(note, destination);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _focusDraft() {
    final controller = _controller;
    if (!widget.enabled ||
        (!_previewOnly && (controller == null || !controller.canCreate))) {
      return;
    }
    final savedCount = controller?.state.notes.length ?? 0;
    if (savedCount + _drafts.length >= _maxInlineNotes) return;
    var id = '$_draftSequence';
    while (_drafts.any((draft) => draft.id == id)) {
      _draftSequence++;
      id = '$_draftSequence';
    }
    _draftSequence++;
    final draft = _ExerciseNoteDraft(id: id, onChanged: _publishDrafts);
    _drafts.add(draft);
    setState(() {});
    _publishDrafts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      draft.focusNode.requestFocus();
      Scrollable.ensureVisible(
        draft.focusNode.context ?? context,
        alignment: 0.25,
        duration: context.tioMotion.fast,
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> _delete(RoutineNote note) async {
    final controller = _controller;
    final isCurrent = widget.isSessionCurrent;
    if (controller == null ||
        controller.isBusy ||
        isCurrent == null ||
        !isCurrent()) {
      return false;
    }
    final isRoutine = note.type == RoutineNoteType.pinnedRoutine;
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: isRoutine ? 'Delete Routine Note?' : 'Delete Exercise Note?',
      message: isRoutine
          ? 'This note will be removed from this Routine.'
          : 'This note will be removed from this Exercise everywhere in your Routines.',
      confirmLabel: 'Delete Note',
      cancelLabel: 'Cancel',
      intent: TioConfirmationIntent.destructive,
    );
    if (confirmed != true || !mounted || !isCurrent()) return false;
    return controller.delete(note);
  }

  Future<void> _refresh() async {
    final controller = _controller;
    final isCurrent = widget.isSessionCurrent;
    if (controller == null || controller.isBusy || isCurrent == null) return;
    if (!isCurrent()) return;
    await controller.load();
  }

  @override
  void dispose() {
    _releaseController();
    _disposeDrafts();
    super.dispose();
  }

  void _disposeDrafts() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = _controller;
    final state = controller?.state;
    final notes = state?.notes ?? const <RoutineNote>[];
    final actionNotice = state?.actionNotice;
    final canCreate =
        widget.enabled && (_previewOnly || controller?.canCreate == true);
    final canAddDraft =
        canCreate && notes.length + _drafts.length < _maxInlineNotes;
    final canEditDraft = widget.enabled &&
        (_previewOnly || controller?.state.status != RoutineNotesStatus.failed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(child: widget.restControl),
            const SizedBox(width: TioSpacing.sm),
            _ExerciseNoteAction(
              key: ValueKey('exercise-note-action-${widget.exerciseRef.value}'),
              enabled: canAddDraft,
              onPressed: _focusDraft,
            ),
          ],
        ),
        const SizedBox(height: TioSpacing.sm),
        ...[
          if (notes.isNotEmpty)
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: TioSpacing.sm),
                child: _ExerciseNoteCard(
                  key: ValueKey('exercise-note-${note.id}'),
                  enabled: widget.enabled && controller?.isBusy != true,
                  onDelete: () => _delete(note),
                  child: _ExerciseNoteSwipeRow(
                    key: ValueKey('exercise-note-swipe-${note.id}'),
                    enabled: widget.enabled && controller?.isBusy != true,
                    onDelete: () => _delete(note),
                    onTypeChange: () => _changeSavedType(note),
                    child: _ExerciseNoteCardContent(
                      note: note,
                      enabled: widget.enabled && controller?.isBusy != true,
                      onTypeChange: () => _changeSavedType(note),
                    ),
                  ),
                ),
              ),
          for (var index = 0; index < _drafts.length; index++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: TioSpacing.sm),
              child: _ExerciseNoteDraftField(
                fieldKey: ValueKey(_draftInputKey(index)),
                typeKey: ValueKey(_draftTypeKey(index)),
                iconKey: ValueKey(_draftIconKey(index)),
                controller: _drafts[index].controller,
                focusNode: _drafts[index].focusNode,
                enabled: canEditDraft,
                noteType: _drafts[index].type,
                onTypeChange:
                    canEditDraft ? () => _changeDraftType(index) : null,
              ),
            ),
          ],
          if (actionNotice != null)
            _ExerciseNotesNotice(
              text: actionNotice,
              onRefresh: controller == null ? null : _refresh,
            ),
          if (state?.isReady == true && notes.length >= _maxInlineNotes)
            Padding(
              padding: const EdgeInsets.only(top: TioSpacing.xs),
              child: Text(
                'Maximum $_maxInlineNotes active Notes reached.',
                style: TextStyle(color: context.tioColors.textSecondary),
              ),
            ),
        ],
        const SizedBox(height: TioSpacing.sm),
      ],
    );
  }

  String _publishedDraftId(String id) {
    final prefix = '${widget.draftKey ?? widget.exerciseRef.value}:';
    return id.startsWith(prefix) ? id : '$prefix$id';
  }

  void _restoreDrafts() {
    for (final snapshot in widget.initialDrafts) {
      _drafts.add(
        _ExerciseNoteDraft(
          id: snapshot.draftId,
          text: snapshot.body,
          type: snapshot.type,
          onChanged: _publishDrafts,
        ),
      );
    }
    _draftSequence = _drafts.length;
  }

  String _draftInputKey(int index) => index == 0
      ? 'exercise-note-input-${widget.exerciseRef.value}'
      : 'exercise-note-input-${widget.exerciseRef.value}-$index';

  String _draftTypeKey(int index) => index == 0
      ? 'exercise-note-draft-type'
      : 'exercise-note-draft-type-$index';

  String _draftIconKey(int index) => index == 0
      ? 'exercise-note-draft-type-icon'
      : 'exercise-note-draft-type-icon-$index';
}

final class _ExerciseNoteDraftField extends StatelessWidget {
  const _ExerciseNoteDraftField({
    required this.fieldKey,
    required this.typeKey,
    required this.iconKey,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.noteType,
    required this.onTypeChange,
  });

  final Key fieldKey;
  final Key typeKey;
  final Key iconKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final RoutineNoteType noteType;
  final VoidCallback? onTypeChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              enabled: onTypeChange != null,
              label: 'Change note type',
              child: InkWell(
                key: typeKey,
                borderRadius: BorderRadius.circular(TioRadius.full),
                onTap: onTypeChange,
                child: SizedBox(
                  width: TioSize.dp24,
                  height: TioSize.dp24,
                  child: Icon(
                    _noteTypeIcon(noteType),
                    key: iconKey,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              child: TextField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 1,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                textAlignVertical: TextAlignVertical.top,
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                ),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: 'Add a pinned exercise note',
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

IconData _noteTypeIcon(RoutineNoteType type) => switch (type) {
      RoutineNoteType.pinnedExercise => Icons.push_pin_outlined,
      RoutineNoteType.pinnedRoutine => Icons.assignment_outlined,
    };

final class _ExerciseNoteAction extends StatelessWidget {
  const _ExerciseNoteAction({
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Note',
      child: Material(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(TioRadius.full),
        child: InkWell(
          borderRadius: BorderRadius.circular(TioRadius.full),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.md,
              vertical: TioSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.note_add_outlined,
                  size: TioSize.dp16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: TioSpacing.xs),
                Text(
                  'Note',
                  style: TextStyle(
                    fontSize: TioFontSize.size13,
                    fontWeight: TioFontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ExerciseNotesNotice extends StatelessWidget {
  const _ExerciseNotesNotice({required this.text, this.onRefresh});

  final String text;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: TioSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text,
                style: TextStyle(color: context.tioColors.textSecondary)),
            if (onRefresh != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const ValueKey('exercise-notes-refresh'),
                  onPressed: () => onRefresh!(),
                  child: const Text('Refresh'),
                ),
              ),
          ],
        ),
      );
}

final class _ExerciseNoteCard extends StatelessWidget {
  const _ExerciseNoteCard({
    required this.enabled,
    required this.onDelete,
    required this.child,
    super.key,
  });

  final bool enabled;
  final Future<bool> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        customSemanticsActions: enabled
            ? {
                const CustomSemanticsAction(label: 'Delete note'): () async {
                  await onDelete();
                },
              }
            : const {},
        child: child,
      );
}

final class _ExerciseNoteCardContent extends StatelessWidget {
  const _ExerciseNoteCardContent({
    required this.note,
    required this.enabled,
    required this.onTypeChange,
  });

  final RoutineNote note;
  final bool enabled;
  final VoidCallback onTypeChange;

  @override
  Widget build(BuildContext context) => TioCard(
        variant: TioCardVariant.outlined,
        padding: const EdgeInsetsDirectional.fromSTEB(
          TioSpacing.md,
          TioSpacing.sm,
          TioSpacing.xs,
          TioSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              key: ValueKey('exercise-note-type-${note.id}'),
              tooltip: 'Change note type',
              onPressed: enabled ? onTypeChange : null,
              icon: Icon(_noteTypeIcon(note.type)),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              child: Semantics(
                label: 'Exercise note: ${note.body}',
                child: Text(note.body,
                    style: TextStyle(color: context.tioColors.textPrimary)),
              ),
            ),
          ],
        ),
      );
}

final class _ExerciseNoteSwipeRow extends StatefulWidget {
  const _ExerciseNoteSwipeRow({
    required this.enabled,
    required this.onDelete,
    required this.onTypeChange,
    required this.child,
    super.key,
  });

  final bool enabled;
  final Future<bool> Function() onDelete;
  final Future<void> Function() onTypeChange;
  final Widget child;

  @override
  State<_ExerciseNoteSwipeRow> createState() => _ExerciseNoteSwipeRowState();
}

final class _ExerciseNoteSwipeRowState extends State<_ExerciseNoteSwipeRow> {
  static const double _revealWidth =
      TioSize.dp64 + TioSpacing.xl + TioSpacing.md;
  static const double _openThreshold = _revealWidth / 2;
  double _offset = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _offset = (_offset - details.delta.dx).clamp(-_revealWidth, _revealWidth);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 200 || _offset <= -_openThreshold) {
      unawaited(_changeType());
      return;
    }
    final open = velocity < -200 || _offset >= _openThreshold;
    setState(() => _offset = open ? _revealWidth : 0);
  }

  Future<void> _delete() async {
    if (!widget.enabled || _offset == 0) return;
    final deleted = await widget.onDelete();
    if (mounted && !deleted) setState(() => _offset = 0);
  }

  Future<void> _changeType() async {
    if (!widget.enabled || _offset >= 0) return;
    setState(() => _offset = 0);
    await widget.onTypeChange();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        customSemanticsActions: widget.enabled
            ? {
                const CustomSemanticsAction(label: 'Delete note'): () {
                  unawaited(widget.onDelete());
                },
                const CustomSemanticsAction(label: 'Change note type'): () {
                  unawaited(widget.onTypeChange());
                },
              }
            : const {},
        child: Stack(
          children: [
            Positioned.fill(
              child: Material(
                color: context.tioColors.danger,
                child: InkWell(
                  onTap: _offset == 0 ? null : _delete,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: TioSpacing.lg,
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(fontWeight: TioFontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-_offset, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: widget.child,
              ),
            ),
          ],
        ),
      );
}

final class _DeleteNoteSelection {
  const _DeleteNoteSelection();
}

const _deleteNoteSelection = _DeleteNoteSelection();

Future<Object?> _chooseType(
        BuildContext context, RoutineNoteType current, RoutineId? routineId,
        {bool allowDelete = false}) =>
    showTioEditorSheet<Object?>(
      context: context,
      useSafeArea: true,
      builder: (_) => _ExerciseNoteTypeSheet(
        current: current,
        routineId: routineId,
        allowDelete: allowDelete,
      ),
    );

final class _ExerciseNoteTypeSheet extends StatelessWidget {
  const _ExerciseNoteTypeSheet({
    required this.current,
    required this.routineId,
    required this.allowDelete,
  });

  final RoutineNoteType current;
  final RoutineId? routineId;
  final bool allowDelete;

  @override
  Widget build(BuildContext context) => TioEditorSheet(
        key: const ValueKey('exercise-note-type-sheet'),
        title: 'Notes type',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExerciseNoteTypeOption(
              key: const ValueKey('exercise-note-type-exercise'),
              title: 'Pinned Exercise Note',
              subtitle:
                  'Appears every time you log this exercise. Hidden from workout posts.',
              icon: Icons.push_pin_outlined,
              selected: current == RoutineNoteType.pinnedExercise,
              onTap: () =>
                  Navigator.of(context).pop(RoutineNoteType.pinnedExercise),
            ),
            if (routineId != null) ...[
              const SizedBox(height: TioSpacing.sm),
              _ExerciseNoteTypeOption(
                key: const ValueKey('exercise-note-type-routine'),
                title: 'Pinned Routine Note',
                subtitle:
                    'Appears every time you log this routine. Hidden from workout posts.',
                icon: Icons.assignment_outlined,
                selected: current == RoutineNoteType.pinnedRoutine,
                onTap: () =>
                    Navigator.of(context).pop(RoutineNoteType.pinnedRoutine),
              ),
            ],
            if (allowDelete) ...[
              const SizedBox(height: TioSpacing.sm),
              TioCard(
                key: const ValueKey('exercise-note-delete'),
                variant: TioCardVariant.outlined,
                onTap: () => Navigator.of(context).pop(_deleteNoteSelection),
                padding: const EdgeInsets.all(TioSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: context.tioColors.danger,
                    ),
                    const SizedBox(width: TioSpacing.md),
                    Text(
                      'Delete Note',
                      style: TextStyle(color: context.tioColors.danger),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

final class _ExerciseNoteTypeOption extends StatelessWidget {
  const _ExerciseNoteTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TioCard(
        variant: TioCardVariant.outlined,
        onTap: onTap,
        padding: const EdgeInsets.all(TioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: TioSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (selected) const Icon(Icons.check),
              ],
            ),
            const SizedBox(height: TioSpacing.xs),
            Text(
              subtitle,
              style: TextStyle(color: context.tioColors.textSecondary),
            ),
          ],
        ),
      );
}
