import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/detailed_meal_log_create_repository.dart';
import '../../meal_editor_create_controller.dart';
import '../../meal_editor_detailed_create_controller.dart';
import '../widgets/meal_log_action_footer.dart';

/// Full-screen create-mode Meal Editor body for a provider-neutral draft.
///
/// The editor keeps correction state local until the user explicitly presses
/// `Log Meal`. Durable detailed persistence is delegated to the dedicated
/// submission controller, while this widget remains responsible only for
/// rendering state and emitting user actions.
class MealEditorCreatePage extends StatefulWidget {
  const MealEditorCreatePage({
    required this.initialDraft,
    required this.mealCategoryLabel,
    required this.dateTimeLabel,
    super.key,
    this.mealCategoryId,
    this.consumedLocalDateTime,
    this.detailedCreateRepository,
    this.onCreated,
    this.onBack,
    this.onMealCategoryTap,
    this.onDateTimeTap,
  });

  final MealLoggingDraft initialDraft;
  final String mealCategoryLabel;
  final String dateTimeLabel;
  final String? mealCategoryId;
  final DateTime? consumedLocalDateTime;
  final DetailedMealLogCreateRepository? detailedCreateRepository;
  final ValueChanged<MealLogEntry>? onCreated;
  final VoidCallback? onBack;
  final VoidCallback? onMealCategoryTap;
  final VoidCallback? onDateTimeTap;

  @override
  State<MealEditorCreatePage> createState() => _MealEditorCreatePageState();
}

class _MealEditorCreatePageState extends State<MealEditorCreatePage> {
  late final MealEditorCreateController _controller;
  late final TextEditingController _mealNameController;
  MealEditorDetailedCreateController? _submitController;

  @override
  void initState() {
    super.initState();
    _controller = MealEditorCreateController(initialDraft: widget.initialDraft)
      ..addListener(_handleDraftChanged);
    _mealNameController = TextEditingController(
      text: widget.initialDraft.mealName ?? '',
    );
    final repository = widget.detailedCreateRepository;
    if (repository != null) {
      _submitController = MealEditorDetailedCreateController(
        repository: repository,
      )..addListener(_handleSubmitStateChanged);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleDraftChanged)
      ..dispose();
    _submitController
      ?..removeListener(_handleSubmitStateChanged)
      ..dispose();
    _mealNameController.dispose();
    super.dispose();
  }

  void _handleDraftChanged() {
    _submitController?.draftChanged();
  }

  void _handleSubmitStateChanged() {
    if (mounted) setState(() {});
  }

  MealEditorDetailedCreateContext? get _submitContext {
    final mealCategoryId = widget.mealCategoryId;
    final consumedLocalDateTime = widget.consumedLocalDateTime;
    if (mealCategoryId == null || consumedLocalDateTime == null) return null;
    return MealEditorDetailedCreateContext(
      mealCategoryId: mealCategoryId,
      consumedLocalDateTime: consumedLocalDateTime,
    );
  }

  Future<void> _submit() async {
    final submitController = _submitController;
    final context = _submitContext;
    if (submitController == null || context == null) return;
    final entry = await submitController.submit(
      draft: _controller.draft,
      context: context,
    );
    if (!mounted || entry == null) return;
    widget.onCreated?.call(entry);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final submitController = _submitController;
    final submitContext = _submitContext;
    final submitState = submitController?.state;
    final draftLocked = submitState?.locksDraft ?? false;
    final canSubmit = submitController != null &&
        submitContext != null &&
        submitController.canSubmit(
          draft: _controller.draft,
          context: submitContext,
        );

    return PopScope(
      canPop: !draftLocked,
      child: Scaffold(
        key: const ValueKey('meal-editor-create-page'),
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          leading: BackButton(
            color: colors.textPrimary,
            onPressed: draftLocked ? null : widget.onBack,
          ),
          title: Text(
            'Log your meal',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w800,
              fontSize: TioFontSize.size20,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => ListView(
              key: const ValueKey('meal-editor-create-body'),
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.md,
                TioSpacing.lg,
                TioSpacing.xl,
              ),
              children: [
                TioInput.multiline(
                  key: const ValueKey('meal-editor-meal-name'),
                  controller: _mealNameController,
                  hint: 'Meal name',
                  minLines: 1,
                  maxLines: 2,
                  enabled: !draftLocked,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onChanged: _controller.updateMealName,
                ),
                const SizedBox(height: TioSpacing.xl),
                _NutritionSummary(summary: _controller.nutritionSummary),
                const SizedBox(height: TioSpacing.xl),
                _SectionHeader(itemCount: _controller.items.length),
                const SizedBox(height: TioSpacing.md),
                for (var index = 0;
                    index < _controller.items.length;
                    index++) ...[
                  _MealEditorItemCard(
                    index: index,
                    item: _controller.items[index],
                    canIncrement: !draftLocked &&
                        _controller.canIncrementQuantity(index),
                    canDecrement: !draftLocked &&
                        _controller.canDecrementQuantity(index),
                    canDelete:
                        !draftLocked && _controller.canRemoveItem(index),
                    onIncrement: () => _controller.incrementQuantity(index),
                    onDecrement: () => _controller.decrementQuantity(index),
                    onDelete: () => _controller.removeItem(index),
                  ),
                  if (index != _controller.items.length - 1)
                    const SizedBox(height: TioSpacing.md),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: ColoredBox(
            color: colors.background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                0,
                TioSpacing.lg,
                TioSpacing.md,
              ),
              child: MealLogActionFooter(
                mealCategoryLabel: widget.mealCategoryLabel,
                mealCategorySemanticLabel:
                    'Meal type. ${widget.mealCategoryLabel}.',
                onMealCategoryTap:
                    draftLocked ? null : widget.onMealCategoryTap,
                dateTimeLabel: widget.dateTimeLabel,
                dateTimeSemanticLabel:
                    'Date and time. ${widget.dateTimeLabel}.',
                onDateTimeTap: draftLocked ? null : widget.onDateTimeTap,
                primaryLabel: 'Log Meal',
                primarySemanticLabel: submitState?.isOutcomeUnknown == true
                    ? 'Retry Log Meal. Save status is uncertain.'
                    : canSubmit
                        ? 'Log Meal.'
                        : 'Log Meal. Review the meal details before saving.',
                note: submitState?.message,
                primaryLoading: submitState?.isSubmitting ?? false,
                primaryLoadingLabel: 'Logging meal',
                onPrimaryPressed: canSubmit ? _submit : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({required this.summary});

  final MealEditorNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioCard(
      key: const ValueKey('meal-editor-nutrition-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TOTAL CALORIES',
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: TioFontWeight.w700,
            ),
          ),
          const SizedBox(height: TioSpacing.xs),
          Text(
            _formatEnergy(summary.energyKcal),
            key: const ValueKey('meal-editor-total-calories'),
            style: textTheme.headlineMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w800,
            ),
          ),
          const SizedBox(height: TioSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MacroMetric(
                  label: 'Protein',
                  value: _formatGrams(summary.proteinGrams),
                  valueKey: const ValueKey('meal-editor-total-protein'),
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: _MacroMetric(
                  label: 'Carbs',
                  value: _formatGrams(summary.carbohydrateGrams),
                  valueKey: const ValueKey('meal-editor-total-carbs'),
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: _MacroMetric(
                  label: 'Fat',
                  value: _formatGrams(summary.fatGrams),
                  valueKey: const ValueKey('meal-editor-total-fat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroMetric extends StatelessWidget {
  const _MacroMetric({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: TioSpacing.xs),
        Text(
          value,
          key: valueKey,
          style: textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Items',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w800,
            ),
          ),
        ),
        Text(
          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
          key: const ValueKey('meal-editor-item-count'),
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _MealEditorItemCard extends StatelessWidget {
  const _MealEditorItemCard({
    required this.index,
    required this.item,
    required this.canIncrement,
    required this.canDecrement,
    required this.canDelete,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  final int index;
  final MealLoggingDraftItem item;
  final bool canIncrement;
  final bool canDecrement;
  final bool canDelete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final snapshot = item.consumedNutritionSnapshot;
    final energy = snapshot?.amountFor(NutrientId.energy);
    final protein = snapshot?.amountFor(NutrientId.protein);

    return TioCard(
      key: ValueKey('meal-editor-item-$index'),
      variant: TioCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      key: ValueKey('meal-editor-item-name-$index'),
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.xs),
                    Text(
                      '${_formatEnergy(energy)} · ${_formatGrams(protein)} protein',
                      key: ValueKey('meal-editor-item-nutrition-$index'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('meal-editor-delete-$index'),
                tooltip: canDelete
                    ? 'Delete ${item.displayName}'
                    : 'At least one item is required',
                onPressed: canDelete ? onDelete : null,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: canDelete ? colors.danger : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.md),
          Wrap(
            spacing: TioSpacing.md,
            runSpacing: TioSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (item.quantity == null)
                Text(
                  'Quantity unknown',
                  key: ValueKey('meal-editor-quantity-unknown-$index'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                Semantics(
                  label:
                      'Quantity ${_formatNumber(item.quantity!)}${item.servingUnit == null ? '' : ' ${item.servingUnit}'}.',
                  container: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: ValueKey('meal-editor-quantity-minus-$index'),
                        tooltip: 'Decrease quantity',
                        onPressed: canDecrement ? onDecrement : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text(
                        _formatNumber(item.quantity!),
                        key: ValueKey('meal-editor-quantity-$index'),
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                        ),
                      ),
                      IconButton(
                        key: ValueKey('meal-editor-quantity-plus-$index'),
                        tooltip: 'Increase quantity',
                        onPressed: canIncrement ? onIncrement : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              Text(
                item.servingUnit == null
                    ? 'Unit unknown'
                    : 'Unit: ${item.servingUnit}',
                key: ValueKey('meal-editor-serving-unit-$index'),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatEnergy(num? value) =>
    value == null ? '— kcal' : '${_formatNumber(value)} kcal';

String _formatGrams(num? value) =>
    value == null ? '— g' : '${_formatNumber(value)} g';

String _formatNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}
