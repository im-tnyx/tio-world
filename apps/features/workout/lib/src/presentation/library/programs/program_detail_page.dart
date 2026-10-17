import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_repository.dart';
import '../routines/program_routines_controller.dart';
import '../routines/routine_metadata_card.dart';

/// Minimal Program-owned Routine metadata screen. Exercise composition/editing
/// and Library-level Routine quick-create are different, still-gated slices.
class ProgramDetailPage extends StatefulWidget {
  const ProgramDetailPage({
    required this.program,
    required this.routineRepository,
    super.key,
    this.newRoutineUuid,
    this.onRoutinePressed,
    this.onEditRoutine,
    this.onDeleteRoutine,
    this.onCreateRoutine,
    this.hasUnconfirmedCreate,
    this.onVerifyUnconfirmedCreate,
    this.pendingCreateChanges,
  });

  final Program program;
  final RoutineRepository? routineRepository;

  /// Injected only for deterministic tests; production uses a random UUID v4.
  final String Function()? newRoutineUuid;
  final Future<void> Function(Routine routine)? onRoutinePressed;
  /// Opens the same verified owner Edit composer as Routine Detail.
  final Future<bool> Function(Routine routine)? onEditRoutine;
  /// Verified Delete returns true only when the owner-scoped list must refresh.
  final Future<bool> Function(Routine routine)? onDeleteRoutine;

  /// Atomic Create draft action supplied by the authenticated app shell.
  /// True means re-read the Program: either a confirmed Create or an explicit
  /// unconfirmed exit where the server may already have committed.
  /// Production must never fall back to metadata-only creation.
  final Future<bool> Function(String suggestedName)? onCreateRoutine;
  /// Volatile app owner/login-cycle protection, not stored Routine truth.
  final bool Function()? hasUnconfirmedCreate;
  final Future<bool> Function()? onVerifyUnconfirmedCreate;
  /// Refresh the disabled Create action when an in-flight RPC settles.
  /// No draft payload or auth credentials cross this notification boundary.
  final Listenable? pendingCreateChanges;

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  ProgramRoutinesController? _controller;
  bool _verifyingUnconfirmed = false;
  bool get _hasUnconfirmed => widget.hasUnconfirmedCreate?.call() ?? false;

  Future<void> _verifyUnconfirmed() async {
    final verify = widget.onVerifyUnconfirmedCreate;
    if (_verifyingUnconfirmed || !_hasUnconfirmed || verify == null) return;
    setState(() => _verifyingUnconfirmed = true);
    try {
      await verify();
      if (mounted) await _controller?.load();
    } finally {
      if (mounted) setState(() => _verifyingUnconfirmed = false);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.pendingCreateChanges?.addListener(_pendingChanged);
    _bind();
  }

  void _pendingChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ProgramDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pendingCreateChanges, widget.pendingCreateChanges)) {
      oldWidget.pendingCreateChanges?.removeListener(_pendingChanged);
      widget.pendingCreateChanges?.addListener(_pendingChanged);
    }
    if (oldWidget.program.id != widget.program.id ||
        !identical(oldWidget.routineRepository, widget.routineRepository) ||
        !identical(oldWidget.newRoutineUuid, widget.newRoutineUuid)) {
      _bind();
    }
  }

  void _bind() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    final repository = widget.routineRepository;
    if (repository == null) {
      _controller = null;
      return;
    }
    final controller = ProgramRoutinesController(
      program: widget.program,
      repository: repository,
      newRoutineUuid: widget.newRoutineUuid,
    )..addListener(_onChanged);
    _controller = controller;
    controller.load();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    widget.pendingCreateChanges?.removeListener(_pendingChanged);
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  bool get _canEdit {
    final c = _controller;
    return c != null &&
        c.state.status == ProgramRoutinesStatus.ready &&
        !c.state.saving;
  }

  Future<void> _openCreate() async {
    final controller = _controller;
    final create = widget.onCreateRoutine;
    // No protected atomic Create capability means no Create action.
    // Never expose metadata-only name persistence as a fallback.
    if (!_canEdit || _hasUnconfirmed ||
        controller == null || create == null) {
      return;
    }
    final shouldRefresh = await create(controller.suggestedName());
    if (mounted && identical(controller, _controller) && shouldRefresh) {
      await controller.load();
    }
  }

  Future<void> _openEditor(Routine routine) async {
    final controller = _controller;
    final edit = widget.onEditRoutine;
    if (!_canEdit || controller == null || edit == null ||
        routine.programId != widget.program.id || !
        controller.state.routines.any((item) => item.id == routine.id)) {
      return;
    }
    final confirmed = await edit(routine);
    if (mounted && identical(controller, _controller) && confirmed) {
      await controller.load();
    }
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final controller = _controller;
    final delete = widget.onDeleteRoutine;
    if (!_canEdit || _hasUnconfirmed || controller == null || delete == null ||
        routine.programId != widget.program.id ||
        !controller.state.routines.any((item) => item.id == routine.id)) {
      return;
    }
    final shouldRefresh = await delete(routine);
    if (mounted && identical(controller, _controller) && shouldRefresh) {
      await controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Scaffold(
      key: const ValueKey('program-detail-page'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          widget.program.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioFontSize.size20,
            fontWeight: TioFontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('program-detail-add-routine'),
            tooltip: 'Add Routine',
            color: colors.textPrimary,
            onPressed: _canEdit && !_hasUnconfirmed &&
                    widget.onCreateRoutine != null
                ? _openCreate
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSpacing.md,
          ),
          children: [
            if (_hasUnconfirmed) ...[
              Text(
                'A previous Routine save is unconfirmed. '
                'Check its status before creating another Routine.',
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: TioSpacing.sm),
              TioButton.secondary(
                key: const ValueKey('program-routines-verify-create'),
                label: 'Check save status',
                onPressed: !_verifyingUnconfirmed &&
                        widget.onVerifyUnconfirmedCreate != null
                    ? _verifyUnconfirmed
                    : null,
              ),
              const SizedBox(height: TioSpacing.lg),
            ],
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final controller = _controller;
    if (controller == null) {
      return const _RoutineMessage(
        key: ValueKey('program-routines-unavailable'),
        message: 'Routines are unavailable right now.',
      );
    }

    final state = controller.state;
    switch (state.status) {
      case ProgramRoutinesStatus.loading:
        return const Center(
          key: ValueKey('program-routines-loading'),
          child: CircularProgressIndicator(),
        );
      case ProgramRoutinesStatus.loadFailed:
        return Column(
          key: const ValueKey('program-routines-load-failed'),
          children: [
            const _RoutineMessage(
              message: 'Could not load routines. Please try again.',
            ),
            const SizedBox(height: TioSpacing.lg),
            TioButton.secondary(
              key: const ValueKey('program-routines-retry'),
              label: 'Try again',
              onPressed: controller.retryLoad,
            ),
          ],
        );
      case ProgramRoutinesStatus.ready:
        if (state.routines.isEmpty) {
          return const _RoutineMessage(
            key: ValueKey('program-routines-empty'),
            message: 'No routines yet. Use + above to add one.',
          );
        }
        return Column(
          key: const ValueKey('program-routines-list'),
          children: [
            for (final routine in state.routines)
              Padding(
                key: ValueKey('program-routine-${routine.id.value}'),
                padding: const EdgeInsets.only(bottom: TioSpacing.sm),
                child: RoutineMetadataCard(
                  routine: routine,
                  supportingText: widget.onRoutinePressed == null
                      ? null
                      : 'View Routine',
                  onTap: _canEdit && widget.onRoutinePressed != null
                      ? () { widget.onRoutinePressed!(routine); }
                      : null,
                  onEdit: _canEdit && widget.onEditRoutine != null
                      ? () => _openEditor(routine) : null,
                  onDelete: _canEdit && !_hasUnconfirmed &&
                          widget.onDeleteRoutine != null
                      ? () => _deleteRoutine(routine) : null,
                ),
              ),
          ],
        );
    }
  }
}

class _RoutineMessage extends StatelessWidget {
  const _RoutineMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(TioSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.tioColors.textSecondary,
            fontSize: TioFontSize.size14,
          ),
        ),
      );
}

