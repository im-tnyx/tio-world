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
    super.key,
  });

  final Program program;
  final RoutineRepository? repository;
  final int refreshVersion;
  final Future<void> Function(Routine routine)? onRoutinePressed;

  @override
  State<InlineProgramRoutines> createState() => _InlineProgramRoutinesState();
}

class _InlineProgramRoutinesState extends State<InlineProgramRoutines> {
  ProgramRoutinesController? _controller;

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
          content = Text(
            'No routines yet',
            style: TextStyle(color: context.tioColors.textSecondary),
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
    return Padding(
      key: ValueKey('library-routines-${widget.program.id.value}'),
      padding: const EdgeInsetsDirectional.only(
        start: TioSpacing.xl,
        bottom: TioSpacing.sm,
      ),
      child: content,
    );
  }
}
