import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/usecases/program_id_generator.dart';
import 'programs_controller.dart';

/// Persisted user Program collection.
///
/// Rows are intentionally display-only in this first increment. Detail,
/// Routine management, archive/delete and scheduling are separate slices.
class ProgramsPage extends StatefulWidget {
  const ProgramsPage({
    required this.repository,
    super.key,
    this.idGenerator,
  });

  /// Null means durable Program persistence is unavailable in app composition.
  final ProgramRepository? repository;
  final ProgramIdGenerator? idGenerator;

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  ProgramsController? _controller;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant ProgramsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository) ||
        !identical(oldWidget.idGenerator, widget.idGenerator)) {
      _bindController();
    }
  }

  void _bindController() {
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

  @override
  void dispose() {
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
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
        controller: controller,
        initialName: controller.suggestedName(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final controller = _controller;
    final canCreate = controller != null &&
        controller.state.status == ProgramsStatus.ready &&
        !controller.state.creating;

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
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    final controller = _controller;
    if (controller == null) {
      return const _ProgramsUnavailable();
    }

    final state = controller.state;
    switch (state.status) {
      case ProgramsStatus.loading:
        return const Center(
          key: ValueKey('programs-loading'),
          child: CircularProgressIndicator(),
        );
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
        return _ProgramsList(programs: state.programs);
    }
  }
}

class _ProgramsList extends StatelessWidget {
  const _ProgramsList({required this.programs});

  final List<Program> programs;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < programs.length; index++) {
      final program = programs[index];
      children.add(
        _ProgramRow(
          key: ValueKey('program-row-${program.id.value}'),
          name: program.name,
        ),
      );
      if (index != programs.length - 1) {
        children.add(const _ProgramsDivider());
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
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({required this.name, super.key});

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

class _ProgramsDivider extends StatelessWidget {
  const _ProgramsDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioStroke.width1,
      indent: TioSpacing.lg,
      endIndent: TioSpacing.lg,
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

class _CreateProgramSheet extends StatefulWidget {
  const _CreateProgramSheet({
    required this.controller,
    required this.initialName,
  });

  final ProgramsController controller;
  final String initialName;

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

    final succeeded = await widget.controller.create(_nameController.text);
    if (!mounted) return;

    if (succeeded) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = false;
      _error = widget.controller.state.createError ??
          'Could not create program. Please try again.';
    });
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
          label: _saving ? 'Creating...' : 'Create',
          onPressed: canSubmit ? _submit : null,
        ),
      ),
    );
  }
}
