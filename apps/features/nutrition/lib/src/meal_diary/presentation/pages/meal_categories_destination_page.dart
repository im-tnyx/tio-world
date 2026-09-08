import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/models/meal_category.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/usecases/meal_category_id_generator.dart';
import '../controllers/meal_categories_controller.dart';
import '../widgets/meal_category_swipe_row.dart';

/// Meal Categories management.
///
/// Owner-locked shape: one screen, two sections. `ACTIVE` is reorderable and
/// carries rename/archive. `ARCHIVED` is absent entirely until something is
/// archived, is not reorderable, and offers only reactivation. There is no
/// Archived sub-route — this page is the whole surface.
class MealCategoriesDestinationPage extends StatefulWidget {
  const MealCategoriesDestinationPage({
    required this.repository,
    super.key,
    this.idGenerator,
    this.onArchivedPressed,
  });

  /// Supplied by app composition. The feature never reaches for Supabase.
  final MealCategoriesRepository repository;

  /// Overridable so a test can make generated identities deterministic.
  final MealCategoryIdGenerator? idGenerator;

  /// Opens the archived categories destination. Supplied by app composition,
  /// which owns navigation; awaited so the list refreshes if something was
  /// restored while away.
  final Future<void> Function()? onArchivedPressed;

  @override
  State<MealCategoriesDestinationPage> createState() =>
      _MealCategoriesDestinationPageState();
}

class _MealCategoriesDestinationPageState
    extends State<MealCategoriesDestinationPage> {
  /// Owned here rather than built by the route.
  ///
  /// A controller constructed inside a route builder is rebuilt whenever that
  /// builder runs, which would leave this State listening to an instance the
  /// screen no longer reads and would never dispose the ones it dropped.
  late final MealCategoriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MealCategoriesController(
      repository: widget.repository,
      idGenerator: widget.idGenerator,
    );
    _controller.addListener(_onControllerChanged);
    // Read, never write. Opening this screen must not materialise defaults
    // into a user's row; an untouched user keeps inheriting them.
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  /// Which row is currently swiped open. Only one at a time, so revealing a
  /// second action closes the first rather than leaving two armed.
  String? _openRowId;

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _setOpenRow(String? id) {
    if (_openRowId == id) return;
    setState(() => _openRowId = id);
  }

  Future<void> _openArchived() async {
    _setOpenRow(null);
    final open = widget.onArchivedPressed;
    if (open == null) return;
    await open();
    if (mounted) await _controller.load();
  }

  /// Surfaces a failed edit, offering to retry the write itself where the
  /// failure could plausibly be transient. Retrying costs one tap because the
  /// controller kept the attempt — by the time a write fails the name sheet
  /// has closed, and asking the reader to retype is the thing to avoid.
  void _reportFailure() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = _controller.state.actionError;
    if (messenger == null || message == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('meal-categories-action-error'),
          content: Text(message),
          action: _controller.state.canRetryAction
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _controller.retryPendingAction().then((ok) {
                    if (mounted && !ok) _reportFailure();
                  }),
                )
              : null,
        ),
      );
  }

  Future<void> _reportIfFailed(Future<bool> action) async {
    final succeeded = await action;
    if (!mounted || succeeded) return;
    _reportFailure();
  }

  Future<void> _promptRename(MealCategory item) async {
    final value = await _promptForName(
      title: 'Rename category',
      initialValue: item.displayName,
      confirmLabel: 'Save',
    );
    if (value == null || !mounted) return;
    await _reportIfFailed(
      _controller.rename(id: item.id, displayName: value),
    );
  }

  Future<void> _promptAdd() async {
    final value = await _promptForName(
      title: 'Add meal category',
      initialValue: '',
      confirmLabel: 'Add',
    );
    if (value == null || !mounted) return;
    await _reportIfFailed(_controller.addCustom(value));
  }

  /// One editor sheet serves rename and add: both collect a single display
  /// name, and validation belongs to the domain rather than to two near-copies
  /// of the same form.
  ///
  /// The sheet owns its own text controller. Disposing one here on the popped
  /// future tears it down while the sheet is still animating out, and its
  /// field then rebuilds against a disposed controller.
  Future<String?> _promptForName({
    required String title,
    required String initialValue,
    required String confirmLabel,
  }) {
    return showTioEditorSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheetContext) => _NameEditorSheet(
        title: title,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
      ),
    );
  }

  /// Archive is never a side effect of the gesture. The swipe reveals the
  /// action, the action asks, and only a confirmed answer archives.
  Future<void> _confirmArchive(MealCategory item) async {
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      cardKey: const ValueKey('meal-category-archive-confirm'),
      title: 'Archive "${item.displayName}"?',
      message: 'You can restore it later from Archived Meal Categories. Meals '
          'already logged under it keep their category, and archiving frees '
          'one of your 8 active slots.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Archive',
    );
    if (!mounted) return;
    if (confirmed != true) {
      _setOpenRow(null);
      return;
    }
    final succeeded = await _controller.archive(item.id);
    if (!mounted) return;
    _setOpenRow(null);
    if (succeeded) {
      // One confirming tick after a destructive-shaped action lands, matching
      // the repo's restrained haptic use.
      unawaited(HapticFeedback.mediumImpact());
    } else {
      _reportFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final state = _controller.state;

    return Scaffold(
      key: const ValueKey('meal-categories-destination-page'),
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Meal Categories',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
        actions: [
          // Derived from the same configuration the list renders, not a
          // separate flag: the entry exists exactly while something is
          // archived, and disappears again when the last one is restored.
          // Absent rather than disabled, so it leaves no invisible target in
          // the semantics tree either.
          if (state.hasArchivedCategories && widget.onArchivedPressed != null)
            IconButton(
              key: const ValueKey('meal-categories-archived-entry'),
              // Reads as "view what is archived", not "archive this" — the row
              // gesture owns that verb.
              tooltip: 'Archived meal categories',
              onPressed: _openArchived,
              icon: Icon(Icons.inventory_2_outlined, color: colors.textPrimary),
            ),
        ],
      ),
      body: SafeArea(child: _body(state)),
    );
  }

  Widget _body(MealCategoriesState state) {
    switch (state.status) {
      case MealCategoriesStatus.loading:
        return const Center(
          key: ValueKey('meal-categories-loading'),
          child: CircularProgressIndicator(),
        );
      case MealCategoriesStatus.loadFailed:
        return _LoadFailure(
          message: state.loadError ?? 'Could not load meal categories.',
          onRetry: _controller.retryLoad,
        );
      case MealCategoriesStatus.ready:
        return _ready(state);
    }
  }

  Widget _ready(MealCategoriesState state) {
    // Archived categories live behind the top-bar destination now, so this
    // screen is only the active list.
    final active = state.activeItems;
    final enabled = !state.saving;

    // One scroll view for the whole page, with the active list as a sliver
    // inside it. A shrink-wrapped reorderable list nested in another scroll
    // view has no scroll extent of its own, so a drag toward an off-screen
    // position cannot auto-scroll anything — reachable only while every row
    // happens to fit, which eight categories on a short viewport do not.
    return GestureDetector(
      // A tap anywhere else closes a revealed row, so an armed action never
      // sits forgotten under the reader's next interaction.
      behavior: HitTestBehavior.deferToChild,
      onTap: _openRowId == null ? null : () => _setOpenRow(null),
      child: CustomScrollView(
      key: const ValueKey('meal-categories-list'),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.md,
            TioSpacing.lg,
            TioSpacing.none,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              key: ValueKey('meal-categories-active-header'),
              title: 'ACTIVE',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
          sliver: SliverReorderableList(
            key: const ValueKey('meal-categories-active-list'),
            itemCount: active.length,
            // `onReorderItem` already resolves the framework's insertion
            // index, so these are the final positions the controller expects.
            onReorderItem: (oldIndex, newIndex) => _reportIfFailed(
              _controller.reorderActive(
                oldIndex: oldIndex,
                newIndex: newIndex,
              ),
            ),
            itemBuilder: (context, index) {
              final item = active[index];
              final isLast = index == active.length - 1;
              return MealCategorySwipeRow(
                key: ValueKey('meal-category-swipe-${item.id}'),
                enabled: enabled,
                // The last active category cannot be archived, so the gesture
                // does not offer an action that would only be refused.
                actionEnabled: state.canArchive,
                blockedReason: MealCategoriesController.lastActiveReason,
                isOpen: _openRowId == item.id,
                onOpenChanged: (open) => _setOpenRow(open ? item.id : null),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(index == 0 ? TioRadius.lg : 0),
                  bottom: Radius.circular(isLast ? TioRadius.lg : 0),
                ),
                actionKey: ValueKey('meal-category-swipe-action-${item.id}'),
                actionIcon: Icons.archive_outlined,
                actionLabel: 'Archive ${item.displayName}',
                semanticActionLabel: 'Archive meal category',
                onAction: () => _confirmArchive(item),
                child: _ActiveRow(
                  key: ValueKey('meal-category-active-${item.id}'),
                  item: item,
                  index: index,
                  enabled: enabled,
                  isFirst: index == 0,
                  isLast: isLast,
                  onRename: () {
                    _setOpenRow(null);
                    unawaited(_promptRename(item));
                  },
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.md,
            TioSpacing.lg,
            TioSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddCategoryRow(
                  atCap: state.isAtActiveCap,
                  enabled: enabled,
                  onPressed: _promptAdd,
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  const _ActiveRow({
    required this.item,
    required this.index,
    required this.enabled,
    required this.isFirst,
    required this.isLast,
    required this.onRename,
    super.key,
  });

  /// Where the row's content begins: the drag handle plus its gap. The divider
  /// starts here rather than at the card edge so it separates the names
  /// without cutting through the handle column.
  static const double contentInset = TioSize.dp20 + TioSpacing.md;

  final MealCategory item;
  final int index;
  final bool enabled;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    // Disabled controls must look disabled. An explicit icon colour overrides
    // `IconButton`'s disabled `IconTheme`, so during a save these would read
    // as tappable while ignoring taps.
    final actionColor = enabled ? colors.textSecondary : colors.textMuted;

    // Canonical defaults hold a fixed relative order, so they are not
    // draggable and show no grip.
    final isReorderable = item.defaultKey == null;

    // Each row paints its own slice of the group surface, with the corners
    // rounded only at the ends, so the list still reads as one card while
    // living in a sliver that can actually scroll.
    // The surface and its rounding belong to the swipe row, which has to clip
    // the sliding content to the card.
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSpacing.sm,
            ),
            child: Row(
              children: [
                // The handle slot is always occupied, even for a default that
                // has none, so every category name sits in one vertical column
                // instead of jumping left on the fixed rows.
                SizedBox(
                  width: TioSize.dp20,
                  child: !isReorderable
                      // Deliberately empty rather than a disabled handle: a
                      // greyed-out grip still reads as "drag me", and these
                      // rows genuinely cannot move.
                      ? const SizedBox.shrink()
                      : ReorderableDragStartListener(
                  index: index,
                  enabled: enabled,
                  child: Semantics(
                    // `container: true` because the child is a bare Icon and
                    // produces no semantics node of its own, so without it
                    // this label would have nothing to attach to.
                    container: true,
                    label: 'Reorder ${item.displayName}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      // One tick as the drag begins. The reorderable list
                      // itself emits none, and a silent drag start reads as an
                      // unresponsive handle.
                      onVerticalDragStart:
                          enabled ? (_) => HapticFeedback.selectionClick() : null,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: TioSpacing.sm),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          key: ValueKey('meal-category-drag-${item.id}'),
                          size: TioSize.dp20,
                          color:
                              enabled ? colors.textMuted : colors.outlineStrong,
                        ),
                      ),
                    ),
                  ),
                ),
                ),
                const SizedBox(width: TioSpacing.md),
                Expanded(
                  // The durable id and defaultKey are never rendered.
                  child: Text(
                    item.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled ? colors.textPrimary : colors.textMuted,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('meal-category-rename-${item.id}'),
                  tooltip: 'Edit ${item.displayName}',
                  onPressed: enabled ? onRename : null,
                  icon: Icon(Icons.edit_outlined, color: actionColor),
                ),
              ],
            ),
          ),
          // No rule under the final row: the card's own edge ends the list.
          if (!isLast)
            Divider(
              key: ValueKey('meal-category-divider-${item.id}'),
              height: TioStroke.width1,
              thickness: TioStroke.width1,
              indent: TioSpacing.lg + contentInset,
              endIndent: TioSpacing.lg,
              color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
            ),
      ],
    );
  }
}

class _AddCategoryRow extends StatelessWidget {
  const _AddCategoryRow({
    required this.atCap,
    required this.enabled,
    required this.onPressed,
  });

  final bool atCap;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TioButton.secondary(
          key: const ValueKey('meal-categories-add'),
          label: 'Add Meal Category',
          onPressed: enabled && !atCap ? onPressed : null,
        ),
        if (atCap)
          Padding(
            padding: const EdgeInsets.only(
              top: TioSpacing.sm,
              left: TioSpacing.sm,
            ),
            child: Text(
              MealCategoriesController.activeCapReason,
              key: const ValueKey('meal-categories-add-cap-reason'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: TioFontSize.size12,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.only(
        left: TioSpacing.sm,
        bottom: TioSpacing.sm,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontWeight: TioFontWeight.w700,
          fontSize: TioFontSize.size11,
          letterSpacing: TioLetterSpacing.positive08,
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Center(
      key: const ValueKey('meal-categories-load-failure'),
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
              key: const ValueKey('meal-categories-retry'),
              label: 'Try again',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _NameEditorSheet extends StatefulWidget {
  const _NameEditorSheet({
    required this.title,
    required this.confirmLabel,
    required this.initialValue,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;

  @override
  State<_NameEditorSheet> createState() => _NameEditorSheetState();
}

class _NameEditorSheetState extends State<_NameEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    // Blank is the one rejection worth pre-empting here, because it is about
    // an empty field rather than a rule. Everything else — normalized
    // duplicates included — stays with the domain so one algorithm decides.
    final canSubmit = _controller.text.trim().isNotEmpty;

    return TioEditorSheet(
      title: widget.title,
      content: TioInput(
        key: const ValueKey('meal-category-name-field'),
        controller: _controller,
        onChanged: (_) {},
        hint: 'Category name',
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: TioButton.primary(
        key: const ValueKey('meal-category-name-submit'),
        label: widget.confirmLabel,
        onPressed: canSubmit ? _submit : null,
      ),
    );
  }
}
