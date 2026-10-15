import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_repository.dart';
import 'program_routines_controller.dart';
import 'routine_metadata_card.dart';

/// Read-only, owner-filtered Routine children under an expanded Library Program.
/// Program Detail owns create/rename; Library never owns another Routine truth.
class InlineProgramRoutines extends StatefulWidget {
  const InlineProgramRoutines({
    required this.program,
    required this.repository,
    required this.refreshVersion,
    this.onRoutinePressed,
    this.onAddRoutine,
    super.key,
  });

  final Program program;
  final RoutineRepository? repository;
  final int refreshVersion;
  final Future<void> Function(Routine routine)? onRoutinePressed;
  /// Opens canonical Create for this exact Program; injected by app shell.
  final Future<void> Function()? onAddRoutine;

  @override
  State<InlineProgramRoutines> createState() => _InlineProgramRoutinesState();
}

class _InlineProgramRoutinesState extends State<InlineProgramRoutines> {
  ProgramRoutinesController? _controller;
  bool _openingCreate = false;

  Future<void> _addRoutine() async {
    final add = widget.onAddRoutine;
    final controller = _controller;
    if (_openingCreate || add == null || controller == null ||
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
                  onPressed: _openingCreate ? null : _addRoutine,
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
                  ),
                ),
            ],
          );
        }
    }
    // Only the empty Create card aligns with the Library's outer margins.
    // Saved Routine cards keep their existing child indentation.
    final fullWidthEmptyCreate =
        state.status == ProgramRoutinesStatus.ready &&
        state.routines.isEmpty &&
        widget.onAddRoutine != null;
    return Padding(
      key: ValueKey('library-routines-${widget.program.id.value}'),
      padding: EdgeInsetsDirectional.only(
        start: fullWidthEmptyCreate ? 0 : TioSpacing.xl,
        bottom: TioSpacing.sm,
      ),
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
      ..strokeWidth = TioStroke.width2
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
