import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/repositories/routine_composition_repository.dart';
import '../../widgets/workout_exercise_card.dart';

export '../../widgets/workout_exercise_card.dart';

class RoutineComposerScreen extends StatefulWidget {
  const RoutineComposerScreen({
    required this.mode,
    required this.pageKey,
    required this.cancelKey,
    required this.cancel,
    required this.cancelEnabled,
    required this.content,
    this.submitKey,
    this.onSubmit,
    super.key,
  });

  final RoutineComposerMode mode;
  final Key pageKey;
  final Key cancelKey;
  final VoidCallback? cancel;
  final bool cancelEnabled;
  final Widget content;
  final Key? submitKey;
  final VoidCallback? onSubmit;

  @override
  State<RoutineComposerScreen> createState() => _RoutineComposerScreenState();
}

/// Keep the focus policy for both builder modes in one screen.
/// Mobile keyboard Back can hide the IME while leaving a numeric field focused.
class _RoutineComposerScreenState extends State<RoutineComposerScreen>
    with WidgetsBindingObserver {
  double? _previousKeyboardInset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial keyboard absence is not a dismissal event.
    _previousKeyboardInset ??= View.of(context).viewInsets.bottom;
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final keyboardInset = View.of(context).viewInsets.bottom;
    final previousInset = _previousKeyboardInset;
    _previousKeyboardInset = keyboardInset;

    // Do not dismiss another route's input (e.g. the Exercise picker).
    if (previousInset != null &&
        previousInset > 0 &&
        keyboardInset == 0 &&
        ModalRoute.of(context)?.isCurrent == true) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isEdit = widget.mode == RoutineComposerMode.edit;
    return Scaffold(
      key: widget.pageKey,
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: widget.cancelKey,
          tooltip: 'Cancel',
          onPressed: widget.cancelEnabled ? widget.cancel : null,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          isEdit ? 'Edit Routine' : 'Create Routine',
          key: const ValueKey('routine-composer-title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioFontSize.size18,
            fontWeight: TioFontWeight.w800,
          ),
        ),
        actions: [
          // Identical submit position; Create/Edit adapters retain guarded
          // persistence and submit availability.
          if (isEdit && widget.submitKey == null)
            const SizedBox(width: TioSize.dp64)
          else
            TextButton(
              key: widget.submitKey,
              onPressed: widget.onSubmit,
              child: Text(isEdit ? 'Update' : 'Save'),
            ),
        ],
      ),
      body: SafeArea(child: widget.content),
    );
  }
}

/// The only Routine builder scroll/reorder composition.
/// Callers supply controller-owned data and callbacks, not duplicate layout.
class RoutineComposerContent extends StatelessWidget {
  const RoutineComposerContent({
    required this.mode,
    required this.scrollKey,
    required this.reorderKey,
    required this.header,
    required this.entries,
    required this.itemBuilder,
    required this.onReorder,
    required this.footer,
    super.key,
  });

  final RoutineComposerMode mode;
  final Key scrollKey;
  final Key reorderKey;
  final Widget header;
  final List<RoutineCompositionEntry> entries;
  final Widget Function(RoutineCompositionEntry entry, int index) itemBuilder;
  final void Function(int from, int to) onReorder;
  final Widget footer;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        key: scrollKey,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              TioSpacing.lg,
              // Identical top Name field position in Create and Edit.
              TioSpacing.xl,
              TioSpacing.lg,
              TioSpacing.none,
            ),
            sliver: SliverToBoxAdapter(child: header),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
            sliver: SliverReorderableList(
              key: reorderKey,
              itemCount: entries.length,
              // Preserve Material for the controls while a row is in Overlay.
              proxyDecorator: (child, _, __) => Material(
                type: MaterialType.transparency,
                child: child,
              ),
              onReorderStart: (_) => unawaited(HapticFeedback.mediumImpact()),
              onReorderEnd: (_) => unawaited(HapticFeedback.selectionClick()),
              onReorderItem: onReorder,
              itemBuilder: (context, index) =>
                  itemBuilder(entries[index], index),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              TioSpacing.lg,
              TioSpacing.none,
              TioSpacing.lg,
              TioSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(child: footer),
          ),
        ],
      );
}
