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
    this.onCreateRoutine,
    this.launchCreateOnReady = false,
    this.hasUnconfirmedCreate,
    this.onVerifyUnconfirmedCreate,
    this.pendingCreateChanges,
  });

  final Program program;
  final RoutineRepository? routineRepository;

  /// Injected only for deterministic tests; production uses a random UUID v4.
  final String Function()? newRoutineUuid;
  final Future<void> Function(Routine routine)? onRoutinePressed;

  /// Atomic Create draft action supplied by the authenticated app shell.
  /// True means re-read the Program: either a confirmed Create or an explicit
  /// unconfirmed exit where the server may already have committed.
  /// Production must never fall back to metadata-only creation.
  final Future<bool> Function(String suggestedName)? onCreateRoutine;
  /// A Library Add Routine entry opens this Program's existing Create flow
  /// after its owner-scoped Routine read succeeds, then returns to Library.
  final bool launchCreateOnReady;
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
  bool _autoCreateTriggered = false;

  void _maybeAutoCreate() {
    if (!widget.launchCreateOnReady || _autoCreateTriggered ||
        !_canEdit || _hasUnconfirmed || widget.onCreateRoutine == null) {
      return;
    }
    _autoCreateTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _openCreate();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

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
    _maybeAutoCreate();
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
      _autoCreateTriggered = false;
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
    _maybeAutoCreate();
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

  Future<void> _openRename(Routine routine) async {
    final controller = _controller;
    if (!_canEdit || controller == null ||
        routine.programId != widget.program.id) {
      return;
    }
    await showTioEditorSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => _RoutineNameSheet(
        controller: controller,
        initialName: routine.name,
        routine: routine,
      ),
    );
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
                  onEdit: _canEdit ? () => _openRename(routine) : null,
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

/// One persisted-name editor shared by create and rename. No fake builder
/// action appears while composition editing is still unimplemented.
class _RoutineNameSheet extends StatefulWidget {
  const _RoutineNameSheet({
    required this.controller,
    required this.initialName,
    this.routine,
  });

  final ProgramRoutinesController controller;
  final String initialName;
  final Routine? routine;

  @override
  State<_RoutineNameSheet> createState() => _RoutineNameSheetState();
}

class _RoutineNameSheetState extends State<_RoutineNameSheet> {
  late final TextEditingController _name;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName)
      ..addListener(_clearError);
  }

  void _clearError() {
    // Rebuild on *every* edit so the primary action tracks empty/non-empty
    // names before and after a server validation error.
    if (mounted) setState(() => _error = null);
  }

  @override
  void dispose() {
    _name
      ..removeListener(_clearError)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _name.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final routine = widget.routine;
    String? error;
    if (routine == null) {
      if (!await widget.controller.create(_name.text)) {
        error = widget.controller.state.error ??
            'Could not create routine. Please try again.';
      }
    } else {
      error = await widget.controller.rename(routine: routine, name: _name.text);
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.routine != null;
    final canSubmit = !_saving && _name.text.trim().isNotEmpty;
    return PopScope(
      canPop: !_saving,
      child: TioEditorSheet(
        title: editing ? 'Edit Routine' : 'Create Routine',
        canDismiss: !_saving,
        content: TioInput(
          key: const ValueKey('routine-name-field'),
          controller: _name,
          onChanged: (_) {},
          hint: 'Routine name',
          errorText: _error,
          enabled: !_saving,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canSubmit) _submit();
          },
        ),
        actions: TioButton.primary(
          key: const ValueKey('routine-name-submit'),
          label: _saving
              ? 'Saving...'
              : editing
                  ? 'Save'
                  : 'Create',
          onPressed: canSubmit ? _submit : null,
        ),
      ),
    );
  }
}
