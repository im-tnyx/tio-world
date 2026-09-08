import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/models/meal_category.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/usecases/meal_category_id_generator.dart';
import '../controllers/meal_categories_controller.dart';

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
  });

  /// Supplied by app composition. The feature never reaches for Supabase.
  final MealCategoriesRepository repository;

  /// Overridable so a test can make generated identities deterministic.
  final MealCategoryIdGenerator? idGenerator;

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

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _showActionError(String message) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reportIfFailed(Future<bool> action) async {
    final succeeded = await action;
    if (!mounted || succeeded) return;
    final message = _controller.state.actionError;
    if (message != null) await _showActionError(message);
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

  Future<void> _confirmArchive(MealCategory item) async {
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      cardKey: const ValueKey('meal-category-archive-confirm'),
      title: 'Archive ${item.displayName}?',
      message: 'It stops appearing as a meal category you can pick, and frees '
          'one of your 8 active slots. Meals already logged under it keep '
          'their category, and you can reactivate it later.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Archive',
    );
    if (confirmed != true || !mounted) return;
    await _reportIfFailed(_controller.archive(item.id));
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
    final archived = state.archivedItems;

    return ListView(
      key: const ValueKey('meal-categories-list'),
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md,
      ),
      children: [
        const _SectionHeader(
          key: ValueKey('meal-categories-active-header'),
          title: 'ACTIVE',
        ),
        _ActiveSection(
          items: state.activeItems,
          enabled: !state.saving,
          onRename: _promptRename,
          onArchive: _confirmArchive,
          onReorder: (oldIndex, newIndex) => _reportIfFailed(
            _controller.reorderActive(oldIndex: oldIndex, newIndex: newIndex),
          ),
        ),
        const SizedBox(height: TioSpacing.md),
        _AddCategoryRow(
          atCap: state.isAtActiveCap,
          enabled: !state.saving,
          onPressed: _promptAdd,
        ),
        // The Archived section does not exist until something is archived.
        // An always-present empty section would advertise a state most users
        // never reach.
        if (archived.isNotEmpty) ...[
          const SizedBox(height: TioSpacing.xl),
          const _SectionHeader(
            key: ValueKey('meal-categories-archived-header'),
            title: 'ARCHIVED',
          ),
          _ArchivedSection(
            items: archived,
            atCap: state.isAtActiveCap,
            enabled: !state.saving,
            onReactivate: (item) =>
                _reportIfFailed(_controller.reactivate(item.id)),
          ),
        ],
      ],
    );
  }
}

class _ActiveSection extends StatelessWidget {
  const _ActiveSection({
    required this.items,
    required this.enabled,
    required this.onRename,
    required this.onArchive,
    required this.onReorder,
  });

  final List<MealCategory> items;
  final bool enabled;
  final ValueChanged<MealCategory> onRename;
  final ValueChanged<MealCategory> onArchive;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return TioGroupCard(
      children: [
        ReorderableListView(
          key: const ValueKey('meal-categories-active-list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: onReorder,
          children: [
            for (var index = 0; index < items.length; index++)
              _ActiveRow(
                key: ValueKey('meal-category-active-${items[index].id}'),
                item: items[index],
                index: index,
                enabled: enabled,
                onRename: () => onRename(items[index]),
                onArchive: () => onArchive(items[index]),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActiveRow extends StatelessWidget {
  const _ActiveRow({
    required this.item,
    required this.index,
    required this.enabled,
    required this.onRename,
    required this.onArchive,
    super.key,
  });

  final MealCategory item;
  final int index;
  final bool enabled;
  final VoidCallback onRename;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.sm,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            enabled: enabled,
            child: Semantics(
              // `container: true` because the child is a bare Icon and
              // produces no semantics node of its own, so without it this
              // label would have nothing to attach to.
              container: true,
              label: 'Reorder ${item.displayName}',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
                child: Icon(
                  Icons.drag_handle_rounded,
                  key: ValueKey('meal-category-drag-${item.id}'),
                  size: TioSize.dp20,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: TioSpacing.md),
          Expanded(
            // The durable id and defaultKey are deliberately never rendered.
            child: Text(
              item.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w700,
                fontSize: TioFontSize.size15,
              ),
            ),
          ),
          IconButton(
            key: ValueKey('meal-category-rename-${item.id}'),
            tooltip: 'Rename ${item.displayName}',
            onPressed: enabled ? onRename : null,
            icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
          ),
          IconButton(
            key: ValueKey('meal-category-archive-${item.id}'),
            tooltip: 'Archive ${item.displayName}',
            onPressed: enabled ? onArchive : null,
            icon: Icon(Icons.archive_outlined, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({
    required this.items,
    required this.atCap,
    required this.enabled,
    required this.onReactivate,
  });

  final List<MealCategory> items;
  final bool atCap;
  final bool enabled;
  final ValueChanged<MealCategory> onReactivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return TioGroupCard(
      children: [
        for (final item in items)
          Padding(
            key: ValueKey('meal-category-archived-${item.id}'),
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSpacing.sm,
            ),
            // `Wrap` rather than `Row`: the name and the action share a line
            // whenever they fit, and fall onto two lines when they cannot —
            // at 320dp with a large text scale they genuinely cannot, and a
            // truncated action label would be worse than a second line.
            // `TioGroupCard` centres loose children, so the row is stretched
            // to the card's width and left-aligns like the active rows.
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: TioSpacing.md,
                children: [
                  // No drag handle: order is meaningful only among active
                  // categories, so an archived row has nothing to reorder.
                  Text(
                    item.displayName,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                  TioButton.ghost(
                    key: ValueKey('meal-category-reactivate-${item.id}'),
                    label: 'Reactivate',
                    onPressed:
                        enabled && !atCap ? () => onReactivate(item) : null,
                  ),
                ],
              ),
            ),
          ),
        if (atCap)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TioSpacing.lg,
              TioSpacing.none,
              TioSpacing.lg,
              TioSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                MealCategoriesController.activeCapReason,
                key: const ValueKey('meal-categories-reactivate-cap-reason'),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: TioFontSize.size12,
                ),
              ),
            ),
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
