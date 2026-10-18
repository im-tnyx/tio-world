import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_repository.dart';
import 'program_routines_controller.dart';
import 'routine_metadata_card.dart';

/// Owner-filtered Routine children under an expanded Library Program.
/// Actions reuse the same Routine card/sheet; the app shell provides any
/// current owner-verified editor capability. No second Routine truth exists.
class InlineProgramRoutines extends StatefulWidget {
  const InlineProgramRoutines({
    required this.program,
    required this.repository,
    required this.refreshVersion,
    this.onRoutinePressed,
    this.onEditRoutine,
    this.onMoveRoutine,
    this.onDeleteRoutine,
    this.actionSheetGuard,
    this.onAddRoutine,
    this.onOpenProgram,
    this.disableAddRoutine = false,
    this.hasUnconfirmedCreate = false,
    super.key,
  });

  final Program program;
  final RoutineRepository? repository;
  final int refreshVersion;
  final Future<void> Function(Routine routine)? onRoutinePressed;
  /// Real canonical full editor, guarded by app shell identity/login cycle.
  final Future<bool> Function(Routine routine)? onEditRoutine;
  /// Optional owner-injected Move. True requests source-list reread only.
  final Future<bool> Function(Routine routine)? onMoveRoutine;
  /// Owner-checked and confirmed Delete (or uncertain write) requests a read.
  final Future<bool> Function(Routine routine)? onDeleteRoutine;
  final Widget Function(BuildContext, Widget)? actionSheetGuard;
  /// Opens canonical Create for this exact Program; injected by app shell.
  final Future<void> Function()? onAddRoutine;
  /// Existing Program Detail exposes owner-scoped unknown-save verification.
  final Future<void> Function()? onOpenProgram;
  final bool disableAddRoutine;
  final bool hasUnconfirmedCreate;

  @override
  State<InlineProgramRoutines> createState() => _InlineProgramRoutinesState();
}

class _InlineProgramRoutinesState extends State<InlineProgramRoutines> {
  ProgramRoutinesController? _controller;
  bool _openingCreate = false;

  Future<void> _addRoutine() async {
    final add = widget.onAddRoutine;
    final controller = _controller;
    if (_openingCreate || widget.disableAddRoutine || add == null || controller == null ||
        controller.state.status != ProgramRoutinesStatus.ready ||
        controller.state.routines.isNotEmpty) {
      return;
    }
    setState(() => _openingCreate = true);
    try {
      await add();
    } finally {
      if (mounted) setState(() => _openingCreate = false);
    }
  }

  Future<void> _moveRoutine(Routine routine) async {
    final controller = _controller;
    final move = widget.onMoveRoutine;
    if (controller == null || move == null ||
        controller.state.status != ProgramRoutinesStatus.ready ||
        controller.state.saving || widget.hasUnconfirmedCreate ||
        routine.programId != widget.program.id ||
        !controller.state.routines.any((item) => item.id == routine.id)) {
      return;
    }
    final refresh = await move(routine);
    if (mounted && identical(controller, _controller) && refresh) {
      await controller.load();
    }
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final controller = _controller;
    final delete = widget.onDeleteRoutine;
    if (controller == null || delete == null ||
        controller.state.status != ProgramRoutinesStatus.ready ||
        controller.state.saving || routine.programId != widget.program.id ||
        !controller.state.routines.any((item) => item.id == routine.id)) {
      return;
    }
    final refresh = await delete(routine);
    if (mounted && identical(controller, _controller) && refresh) {
      await controller.load();
    }
  }

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant InlineProgramRoutines oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id ||
        !identical(oldWidget.repository, widget.repository)) {
      _bind();
    } else if (oldWidget.refreshVersion != widget.refreshVersion) {
      _controller?.load();
    }
  }

  void _bind() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();

    final repository = widget.repository;
    if (repository == null) {
      _controller = null;
      return;
    }
    final controller = ProgramRoutinesController(
      program: widget.program,
      repository: repository,
    )..addListener(_onChanged);
    _controller = controller;
    controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // No active owner-scoped data source: do not render old or invented rows.
    if (controller == null) {
      return const SizedBox.shrink(
        key: ValueKey('library-routines-unavailable'),
      );
    }
    final state = controller.state;
    Widget content;
    switch (state.status) {
      case ProgramRoutinesStatus.loading:
        content = const Center(
          child: Padding(
            padding: EdgeInsets.all(TioSpacing.sm),
            child: CircularProgressIndicator(),
          ),
        );
      case ProgramRoutinesStatus.loadFailed:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not load routines.',
              style: TextStyle(
                color: context.tioColors.textSecondary,
              ),
            ),
            TioButton.secondary(
              key: ValueKey(
                'library-routines-retry-${widget.program.id.value}',
              ),
              label: 'Try again',
              onPressed: controller.retryLoad,
            ),
          ],
        );
      case ProgramRoutinesStatus.ready:
        if (state.routines.isEmpty) {
          content = widget.onAddRoutine == null
              ? Text(
                  'No routines yet',
                  style: TextStyle(color: context.tioColors.textSecondary),
                )
              : _DottedAddRoutineCard(
                  key: ValueKey(
                    'library-add-routine-${widget.program.id.value}',
                  ),
                  onPressed: _openingCreate || widget.disableAddRoutine
                      ? null : _addRoutine,
                );
        } else {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final routine in state.routines)
                Padding(
                  key: ValueKey(
                    'library-routine-${widget.program.id.value}-${routine.id.value}',
                  ),
                  padding: const EdgeInsets.only(bottom: TioSpacing.sm),
                  child: RoutineMetadataCard(
                    routine: routine,
                    onTap: widget.onRoutinePressed == null
                        ? null
                        : () { widget.onRoutinePressed!(routine); },
                    onEdit: widget.onEditRoutine == null
                        ? null
                        : () { widget.onEditRoutine!(routine); },
                    actionSheetGuard: widget.actionSheetGuard,
                    onMove: widget.onMoveRoutine == null ||
                            widget.hasUnconfirmedCreate
                        ? null
                        : () => _moveRoutine(routine),
                    onDelete: widget.onDeleteRoutine == null ||
                            widget.hasUnconfirmedCreate
                        ? null
                        : () => _deleteRoutine(routine),
                  ),
                ),
            ],
          );
        }
    }
    if (widget.hasUnconfirmedCreate) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Previous Routine save is not confirmed. '
            'Open this Program to check its status.',
            style: TextStyle(color: context.tioColors.textSecondary),
          ),
          if (widget.onOpenProgram != null) ...[
            const SizedBox(height: TioSpacing.sm),
            TioButton.secondary(
              key: ValueKey(
                'library-verify-routine-${widget.program.id.value}',
              ),
              label: 'Open Program to verify save',
              onPressed: widget.onOpenProgram,
            ),
          ],
          const SizedBox(height: TioSpacing.sm),
          content,
        ],
      );
    }
    // All Program-owned content shares the Library's outer horizontal margin.
    // Do not indent saved Routine cards, empty Create, loading or retry states.
    return Padding(
      key: ValueKey('library-routines-${widget.program.id.value}'),
      padding: const EdgeInsets.only(bottom: TioSpacing.sm),
      child: content,
    );
  }
}


/// One-off Program empty-state action. Uses Core tokens without adding a
/// duplicate Card variant for a presentation used in only this Workout flow.
class _DottedAddRoutineCard extends StatelessWidget {
  const _DottedAddRoutineCard({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final foreground =
        onPressed == null ? colors.textSecondary : colors.primary;
    return Material(
      color: TioPalette.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(TioRadius.lg),
        onTap: onPressed,
        child: CustomPaint(
          painter: _DottedOutline(color: colors.outlineStrong),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: TioSpacing.lg,
              horizontal: TioSpacing.lg,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: foreground),
                  const SizedBox(width: TioSpacing.sm),
                  Text(
                    'Add new routine',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foreground,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed border follows the same rounded card shape in all Tio themes.
class _DottedOutline extends CustomPainter {
  const _DottedOutline({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(TioStroke.width1),
          const Radius.circular(TioRadius.lg),
        ),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = TioStroke.width1
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0;
          start < metric.length;
          start += TioSize.dp12) {
        final end = start + TioSize.dp6;
        canvas.drawPath(
          metric.extractPath(
            start,
            end < metric.length ? end : metric.length,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedOutline oldDelegate) =>
      oldDelegate.color != color;
}
