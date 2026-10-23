import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/repositories/routine_repository.dart';
import '../../../domain/usecases/program_id_generator.dart';
import '../routines/inline_program_routines.dart';
import '../routines/routine_move_refresh_signal.dart';
import 'programs_controller.dart';

enum _ProgramsSurfaceMode { standalone, library }

/// Reusable persisted user-Program collection presentation.
///
/// The standalone mode backs `ProgramsPage`. The Library mode renders the same
/// controller/repository/create contract inline without making the management
/// route a mandatory intermediate screen.
class ProgramsSurface extends StatefulWidget {
  const ProgramsSurface.standalone({
    required this.repository,
    this.idGenerator,
    this.moveRefreshSignal,
    this.moveRefreshOwnerId,
    this.moveRefreshLoginCycleId,
    super.key,
  })  : _mode = _ProgramsSurfaceMode.standalone,
        onManagePressed = null,
        onProgramPressed = null,
        onRoutinePressed = null,
        onEditRoutine = null,
        onMoveRoutine = null,
        onDeleteRoutine = null,
        actionSheetGuard = null,
        onAddRoutinePressed = null,
        hasUnconfirmedCreate = null,
        routineRepository = null;

  const ProgramsSurface.library({
    required this.repository,
    required this.onManagePressed,
    this.onProgramPressed,
    this.onRoutinePressed,
    this.onEditRoutine,
    this.onMoveRoutine,
    this.onDeleteRoutine,
    this.actionSheetGuard,
    this.onAddRoutinePressed,
    this.hasUnconfirmedCreate,
    this.routineRepository,
    this.idGenerator,
    this.moveRefreshSignal,
    this.moveRefreshOwnerId,
    this.moveRefreshLoginCycleId,
    super.key,
  }) : _mode = _ProgramsSurfaceMode.library;

  final ProgramRepository? repository;
  final ProgramIdGenerator? idGenerator;
  /// App-only owner/login-cycle bound invalidation, never Move success truth.
  final RoutineMoveRefreshSignal? moveRefreshSignal;
  final String? moveRefreshOwnerId;
  final String? moveRefreshLoginCycleId;
  final _ProgramsSurfaceMode _mode;
  final Future<void> Function()? onManagePressed;
  final Future<void> Function(Program)? onProgramPressed;
  final Future<void> Function(Program)? onAddRoutinePressed;
  /// Program-scoped uncertain save flag scoped by caller auth/login-cycle.
  final bool Function(Program)? hasUnconfirmedCreate;
  final Future<void> Function(Program, Routine)? onRoutinePressed;
  final Future<bool> Function(Program, Routine)? onEditRoutine;
  /// Optional Move capability; production app shell does not inject it yet.
  final Future<bool> Function(Program, Routine)? onMoveRoutine;
  final Future<bool> Function(Program, Routine)? onDeleteRoutine;
  final Widget Function(BuildContext, Widget)? actionSheetGuard;
  final RoutineRepository? routineRepository;

  @override
  State<ProgramsSurface> createState() => _ProgramsSurfaceState();
}

class _ProgramsSurfaceState extends State<ProgramsSurface> {
  ProgramsController? _controller;
  // The list child unmounts while ProgramsController publishes loading.
  // Keep the view-only collapse state in this stable, owner-scoped parent.
  final Set<ProgramId> _collapsedPrograms = <ProgramId>{};
  int _routineRefreshVersion = 0;
  bool _openingAddRoutine = false;

  void _toggleExpanded(ProgramId id) {
    setState(() {
      if (!_collapsedPrograms.add(id)) {
        _collapsedPrograms.remove(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.moveRefreshSignal?.addListener(_onMoveRefresh);
    _bindController();
  }

  @override
  void didUpdateWidget(covariant ProgramsSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.moveRefreshSignal, widget.moveRefreshSignal)) {
      oldWidget.moveRefreshSignal?.removeListener(_onMoveRefresh);
      widget.moveRefreshSignal?.addListener(_onMoveRefresh);
    }
    if (!identical(oldWidget.repository, widget.repository) ||
        !identical(oldWidget.idGenerator, widget.idGenerator) ||
        oldWidget.moveRefreshOwnerId != widget.moveRefreshOwnerId ||
        oldWidget.moveRefreshLoginCycleId != widget.moveRefreshLoginCycleId) {
      _bindController();
    }
  }

  void _bindController() {
    // Controller rebind covers repository/owner/login-cycle changes. Never
    // carry a former account's Program view preferences into a new session.
    _collapsedPrograms.clear();
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();

    final repository = widget.repository;
    if (repository == null) {
      _controller = null;
      return;
    }

    final controller = ProgramsController(
      repository: repository,
      idGenerator: widget.idGenerator,
    );
    _controller = controller;
    controller.addListener(_onControllerChanged);
    controller.load();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onMoveRefresh() {
    final signal = widget.moveRefreshSignal;
    if (!mounted || signal == null || !signal.matches(
      ownerId: widget.moveRefreshOwnerId,
      loginCycleId: widget.moveRefreshLoginCycleId,
    )) {
      return;
    }
    // Existing Move leaves Program membership unchanged: refresh expanded
    // Routine lists without collapsing their expansion state. Atomic
    // Create+Move may have created a Program, so re-read that collection too.
    if (signal.programsMayHaveChanged) {
      _controller?.load();
    }
    setState(() => _routineRefreshVersion++);
  }

  @override
  void dispose() {
    widget.moveRefreshSignal?.removeListener(_onMoveRefresh);
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _openProgram(Program program) async {
    final open = widget.onProgramPressed;
    if (open == null) return;
    await open(program);
    if (!mounted) return;
    setState(() => _routineRefreshVersion++);
  }

  Future<bool> _editLibraryRoutine(Program program, Routine routine) async {
    final edit = widget.onEditRoutine;
    if (edit == null || routine.programId != program.id) return false;
    final saved = await edit(program, routine);
    if (mounted && saved) setState(() => _routineRefreshVersion++);
    return saved;
  }

  Future<void> _openAddRoutine(Program program) async {
    final open = widget.onAddRoutinePressed;
    if (_openingAddRoutine || open == null ||
        (widget.hasUnconfirmedCreate?.call(program) ?? false)) {
      return;
    }
    // Shared single flight across every Program card and overflow action.
    setState(() => _openingAddRoutine = true);
    try {
      await open(program);
    } finally {
      if (mounted) {
        setState(() {
          _openingAddRoutine = false;
          _routineRefreshVersion++;
        });
      }
    }
  }

  Future<void> _openManage() async {
    final onManagePressed = widget.onManagePressed;
    if (onManagePressed == null) return;

    final controller = _controller;
    await onManagePressed();
    if (controller == null ||
        !mounted ||
        !identical(controller, _controller)) {
      return;
    }
    await controller.load();
  }

  Future<void> _openRename(Program program) async {
    final controller = _controller;
    if (controller == null ||
        controller.state.status != ProgramsStatus.ready ||
        controller.state.creating) {
      return;
    }

    await showTioEditorSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => _RenameProgramSheet(
        controller: controller,
        program: program,
      ),
    );
  }

  Future<void> _openProgramActions(Program program) async {
    final pendingSave = widget.hasUnconfirmedCreate?.call(program) ?? false;
    var addRequested = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TioPalette.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: TioSheet(
          key: const ValueKey('program-actions-sheet'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program.name,
                key: const ValueKey('program-actions-title'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      color: sheetContext.tioColors.textPrimary,
                    ),
              ),
              const SizedBox(height: TioSpacing.lg),
              TioGroupCard(
                children: [
                  TioSettingsNavigationRow(
                    key: const ValueKey('program-action-edit'),
                    leading: const TioSettingsLeadingIcon(
                      icon: Icons.edit_outlined,
                    ),
                    title: 'Edit Program',
                    supportingText: 'Rename this Program',
                    showChevron: false,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _openRename(program);
                    },
                  ),
                  if (widget.onAddRoutinePressed != null)
                    TioSettingsNavigationRow(
                      key: const ValueKey('program-action-add-routine'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.add_rounded,
                      ),
                      title: 'Add New Routine',
                      titleColor: pendingSave || _openingAddRoutine
                          ? sheetContext.tioColors.textMuted
                          : null,
                      supportingText: pendingSave
                          ? 'Check the previous save in Program'
                          : _openingAddRoutine
                              ? 'Another Routine is opening'
                              : 'Create in this Program',
                      showChevron: false,
                      onTap: _openingAddRoutine || pendingSave ? null : () {
                        addRequested = true;
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    // The bottom-sheet transition must finish before the shell tests whether
    // Library is still the current route and launches canonical Create.
    if (addRequested && mounted) await _openAddRoutine(program);
  }

  Future<void> _openCreate() async {
    final controller = _controller;
    if (controller == null ||
        controller.state.status != ProgramsStatus.ready ||
        controller.state.creating) {
      return;
    }

    await showTioEditorSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => _CreateProgramSheet(
        initialName: controller.suggestedName(),
        onSubmit: controller.create,
        currentError: () => controller.state.createError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget._mode) {
      _ProgramsSurfaceMode.standalone => _standalone(),
      _ProgramsSurfaceMode.library => _library(),
    };
  }

  Widget _standalone() {
    final colors = context.tioColors;
    final controller = _controller;
    final canCreate = _canCreate(controller);

    return Scaffold(
      key: const ValueKey('programs-page'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Programs',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('programs-create-action'),
            tooltip: 'Create Program',
            onPressed: canCreate ? _openCreate : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _body(embedded: false)),
    );
  }

  Widget _library() {
    final colors = context.tioColors;
    final controller = _controller;
    final canCreate = _canCreate(controller);

    return Column(
      key: const ValueKey('library-programs-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              key: const ValueKey('library-programs-header'),
              onPressed: _openManage,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: colors.textPrimary,
              ),
              child: Text(
                'Programs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w800,
                    ),
              ),
            ),
            const Spacer(),
            IconButton(
              key: const ValueKey('library-programs-create'),
              tooltip: 'Create Program',
              onPressed: canCreate ? _openCreate : null,
              color: colors.textPrimary,
              icon: const Icon(Icons.create_new_folder_outlined),
            ),
          ],
        ),
        const SizedBox(height: TioSpacing.sm),
        _body(embedded: true),
      ],
    );
  }

  bool _canCreate(ProgramsController? controller) =>
      controller != null &&
      controller.state.status == ProgramsStatus.ready &&
      !controller.state.creating;

  Widget _body({required bool embedded}) {
    final controller = _controller;
    if (controller == null) {
      return const _ProgramsUnavailable();
    }

    final state = controller.state;
    switch (state.status) {
      case ProgramsStatus.loading:
        return const _ProgramsLoading();
      case ProgramsStatus.loadFailed:
        return _ProgramsLoadFailure(
          message:
              state.loadError ?? 'Could not load programs. Please try again.',
          onRetry: controller.retryLoad,
        );
      case ProgramsStatus.ready:
        if (state.programs.isEmpty) {
          return _ProgramsEmpty(onCreate: _openCreate);
        }
        return _ProgramsList(
          programs: state.programs,
          embedded: embedded,
          collapsedPrograms: _collapsedPrograms,
          onToggleExpanded: _toggleExpanded,
          onProgramActions: _openProgramActions,
          onProgramPressed: widget.onProgramPressed == null
              ? null
              : _openProgram,
          onAddRoutinePressed: widget.onAddRoutinePressed == null
              ? null
              : _openAddRoutine,
          routineRepository: widget.routineRepository,
          onRoutinePressed: widget.onRoutinePressed,
          onEditRoutine: widget.onEditRoutine == null ? null : _editLibraryRoutine,
          onMoveRoutine: widget.onMoveRoutine,
          onDeleteRoutine: widget.onDeleteRoutine,
          actionSheetGuard: widget.actionSheetGuard,
          hasUnconfirmedCreate: widget.hasUnconfirmedCreate,
          isLaunchingRoutine: _openingAddRoutine,
          routineRefreshVersion: _routineRefreshVersion,
        );
    }
  }
}

class _ProgramsLoading extends StatelessWidget {
  const _ProgramsLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: TioSpacing.xl),
        child: Center(
          key: ValueKey('programs-loading'),
          child: CircularProgressIndicator(),
        ),
      );
}

class _ProgramsList extends StatefulWidget {
  const _ProgramsList({
    required this.programs,
    required this.embedded,
    required this.collapsedPrograms,
    required this.onToggleExpanded,
    required this.onProgramActions,
    required this.onProgramPressed,
    required this.onAddRoutinePressed,
    required this.routineRepository,
    required this.onRoutinePressed,
    required this.onEditRoutine,
    required this.onMoveRoutine,
    required this.onDeleteRoutine,
    required this.actionSheetGuard,
    required this.hasUnconfirmedCreate,
    required this.isLaunchingRoutine,
    required this.routineRefreshVersion,
  });

  final List<Program> programs;
  final bool embedded;
  final Set<ProgramId> collapsedPrograms;
  final ValueChanged<ProgramId> onToggleExpanded;
  final Future<void> Function(Program program) onProgramActions;
  final Future<void> Function(Program)? onProgramPressed;
  final Future<void> Function(Program)? onAddRoutinePressed;
  final Future<void> Function(Program, Routine)? onRoutinePressed;
  final Future<bool> Function(Program, Routine)? onEditRoutine;
  /// Optional Move capability; production app shell does not inject it yet.
  final Future<bool> Function(Program, Routine)? onMoveRoutine;
  final Future<bool> Function(Program, Routine)? onDeleteRoutine;
  final Widget Function(BuildContext, Widget)? actionSheetGuard;
  final RoutineRepository? routineRepository;
  final bool Function(Program)? hasUnconfirmedCreate;
  final bool isLaunchingRoutine;
  final int routineRefreshVersion;

  @override
  State<_ProgramsList> createState() => _ProgramsListState();
}

class _ProgramsListState extends State<_ProgramsList> {
  @override
  Widget build(BuildContext context) {
    if (!widget.embedded) {
      final children = <Widget>[];
      for (var index = 0; index < widget.programs.length; index++) {
        final program = widget.programs[index];
        children.add(
          _StandaloneProgramRow(
            key: ValueKey('program-row-${program.id.value}'),
            name: program.name,
          ),
        );
        if (index != widget.programs.length - 1) {
          children.add(const _ProgramsDivider(indented: true));
        }
      }

      return ListView(
        key: const ValueKey('programs-list'),
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md,
        ),
        children: [TioGroupCard(children: children)],
      );
    }

    final children = <Widget>[];
    for (var index = 0; index < widget.programs.length; index++) {
      final program = widget.programs[index];
      final expanded = !widget.collapsedPrograms.contains(program.id);
      children.add(
        _LibraryProgramRow(
          key: ValueKey('program-row-${program.id.value}'),
          program: program,
          expanded: expanded,
          onToggleExpanded: () => widget.onToggleExpanded(program.id),
          onOverflowPressed: () => widget.onProgramActions(program),
          onProgramPressed: widget.onProgramPressed == null
              ? null
              : () => widget.onProgramPressed!(program),
        ),
      );
      if (expanded) {
        children.add(
          InlineProgramRoutines(
            key: ValueKey('library-program-routines-${program.id.value}'),
            program: program,
            repository: widget.routineRepository,
            refreshVersion: widget.routineRefreshVersion,
            onRoutinePressed: widget.onRoutinePressed == null
                ? null
                : (routine) => widget.onRoutinePressed!(program, routine),
            onEditRoutine: widget.onEditRoutine == null
                ? null
                : (routine) => widget.onEditRoutine!(program, routine),
            onMoveRoutine: widget.onMoveRoutine == null
                ? null
                : (routine) => widget.onMoveRoutine!(program, routine),
            actionSheetGuard: widget.actionSheetGuard,
            onDeleteRoutine: widget.onDeleteRoutine == null
                ? null
                : (routine) => widget.onDeleteRoutine!(program, routine),
            onAddRoutine: widget.onAddRoutinePressed == null
                ? null
                : () => widget.onAddRoutinePressed!(program),
            disableAddRoutine: widget.isLaunchingRoutine ||
                (widget.hasUnconfirmedCreate?.call(program) ?? false),
            hasUnconfirmedCreate:
                widget.hasUnconfirmedCreate?.call(program) ?? false,
            onOpenProgram: widget.onProgramPressed == null
                ? null
                : () => widget.onProgramPressed!(program),
          ),
        );
      }
      if (index != widget.programs.length - 1) {
        children.add(const _ProgramsDivider(indented: false));
      }
    }

    return Column(
      key: const ValueKey('programs-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _StandaloneProgramRow extends StatelessWidget {
  const _StandaloneProgramRow({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md + TioSize.dp4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w700,
            fontSize: TioFontSize.size15,
          ),
        ),
      ),
    );
  }
}

class _LibraryProgramRow extends StatelessWidget {
  const _LibraryProgramRow({
    required this.program,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onOverflowPressed,
    required this.onProgramPressed,
    super.key,
  });

  final Program program;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onOverflowPressed;
  final VoidCallback? onProgramPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
      child: Row(
        children: [
          IconButton(
            key: ValueKey('program-expand-${program.id.value}'),
            tooltip:
                expanded ? 'Collapse ${program.name}' : 'Expand ${program.name}',
            onPressed: onToggleExpanded,
            color: colors.textSecondary,
            padding: EdgeInsets.zero,
            alignment: AlignmentDirectional.centerStart,
            constraints: const BoxConstraints.tightFor(
              width: TioSize.dp48,
              height: TioSize.dp48,
            ),
            icon: Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
            ),
          ),
          Expanded(
            child: onProgramPressed == null
                ? Text(
                    program.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: TioSize.dp48),
                    child: InkWell(
                      key: ValueKey('program-open-${program.id.value}'),
                      onTap: onProgramPressed,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          program.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: TioFontWeight.w700,
                            fontSize: TioFontSize.size15,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          IconButton(
            key: ValueKey('program-overflow-${program.id.value}'),
            tooltip: 'Program actions',
            onPressed: onOverflowPressed,
            color: colors.textSecondary,
            padding: EdgeInsets.zero,
            alignment: AlignmentDirectional.centerEnd,
            constraints: const BoxConstraints.tightFor(
              width: TioSize.dp48,
              height: TioSize.dp48,
            ),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProgramsDivider extends StatelessWidget {
  const _ProgramsDivider({required this.indented});

  final bool indented;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioStroke.width1,
      indent: indented ? TioSpacing.lg : null,
      endIndent: indented ? TioSpacing.lg : null,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}

class _ProgramsEmpty extends StatelessWidget {
  const _ProgramsEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Center(
      key: const ValueKey('programs-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No programs yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                  ),
            ),
            const SizedBox(height: TioSpacing.lg),
            TioButton.primary(
              key: const ValueKey('programs-empty-create'),
              label: 'Create Program',
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramsLoadFailure extends StatelessWidget {
  const _ProgramsLoadFailure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Center(
      key: const ValueKey('programs-load-failure'),
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size14,
              ),
            ),
            const SizedBox(height: TioSpacing.lg),
            TioButton.secondary(
              key: const ValueKey('programs-retry'),
              label: 'Try again',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramsUnavailable extends StatelessWidget {
  const _ProgramsUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Center(
      key: const ValueKey('programs-unavailable'),
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.xl),
        child: Text(
          'Programs are unavailable right now.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: TioFontSize.size14,
          ),
        ),
      ),
    );
  }
}

class _RenameProgramSheet extends StatefulWidget {
  const _RenameProgramSheet({
    required this.controller,
    required this.program,
  });

  final ProgramsController controller;
  final Program program;

  @override
  State<_RenameProgramSheet> createState() => _RenameProgramSheetState();
}

class _RenameProgramSheetState extends State<_RenameProgramSheet> {
  late final TextEditingController _nameController;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program.name)
      ..addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() => _error = null);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _nameController.text.trim().isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.controller.rename(
      program: widget.program,
      name: _nameController.text,
    );
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_saving && _nameController.text.trim().isNotEmpty;

    return PopScope(
      canPop: !_saving,
      child: TioEditorSheet(
        title: 'Edit Program',
        canDismiss: !_saving,
        content: TioInput(
          key: const ValueKey('program-edit-name-field'),
          controller: _nameController,
          onChanged: (_) {},
          hint: 'Program name',
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
          key: const ValueKey('program-edit-submit'),
          label: _saving ? 'Saving...' : 'Save',
          onPressed: canSubmit ? _submit : null,
        ),
      ),
    );
  }
}

class _CreateProgramSheet extends StatefulWidget {
  const _CreateProgramSheet({
    required this.initialName,
    required this.onSubmit,
    this.currentError,
    this.nameOnly = false,
    this.submitLabel,
  });

  final String initialName;
  final Future<bool> Function(String) onSubmit;
  final String? Function()? currentError;
  /// Name-only selection never persists a Program before Create & Move.
  final bool nameOnly;
  final String? submitLabel;

  @override
  State<_CreateProgramSheet> createState() => _CreateProgramSheetState();
}

class _CreateProgramSheetState extends State<_CreateProgramSheet> {
  late final TextEditingController _nameController;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName)
      ..addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() => _error = null);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _nameController.text.trim().isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final succeeded = await widget.onSubmit(_nameController.text);
    if (!mounted) return;

    if (succeeded) {
      Navigator.of(context).pop(
        widget.nameOnly ? _nameController.text.trim() : null,
      );
      return;
    }

    setState(() {
      _saving = false;
      _error = widget.currentError?.call() ??
          'Could not create program. Please try again.';
    });
  }

  String _submitButtonLabel() {
    final custom = widget.submitLabel;
    if (custom != null) {
      if (_saving) {
        if (custom == 'Save & Move') return 'Saving & Moving...';
        return 'Saving...';
      }
      return custom;
    }
    if (widget.nameOnly) {
      return _saving ? 'Continuing...' : 'Continue';
    }
    return _saving ? 'Creating...' : 'Create';
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_saving && _nameController.text.trim().isNotEmpty;

    return PopScope(
      canPop: !_saving,
      child: TioEditorSheet(
        title: 'Create Program',
        canDismiss: !_saving,
        content: TioInput(
          key: const ValueKey('program-name-field'),
          controller: _nameController,
          onChanged: (_) {},
          hint: 'Program name',
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
          key: const ValueKey('program-create-submit'),
          label: _submitButtonLabel(),
          onPressed: canSubmit ? _submit : null,
        ),
      ),
    );
  }
}


/// Reuses the canonical Create Program name editor to return a draft only.
/// In the Move workflow, this must never call ProgramRepository.create.
Future<String?> promptCreateProgramName({
  required BuildContext context,
  required String initialName,
  Widget Function(BuildContext, Widget)? modalGuard,
  String submitLabel = 'Save & Move',
}) => showTioEditorSheet<String>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  builder: (sheetContext) {
    final sheet = _CreateProgramSheet(
      initialName: initialName,
      onSubmit: (_) async => true,
      nameOnly: true,
      submitLabel: submitLabel,
    );
    return modalGuard?.call(sheetContext, sheet) ?? sheet;
  },
);
