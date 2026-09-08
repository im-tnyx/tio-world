import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/models/meal_category.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../presentation/widgets/nutrition_settings_widgets.dart';
import '../../../domain/usecases/meal_category_id_generator.dart';
import '../controllers/meal_categories_controller.dart';
import '../widgets/meal_category_glyph.dart';
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
      // Its own current name is not a clash with itself.
      validate: (name) => _controller.validateDisplayName(
        value: name,
        excludingId: item.id,
      ),
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
      validate: (name) => _controller.validateDisplayName(value: name),
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
    required String? Function(String value) validate,
  }) {
    return showTioEditorSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheetContext) => _NameEditorSheet(
        title: title,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
        validate: validate,
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
              // Unavailable while a write is in flight. The entry appears as
              // soon as an archive is shown optimistically, but the archived
              // destination builds its own controller and reads the
              // repository, which until the write lands still holds the
              // previous configuration — so an early tap would arrive at a
              // screen saying nothing is archived, and it would not refresh
              // when the write completed.
              onPressed: state.saving ? null : _openArchived,
              icon: Icon(
                Icons.inventory_2_outlined,
                color: state.saving ? colors.textMuted : colors.textPrimary,
              ),
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
          sliver: SliverToBoxAdapter(child: _PageDescription()),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.lg,
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
            // One firm tick as the row is picked up and a light one as it
            // lands. Emitted by the list rather than by either drag starter,
            // so a lift feels identical whether it came from the grip or from
            // a long press on the row, and so it fires when the drag actually
            // begins rather than when a gesture that may still lose the arena
            // does.
            onReorderStart: (_) => unawaited(HapticFeedback.mediumImpact()),
            onReorderEnd: (_) => unawaited(HapticFeedback.selectionClick()),
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
                  // Two different ceilings can stop an add. The active one is
                  // checked first: it is the common case, and it is the one a
                  // reader can clear by archiving something.
                  capReason: state.isAtActiveCap
                      ? MealCategoriesController.activeCapReason
                      : state.isAtRetainedCap
                          ? MealCategoriesController.retainedCapReason
                          : null,
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
                Expanded(
                  // A long press anywhere across the row lifts it, so the grip
                  // is a shortcut rather than the only way in. The pencil sits
                  // outside this region on purpose: long-pressing a button
                  // should not pick the row up.
                  child: ReorderableDelayedDragStartListener(
                    index: index,
                    enabled: isReorderable && enabled,
                    child: ColoredBox(
                      // Hit-testable, not decorative. The listener defers to
                      // its child, so without a surface the band above and
                      // below the name is inert and a long press landing a few
                      // pixels off the glyphs would do nothing at all.
                      color: TioPalette.transparent,
                      child: ConstrainedBox(
                        // The pencil's target height, so the whole row answers
                        // a long press rather than just the text's line box.
                        constraints: const BoxConstraints(
                          minHeight: kMinInteractiveDimension,
                        ),
                        child: Row(
                          children: [
                            // The leading column is occupied on every row, so
                            // category names sit in one vertical alignment and
                            // no row reads as missing something.
                            SizedBox(
                              width: MealCategoryGlyph.columnWidth,
                              // A grip on the rows that can move, the
                              // category's own glyph on the four that cannot.
                              // Never a disabled grip: it would still read as
                              // "drag me".
                              child: isReorderable
                                  ? _DragHandle(
                                      item: item,
                                      index: index,
                                      enabled: enabled,
                                    )
                                  : MealCategoryGlyph(
                                      item: item,
                                      enabled: enabled,
                                    ),
                            ),
                            const SizedBox(width: TioSpacing.md),
                            Expanded(
                              // The durable id and defaultKey are never
                              // rendered.
                              child: Text(
                                item.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: enabled
                                      ? colors.textPrimary
                                      : colors.textMuted,
                                  fontWeight: TioFontWeight.w700,
                                  fontSize: TioFontSize.size15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // The Settings edit affordance the rest of Nutrition already
                // uses, rather than a third bare pencil. The shared component
                // takes no key, tooltip or disabled state, so those are
                // composed here instead of forking its visuals.
                Tooltip(
                  message: 'Edit ${item.displayName}',
                  child: SizedBox(
                    // The circle is 36dp by design; the target around it is
                    // not, so it keeps a legal 48dp touch area.
                    width: kMinInteractiveDimension,
                    height: kMinInteractiveDimension,
                    child: Center(
                      child: enabled
                          ? NutritionEditPencil(
                              key: ValueKey('meal-category-rename-${item.id}'),
                              onPressed: onRename,
                            )
                          : Opacity(
                              opacity: TioOpacity.opacity64,
                              child: IgnorePointer(
                                child: NutritionEditPencil(
                                  key: ValueKey(
                                    'meal-category-rename-${item.id}',
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ),
                    ),
                  ),
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
              // Inset at the start, flush at the end. The rule separates the
              // names, so it begins where they do; stopping it short of the
              // card's edge left a gap that read as the line failing to reach
              // rather than as a deliberate inset.
              endIndent: TioSpacing.none,
              color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
            ),
      ],
    );
  }
}

/// The grip a custom category carries.
///
/// Present only on rows that can actually move: a greyed-out handle on a fixed
/// row still reads as "drag me". It starts the drag immediately, where a long
/// press on the row body has to wait out the press delay first.
class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.item,
    required this.index,
    required this.enabled,
  });

  final MealCategory item;
  final int index;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return ReorderableDragStartListener(
      index: index,
      enabled: enabled,
      child: Semantics(
        // `container: true` because the child is a bare Icon and produces no
        // semantics node of its own, so without it this label would have
        // nothing to attach to.
        container: true,
        label: 'Reorder ${item.displayName}',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
          child: Icon(
            Icons.drag_handle_rounded,
            key: ValueKey('meal-category-drag-${item.id}'),
            size: TioSize.dp20,
            color: enabled ? colors.textMuted : colors.outlineStrong,
          ),
        ),
      ),
    );
  }
}

class _AddCategoryRow extends StatelessWidget {
  const _AddCategoryRow({
    required this.capReason,
    required this.enabled,
    required this.onPressed,
  });

  /// Why adding is unavailable, or null when it is available. The reason is
  /// passed rather than a flag because there is more than one ceiling and the
  /// reader needs to know which one they met.
  final String? capReason;
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
          // Full width, matching the card it follows. Hugging its label left
          // the button floating in the left half of an otherwise full-width
          // column, which read as an aside rather than as this screen's one
          // way to add something.
          expand: true,
          onPressed: enabled && capReason == null ? onPressed : null,
        ),
        if (capReason != null)
          Padding(
            padding: const EdgeInsets.only(
              top: TioSpacing.sm,
              left: TioSpacing.sm,
            ),
            child: Text(
              capReason!,
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

/// What this screen is for, and the one rule a reader would otherwise have to
/// discover by having an action refused.
///
/// Outside the card on purpose: it describes the screen rather than belonging
/// to any category, and the card is the list.
class _PageDescription extends StatelessWidget {
  const _PageDescription();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Padding(
      padding: const EdgeInsets.only(left: TioSpacing.sm, right: TioSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // "Custom categories" rather than "categories": the canonical four
            // are deliberately fixed, and the shorter phrasing would promise
            // something the screen refuses.
            'Customize the meal categories shown in your diary. Rename '
                'categories, add your own, or archive ones you no longer use. '
                'Custom categories can be reordered.',
            key: const ValueKey('meal-categories-description'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size14,
              height: TioLineHeight.height145,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          Text(
            // Informational, not an error: it is true before anything goes
            // wrong, so it takes muted text rather than the danger colour.
            'At least one meal category must remain active.',
            key: const ValueKey('meal-categories-minimum-note'),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: TioFontSize.size12,
              height: TioLineHeight.height145,
            ),
          ),
        ],
      ),
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
    required this.validate,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;

  /// Why this name cannot be used, or null when it can.
  ///
  /// Run here rather than after the sheet closes. A duplicate name is a
  /// deterministic answer the screen already had — reporting it afterwards
  /// costs the reader everything they typed and gives them no way back to it.
  final String? Function(String value) validate;

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

  /// Set when a submit was refused, cleared as soon as the reader edits.
  String? _error;

  void _onChanged() {
    if (!mounted) return;
    // The message described the text as it was; it stops being true the
    // moment that text changes.
    setState(() => _error = null);
  }

  void _submit() {
    final value = _controller.text;
    final error = widget.validate(value);
    if (error != null) {
      // Stay open, holding what was typed, and say why. The reader corrects
      // it in place and submits again.
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    // Submit stays reachable for anything non-blank, because a refusal now
    // explains itself rather than leaving a dead button with no reason.
    final canSubmit = _controller.text.trim().isNotEmpty;

    return TioEditorSheet(
      title: widget.title,
      content: TioInput(
        key: const ValueKey('meal-category-name-field'),
        controller: _controller,
        onChanged: (_) {},
        hint: 'Category name',
        errorText: _error,
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
