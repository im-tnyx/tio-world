import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_notes_repository.dart';
import 'routine_notes_controller.dart';

/// Inline Exercise Notes surface shared by the Create and Edit Routine cards.
///
/// The draft is local until the explicit inline Save action is pressed. The
/// Exercise scope is canonical and therefore reusable across the owner's
/// Routines without copying a Routine identity into the Note.
final class ExerciseNotesInline extends StatefulWidget {
  const ExerciseNotesInline({
    required this.exerciseRef,
    required this.routineId,
    required this.restControl,
    required this.repository,
    required this.ownerId,
    required this.isSessionCurrent,
    required this.enabled,
    super.key,
  });

  final ExerciseRef exerciseRef;
  final RoutineId? routineId;
  final Widget restControl;
  final RoutineNotesRepository? repository;
  final String? ownerId;
  final RoutineNotesSessionIsCurrent? isSessionCurrent;
  final bool enabled;

  @override
  State<ExerciseNotesInline> createState() => _ExerciseNotesInlineState();
}

final class _ExerciseNotesInlineState extends State<ExerciseNotesInline> {
  RoutineNotesController? _controller;
  late final TextEditingController _draft;
  late final FocusNode _focusNode;
  late RoutineNoteScope _scope;
  String? _errorText;
  bool _showDraftActions = false;

  bool get _available =>
      widget.repository != null &&
      widget.ownerId != null &&
      widget.isSessionCurrent != null;

  @override
  void initState() {
    super.initState();
    _draft = TextEditingController();
    _focusNode = FocusNode()..addListener(_focusChanged);
    _scope = RoutineNoteScope.exercise(widget.exerciseRef);
    _bind();
  }

  @override
  void didUpdateWidget(covariant ExerciseNotesInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseRef != widget.exerciseRef ||
        !identical(oldWidget.repository, widget.repository) ||
        oldWidget.ownerId != widget.ownerId ||
        oldWidget.routineId != widget.routineId ||
        oldWidget.isSessionCurrent != widget.isSessionCurrent) {
      _draft.clear();
      _errorText = null;
      _showDraftActions = false;
      _focusNode.unfocus();
      _scope = RoutineNoteScope.exercise(widget.exerciseRef);
      _bind();
    }
  }

  void _bind({RoutineNoteScope? scope}) {
    _controller
      ?..removeListener(_changed)
      ..dispose();
    _controller = null;
    if (!_available) return;
    if (scope != null) _scope = scope;

    final controller = RoutineNotesController.forScope(
      scope: _scope,
      repository: widget.repository!,
      ownerId: widget.ownerId!,
      isSessionCurrent: widget.isSessionCurrent!,
    )..addListener(_changed);
    _controller = controller;
    unawaited(controller.load());
  }

  Future<void> _changeDraftType() async {
    final type = await _chooseType(context, _scope.type, widget.routineId);
    if (!mounted || type == null || type == _scope.type) return;
    final routineId = widget.routineId;
    if (type == RoutineNoteType.pinnedRoutine && routineId == null) return;
    final next = type == RoutineNoteType.pinnedRoutine
        ? RoutineNoteScope.routine(routineId!)
        : RoutineNoteScope.exercise(widget.exerciseRef);
    _bind(scope: next);
    setState(() {
      _errorText = null;
      _showDraftActions = _draft.text.isNotEmpty || _focusNode.hasFocus;
    });
  }

  Future<void> _changeSavedType(RoutineNote note) async {
    final type = await _chooseType(context, note.type, widget.routineId);
    if (!mounted || type == null || type == note.type) return;
    final routineId = widget.routineId;
    if (type == RoutineNoteType.pinnedRoutine && routineId == null) return;
    final destination = type == RoutineNoteType.pinnedRoutine
        ? RoutineNoteScope.routine(routineId!)
        : RoutineNoteScope.exercise(widget.exerciseRef);
    await _controller?.transfer(note, destination);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _focusChanged() {
    if (!mounted) return;
    setState(() =>
        _showDraftActions = _focusNode.hasFocus || _draft.text.isNotEmpty);
  }

  void _focusDraft() {
    final controller = _controller;
    if (!widget.enabled || controller == null || !controller.canCreate) return;
    setState(() => _showDraftActions = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      Scrollable.ensureVisible(
        context,
        alignment: 0.25,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _cancelDraft() {
    _draft.clear();
    _focusNode.unfocus();
    setState(() {
      _errorText = null;
      _showDraftActions = false;
    });
  }

  Future<void> _saveDraft() async {
    final controller = _controller;
    if (controller == null ||
        !controller.canCreate ||
        !_validBody(_draft.text)) {
      setState(() => _errorText = _validBody(_draft.text)
          ? _actionError(controller?.state.failure)
          : 'Enter a note before saving.');
      return;
    }
    setState(() => _errorText = null);
    final saved = await controller.create(_draft.text);
    if (!mounted) return;
    if (saved) {
      _draft.clear();
      _focusNode.unfocus();
      setState(() => _showDraftActions = false);
      return;
    }
    if (!controller.hasPendingMutation) {
      setState(() => _errorText = _actionError(controller.state.failure));
    }
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
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Delete Exercise Note?',
      message:
          'This note will be removed from this Exercise everywhere in your Routines.',
      confirmLabel: 'Delete Note',
      cancelLabel: 'Cancel',
      intent: TioConfirmationIntent.destructive,
    );
    if (confirmed != true || !mounted || !isCurrent()) return false;
    return controller.delete(note);
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_changed)
      ..dispose();
    _focusNode
      ..removeListener(_focusChanged)
      ..dispose();
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return widget.restControl;
    final controller = _controller;
    final state = controller?.state;
    final canCreate = widget.enabled && controller?.canCreate == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: TioSpacing.sm,
          runSpacing: TioSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            widget.restControl,
            TioButton.secondary(
              key: ValueKey('exercise-note-action-${widget.exerciseRef.value}'),
              label: 'Note',
              leading: const Icon(Icons.note_add_outlined),
              enabled: canCreate,
              onPressed: _focusDraft,
            ),
          ],
        ),
        const SizedBox(height: TioSpacing.sm),
        if (state == null || state.isLoading)
          const _ExerciseNotesPlaceholder(
            key: ValueKey('exercise-notes-loading'),
            loading: true,
          )
        else if (state.status == RoutineNotesStatus.failed)
          _ExerciseNotesFailure(
            key: const ValueKey('exercise-notes-failed'),
            message: _failureMessage(state.failure),
            notice: state.actionNotice,
            onRetry:
                controller?.isBusy == true ? null : () => controller?.load(),
          )
        else ...[
          if (state.notes.isNotEmpty)
            for (final note in state.notes)
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
          TioInput.multiline(
            key: ValueKey('exercise-note-input-${widget.exerciseRef.value}'),
            controller: _draft,
            focusNode: _focusNode,
            leading: GestureDetector(
              key: const ValueKey('exercise-note-draft-type'),
              onTap: canCreate ? _changeDraftType : null,
              child: Icon(Icons.push_pin_outlined,
                  color: context.tioColors.textSecondary),
            ),
            hint: 'Add a pinned exercise note',
            minLines: 1,
            maxLines: 4,
            maxLength: 500,
            errorText: _errorText,
            enabled: canCreate,
            onChanged: (_) {
              setState(() {
                if (_errorText != null) _errorText = null;
              });
            },
          ),
          if (state.actionNotice != null)
            _ExerciseNotesNotice(text: state.actionNotice!),
          if (state.notes.isEmpty && !canCreate)
            Padding(
              padding: const EdgeInsets.only(top: TioSpacing.xs),
              child: Text(
                'Maximum 5 active Exercise Notes reached.',
                style: TextStyle(color: context.tioColors.textSecondary),
              ),
            ),
          if (_showDraftActions)
            Padding(
              padding: const EdgeInsets.only(top: TioSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TioButton.secondary(
                      key: const ValueKey('exercise-note-cancel'),
                      label: 'Cancel',
                      enabled: controller?.isBusy != true,
                      onPressed: _cancelDraft,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: TioButton.primary(
                      key: const ValueKey('exercise-note-save'),
                      label: 'Save Note',
                      enabled: canCreate && _validBody(_draft.text),
                      loading: controller?.isBusy == true,
                      loadingLabel: 'Saving...',
                      onPressed: _saveDraft,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: TioSpacing.sm),
      ],
    );
  }
}

final class _ExerciseNotesPlaceholder extends StatelessWidget {
  const _ExerciseNotesPlaceholder({required this.loading, super.key});

  final bool loading;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(Icons.push_pin_outlined,
              size: TioSize.dp20, color: context.tioColors.textSecondary),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: Text(
              'Add a pinned exercise note',
              style: TextStyle(color: context.tioColors.textSecondary),
            ),
          ),
          if (loading)
            const SizedBox(
              width: TioSize.dp16,
              height: TioSize.dp16,
              child: CircularProgressIndicator(strokeWidth: TioStroke.width2),
            ),
        ],
      );
}

final class _ExerciseNotesFailure extends StatelessWidget {
  const _ExerciseNotesFailure({
    required this.message,
    required this.notice,
    required this.onRetry,
    super.key,
  });

  final String message;
  final String? notice;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: TextStyle(color: context.tioColors.danger)),
          if (notice != null)
            Text(notice!,
                style: TextStyle(color: context.tioColors.textSecondary)),
          TioButton.secondary(
            key: const ValueKey('exercise-notes-retry'),
            label: 'Retry',
            onPressed: onRetry,
          ),
        ],
      );
}

final class _ExerciseNotesNotice extends StatelessWidget {
  const _ExerciseNotesNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: TioSpacing.xs),
        child: Text(text,
            style: TextStyle(color: context.tioColors.textSecondary)),
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
              icon: const Icon(Icons.push_pin_outlined),
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

Future<RoutineNoteType?> _chooseType(
  BuildContext context,
  RoutineNoteType current,
  RoutineId? routineId,
) =>
    showTioEditorSheet<RoutineNoteType>(
      context: context,
      useSafeArea: true,
      builder: (_) => _ExerciseNoteTypeSheet(
        current: current,
        routineId: routineId,
      ),
    );

final class _ExerciseNoteTypeSheet extends StatelessWidget {
  const _ExerciseNoteTypeSheet({
    required this.current,
    required this.routineId,
  });

  final RoutineNoteType current;
  final RoutineId? routineId;

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
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: TioSpacing.xs),
                  Text(subtitle,
                      style: TextStyle(color: context.tioColors.textSecondary)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check),
          ],
        ),
      );
}

bool _validBody(String value) {
  try {
    RoutineNote.normalizeBody(value);
    return true;
  } on ArgumentError {
    return false;
  }
}

String _failureMessage(RoutineNoteFailureKind? failure) => switch (failure) {
      RoutineNoteFailureKind.unauthorized =>
        'Notes are unavailable for this session.',
      RoutineNoteFailureKind.forbidden => 'You cannot access these Notes.',
      RoutineNoteFailureKind.quotaExceeded =>
        'Maximum 5 active Exercise Notes reached.',
      RoutineNoteFailureKind.invalidRequest => 'Enter 1-500 characters.',
      RoutineNoteFailureKind.malformedData =>
        'Notes data could not be verified.',
      _ => 'Exercise Notes are temporarily unavailable.',
    };

String _actionError(RoutineNoteFailureKind? failure) =>
    _failureMessage(failure);
