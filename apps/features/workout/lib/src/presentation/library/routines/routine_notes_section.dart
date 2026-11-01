import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_notes_repository.dart';
import 'routine_notes_controller.dart';

/// Routine-level Notes surface for Routine Detail.
///
/// Exercise Notes, editing and transfer deliberately remain outside this first
/// UI slice. The section owns only presentation and delegates all persistence
/// and session safety to [RoutineNotesController].
final class RoutineNotesSection extends StatefulWidget {
  const RoutineNotesSection({
    required this.routineId,
    required this.repository,
    required this.ownerId,
    required this.isSessionCurrent,
    super.key,
  });

  final RoutineId routineId;
  final RoutineNotesRepository repository;
  final String ownerId;
  final RoutineNotesSessionIsCurrent isSessionCurrent;

  @override
  State<RoutineNotesSection> createState() => _RoutineNotesSectionState();
}

final class _RoutineNotesSectionState extends State<RoutineNotesSection> {
  RoutineNotesController? _controller;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant RoutineNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routineId != widget.routineId ||
        !identical(oldWidget.repository, widget.repository) ||
        oldWidget.ownerId != widget.ownerId) {
      _bind();
    }
  }

  void _bind() {
    _controller
      ?..removeListener(_changed)
      ..dispose();
    final controller = RoutineNotesController(
      routineId: widget.routineId,
      repository: widget.repository,
      ownerId: widget.ownerId,
      isSessionCurrent: widget.isSessionCurrent,
    )..addListener(_changed);
    _controller = controller;
    controller.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> _openComposer() async {
    final controller = _controller;
    if (controller == null ||
        !controller.canCreate ||
        !widget.isSessionCurrent()) {
      return;
    }

    final draft = TextEditingController();
    Timer? sessionGuard;
    StateSetter? setSheetState;
    BuildContext? modalContext;
    var saving = false;
    var sessionActive = true;
    String? errorText;

    void invalidateSession() {
      if (!sessionActive) return;
      sessionActive = false;
      setSheetState?.call(() {});
      final routeContext = modalContext;
      final route = routeContext == null ? null : ModalRoute.of(routeContext);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentContext = routeContext;
        if (currentContext == null ||
            !currentContext.mounted ||
            route == null ||
            !route.isActive) {
          return;
        }
        Navigator.of(currentContext).removeRoute(route);
      });
    }

    void checkSession() {
      try {
        if (!widget.isSessionCurrent()) invalidateSession();
      } catch (_) {
        invalidateSession();
      }
    }

    try {
      await showTioEditorSheet<bool>(
        context: context,
        useSafeArea: true,
        isDismissible: false,
        builder: (builderContext) => StatefulBuilder(
          builder: (context, setState) {
            modalContext = builderContext;
            setSheetState = setState;
            sessionGuard ??= Timer.periodic(
              const Duration(milliseconds: TioDuration.ms90),
              (_) => checkSession(),
            );
            if (!sessionActive) return const SizedBox.shrink();
            final canSave = _validBody(draft.text);
            return PopScope(
              canPop: !saving,
              child: TioEditorSheet(
                key: const ValueKey('routine-note-composer-sheet'),
                title: 'Add Routine Note',
                supportingText: 'Private to you and pinned to this Routine.',
                content: TioInput.multiline(
                  key: const ValueKey('routine-note-body'),
                  controller: draft,
                  label: 'Note',
                  hint: 'Write a note for this Routine',
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 500,
                  errorText: errorText,
                  enabled: !saving,
                  onChanged: (value) {
                    if (errorText != null) {
                      setState(() => errorText = null);
                    } else {
                      setState(() {});
                    }
                  },
                ),
                actions: Row(
                  children: [
                    Expanded(
                      child: TioButton.secondary(
                        key: const ValueKey('routine-note-cancel'),
                        label: 'Cancel',
                        onPressed: saving
                            ? null
                            : () => Navigator.of(builderContext).pop(false),
                      ),
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    Expanded(
                      child: TioButton.primary(
                        key: const ValueKey('routine-note-save'),
                        label: 'Save Note',
                        enabled: canSave && !saving,
                        loading: saving,
                        loadingLabel: 'Saving...',
                        onPressed: !canSave || saving
                            ? null
                            : () async {
                                if (!sessionActive) return;
                                setState(() => saving = true);
                                final saved =
                                    await controller.create(draft.text);
                                if (!context.mounted) return;
                                if (!sessionActive) return;
                                if (saved) {
                                  Navigator.of(builderContext).pop(true);
                                  return;
                                }
                                if (controller.hasPendingMutation) {
                                  Navigator.of(builderContext).pop(false);
                                  return;
                                }
                                setState(() {
                                  saving = false;
                                  errorText = _actionError(
                                    controller.state.failure,
                                  );
                                });
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      sessionGuard?.cancel();
      draft.dispose();
    }
  }

  Future<void> _delete(RoutineNote note) async {
    final controller = _controller;
    if (controller == null || controller.isBusy) return;
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Delete Routine Note?',
      message: 'This note will be removed from this Routine.',
      confirmLabel: 'Delete Note',
      cancelLabel: 'Cancel',
      intent: TioConfirmationIntent.destructive,
    );
    if (confirmed != true || !mounted || !widget.isSessionCurrent()) return;
    await controller.delete(note);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final state = controller?.state;
    return Padding(
      key: const ValueKey('routine-notes-section'),
      padding: const EdgeInsets.only(top: TioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Routine Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.tioColors.textSecondary,
                      ),
                ),
              ),
              if (state?.isReady == true)
                TioButton.secondary(
                  key: const ValueKey('routine-note-add'),
                  label: 'Note',
                  leading: const Icon(Icons.note_add_outlined),
                  enabled: controller?.canCreate == true,
                  onPressed: _openComposer,
                ),
            ],
          ),
          const SizedBox(height: TioSpacing.sm),
          if (state == null || state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: TioSpacing.md),
              child: Center(
                child: SizedBox(
                  key: ValueKey('routine-notes-loading'),
                  width: TioSize.dp20,
                  height: TioSize.dp20,
                  child:
                      CircularProgressIndicator(strokeWidth: TioStroke.width2),
                ),
              ),
            )
          else if (state.status == RoutineNotesStatus.failed)
            _FailureView(
              key: const ValueKey('routine-notes-failed'),
              message: _failureMessage(state.failure),
              onRetry: controller!.isBusy ? null : () => controller.load(),
            )
          else ...[
            if (state.actionNotice != null)
              _NoticeText(
                key: const ValueKey('routine-notes-notice'),
                text: state.actionNotice!,
                onRefresh: controller!.isBusy ? null : () => controller.load(),
              ),
            if (state.notes.isEmpty)
              const _EmptyView(key: ValueKey('routine-notes-empty'))
            else
              for (final note in state.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: TioSpacing.sm),
                  child: _RoutineNoteCard(
                    key: ValueKey('routine-note-${note.id}'),
                    note: note,
                    enabled: !controller!.isBusy,
                    onDelete: () => _delete(note),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

final class _RoutineNoteCard extends StatelessWidget {
  const _RoutineNoteCard({
    required this.note,
    required this.enabled,
    required this.onDelete,
    super.key,
  });

  final RoutineNote note;
  final bool enabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioCard(
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
          Expanded(
            child: Semantics(
              label: 'Routine note: ${note.body}',
              child: Text(
                note.body,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: TioFontSize.size14,
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('routine-note-delete-${note.id}'),
            tooltip: 'Delete note',
            onPressed: enabled ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

final class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key});

  @override
  Widget build(BuildContext context) => Text(
        'No notes for this Routine yet.',
        key: const ValueKey('routine-notes-empty-message'),
        style: TextStyle(
          color: context.tioColors.textSecondary,
          fontSize: TioFontSize.size13,
        ),
      );
}

final class _NoticeText extends StatelessWidget {
  const _NoticeText({required this.text, this.onRefresh, super.key});

  final String text;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TioSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              key: const ValueKey('routine-notes-notice-message'),
              style: TextStyle(
                color: context.tioColors.textSecondary,
                fontSize: TioFontSize.size12,
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: TioSpacing.xs),
              TioButton.secondary(
                key: const ValueKey('routine-notes-refresh'),
                label: 'Refresh',
                onPressed: onRefresh,
              ),
            ],
          ],
        ),
      );
}

final class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            key: const ValueKey('routine-notes-failure-message'),
            style: TextStyle(
              color: context.tioColors.textSecondary,
              fontSize: TioFontSize.size13,
            ),
          ),
          const SizedBox(height: TioSpacing.xs),
          TioButton.secondary(
            key: const ValueKey('routine-notes-retry'),
            label: 'Try again',
            onPressed: onRetry,
          ),
        ],
      );
}

bool _validBody(String value) {
  final body = value.trim();
  return body.isNotEmpty && body.runes.length <= 500;
}

String _failureMessage(RoutineNoteFailureKind? failure) => switch (failure) {
      RoutineNoteFailureKind.unauthorized ||
      RoutineNoteFailureKind.forbidden =>
        'Notes are unavailable for this account session.',
      RoutineNoteFailureKind.quotaExceeded =>
        'This Routine already has the maximum of five notes.',
      RoutineNoteFailureKind.invalidRequest =>
        'Enter a note between 1 and 500 characters.',
      RoutineNoteFailureKind.revisionConflict ||
      RoutineNoteFailureKind.mutationConflict =>
        'The note changed elsewhere. Refresh and try again.',
      RoutineNoteFailureKind.malformedData =>
        'Notes data is unavailable right now.',
      RoutineNoteFailureKind.notFound => 'This Routine is no longer available.',
      RoutineNoteFailureKind.expired ||
      RoutineNoteFailureKind.unavailable ||
      null =>
        'Could not load Routine Notes. Please try again.',
    };

String _actionError(RoutineNoteFailureKind? failure) => switch (failure) {
      RoutineNoteFailureKind.quotaExceeded =>
        'This Routine already has the maximum of five notes.',
      RoutineNoteFailureKind.invalidRequest =>
        'Enter a note between 1 and 500 characters.',
      RoutineNoteFailureKind.unauthorized ||
      RoutineNoteFailureKind.forbidden =>
        'Your session no longer allows this action.',
      RoutineNoteFailureKind.revisionConflict ||
      RoutineNoteFailureKind.mutationConflict =>
        'The note changed elsewhere. Refresh and try again.',
      RoutineNoteFailureKind.unavailable =>
        'The save result could not be confirmed. Refresh before retrying.',
      _ => 'Could not save the note. Please try again.',
    };
