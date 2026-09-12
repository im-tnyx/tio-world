import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/repositories/meal_log_repository.dart';
import '../../../domain/usecases/meal_category_time_suggestion.dart';
import '../../../meal_diary/presentation/controllers/meal_categories_controller.dart';
import '../../quick_add_meal_log_create_controller.dart';
import '../../quick_add_meal_log_edit_controller.dart';
import 'meal_category_picker_popup.dart';
import 'meal_log_action_footer.dart';

/// Opens a brand-new Quick Add manual nutrition editor.
Future<MealLogEntry?> showQuickAddEditorSheet(
  BuildContext context, {
  DateTime Function()? clock,
  MealCategoriesRepository? mealCategoriesRepository,
  MealLogRepository? mealLogRepository,
  MealLogEntry? initialEntry,
}) {
  return showTioEditorSheet<MealLogEntry>(
    context: context,
    // Same reason as the Add Food sheet: the diary sits inside a shell branch
    // navigator, and an editor holding a captured date must not leave the
    // Today action or the tabs reachable behind it.
    useRootNavigator: true,
    // And the same reason again for the top: without this the route strips the
    // top padding, so a keyboard-raised or split-screen viewport can push the
    // handle and title under the status bar.
    useSafeArea: true,
    builder: (_) => QuickAddEditorSheet(
      clock: clock,
      mealCategoriesRepository: mealCategoriesRepository,
      mealLogRepository: mealLogRepository,
      initialEntry: initialEntry,
    ),
  );
}

/// The manual/coarse nutrition editor.
///
/// ```text
/// Quick Add
/// ┌────────────────────────────────┐
/// │ Meal name (optional)           │   large, and the only free text
/// └────────────────────────────────┘
/// Calories (kcal)         [      ]
/// Carbs (g)               [      ]
/// Protein (g)             [      ]
/// Fat (g)                 [      ]
/// ─────────────────────────────────   body scrolls, footer does not
/// Meal type ▼        🗓 Sep 6, 00:07
/// [           Log Meal            ]
/// ```
///
/// ## Why this is not the Meal Editor
///
/// Quick Add is for the reader who already knows the numbers and does not want
/// to name a single ingredient. AI, voice, photo, search, repeat and saved
/// meals will all converge on the full Meal Editor through a draft; this screen
/// deliberately does not, because routing it there would make the fastest path
/// wear the slowest screen's chrome. They may share components. They are not
/// the same surface.
///
/// ## Why so few fields
///
/// Fiber and micronutrients were dropped from this shell on owner review. They
/// are not cancelled — TNYX-115 and TNYX-58 can add supported nutrients later
/// through the shared nutrition-value contract — but a coarse entry that asks
/// for seven numbers is not a coarse entry.
///
/// ## Durable create boundary
///
/// The route-local draft stays presentation-owned, but `Log Meal` commits only
/// through [MealLogRepository]. [QuickAddMealLogCreateController] freezes one
/// canonical create input per logical attempt, owns pending/failure state, and
/// preserves the exact mutation identity/payload while an ambiguous server
/// outcome is reconciled. The editor never writes directly to Supabase or a
/// second local store.
///
/// Reopening a brand-new Quick Add takes a fresh current-local DateTime
/// snapshot. Dismissing before a submit still creates nothing.
class QuickAddEditorSheet extends StatefulWidget {
  const QuickAddEditorSheet({
    super.key,
    this.clock,
    this.mealCategoriesRepository,
    this.mealLogRepository,
    this.initialEntry,
  });

  /// Optional local clock seam. Production uses `DateTime.now`.
  final DateTime Function()? clock;

  /// Where the meal categories come from, supplied by app composition.
  ///
  /// Nutrition cannot reach the provider that owns it — the app depends on the
  /// feature, not the reverse — so it arrives the same way the diary's week
  /// start does. Null leaves the Meal type control inert, which is what a
  /// surface with no category source honestly is.
  final MealCategoriesRepository? mealCategoriesRepository;

  /// Canonical actual-history owner supplied by the Diary/app composition.
  ///
  /// Null keeps isolated feature harnesses honest: the editor remains usable as
  /// a draft but cannot claim that a durable meal can be logged.
  final MealLogRepository? mealLogRepository;

  /// Canonical row read immediately before opening an edit. Null is create
  /// mode. The Diary read model is intentionally not accepted here.
  final MealLogEntry? initialEntry;

  @override
  State<QuickAddEditorSheet> createState() => _QuickAddEditorSheetState();
}

class _QuickAddEditorSheetState extends State<QuickAddEditorSheet>
    with WidgetsBindingObserver {
  final _mealCategoryAnchorKey = GlobalKey();
  final _dateTimeAnchorKey = GlobalKey();
  final _mealName = TextEditingController();
  final _calories = TextEditingController();
  final _carbs = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();

  late final List<TextEditingController> _fields = [
    _mealName,
    _calories,
    _carbs,
    _protein,
    _fat,
  ];
  late DateTime _draftDateTime;
  late DateTime _maximumDateTime;
  Timer? _maximumDateTimer;

  MealCategoriesController? _categories;
  QuickAddMealLogCreateController? _create;
  QuickAddMealLogEditController? _edit;
  MealLogEntry? _activeEntry;
  var _hydrating = false;

  /// The category the reader chose, held as its durable id.
  String? _chosenMealCategoryId;

  var _isMealTypePickerOpen = false;
  var _isDateTimePickerOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final categoriesRepository = widget.mealCategoriesRepository;
    if (categoriesRepository != null) {
      _categories = MealCategoriesController(repository: categoriesRepository)
        ..addListener(_onCategoriesChanged)
        ..load();
    }
    final mealLogRepository = widget.mealLogRepository;
    if (mealLogRepository != null) {
      final initialEntry = widget.initialEntry;
      if (initialEntry == null) {
        _create = QuickAddMealLogCreateController(
          repository: mealLogRepository,
          clock: _currentLocalNow,
        )..addListener(_onMutationChanged);
      } else {
        _edit = QuickAddMealLogEditController(
          repository: mealLogRepository,
          initialEntry: initialEntry,
          clock: _currentLocalNow,
        )..addListener(_onEditChanged);
      }
    }
    final openedAt = _currentLocalNow();
    final initialEntry = widget.initialEntry;
    final initialLocal = initialEntry == null
        ? null
        : QuickAddMealLogEditController.editableLocalDateTime(initialEntry);
    assert(initialEntry == null || initialLocal != null);
    _draftDateTime = initialLocal ?? _minuteOnly(openedAt);
    _maximumDateTime = _draftDateTime;
    if (initialEntry != null) _hydrateEntry(initialEntry);
    for (final controller in _fields) {
      controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _stopMaximumDateRefresh();
    _categories
      ?..removeListener(_onCategoriesChanged)
      ..dispose();
    _create
      ?..removeListener(_onMutationChanged)
      ..dispose();
    _edit
      ?..removeListener(_onEditChanged)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _fields) {
      controller
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onCategoriesChanged() {
    if (mounted) setState(() {});
  }

  void _onMutationChanged() {
    if (mounted) setState(() {});
  }

  void _onEditChanged() {
    final state = _edit?.state;
    final latest = state?.status == QuickAddMealLogEditStatus.conflict
        ? state?.entry
        : null;
    if (latest != null &&
        (_activeEntry?.id != latest.id ||
            _activeEntry?.revision != latest.revision)) {
      _hydrateEntry(latest);
    }
    if (mounted) setState(() {});
  }

  bool get _isEditing => widget.initialEntry != null;
  bool get _draftLocked =>
      _create?.state.locksDraft ?? _edit?.state.locksDraft ?? false;
  bool get _isSubmitting =>
      _create?.state.isSubmitting ?? _edit?.state.isSubmitting ?? false;

  List<MealCategoryOption> get _categoryOptions {
    final controller = _categories;
    if (controller == null) return const [];
    final active = controller.state.activeItems;
    final currentId = _activeEntry?.mealCategoryId;
    final current = currentId == null
        ? null
        : controller.state.visible?.findById(currentId);
    return [
      if (current != null && !current.active)
        MealCategoryOption(id: current.id, label: current.displayName),
      for (final item in active)
        MealCategoryOption(id: item.id, label: item.displayName),
    ];
  }

  bool get _canOpenMealTypePicker =>
      !_draftLocked &&
      _categories != null &&
      _categories!.state.status != MealCategoriesStatus.loading;

  void _toggleMealTypePicker() {
    if (_draftLocked) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isDateTimePickerOpen = false;
      _isMealTypePickerOpen = !_isMealTypePickerOpen;
    });
  }

  void _closeMealTypePicker() {
    if (!_isMealTypePickerOpen) return;
    setState(() => _isMealTypePickerOpen = false);
  }

  void _onMealCategorySelected(String id) {
    if (_draftLocked) return;
    _draftChanged();
    setState(() {
      _chosenMealCategoryId = id;
      _isMealTypePickerOpen = false;
    });
  }

  String? get _selectedMealCategoryId =>
      _chosenMealCategoryId ?? _suggestedMealCategoryId;

  String? get _suggestedMealCategoryId {
    final controller = _categories;
    if (controller == null) return null;
    return suggestedMealCategoryId(
      consumedLocal: _draftDateTime,
      activeItems: controller.state.activeItems,
    );
  }

  String? get _selectedCategoryLabel {
    final id = _selectedMealCategoryId;
    if (id == null) return null;
    for (final option in _categoryOptions) {
      if (option.id == id) return option.label;
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isDateTimePickerOpen) {
      final now = _currentLocalNow();
      _refreshMaximumDateTime(now);
      _scheduleMaximumDateRefresh(now);
      return;
    }
    _stopMaximumDateRefresh();
  }

  void _onChanged() {
    if (_draftLocked || _hydrating) return;
    _draftChanged();
    if (mounted) setState(() {});
  }

  void _draftChanged() {
    _create?.draftChanged();
    _edit?.draftChanged();
  }

  DateTime _currentLocalNow() => widget.clock?.call() ?? DateTime.now();

  DateTime _minuteOnly(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  DateTime _resolveMealDateTime(DateTime candidate) {
    final now = _minuteOnly(_currentLocalNow());
    _maximumDateTime = now;
    return candidate.isAfter(now) ? now : candidate;
  }

  void _refreshMaximumDateTime([DateTime? current]) {
    final maximum = _minuteOnly(current ?? _currentLocalNow());
    if (maximum == _maximumDateTime) return;
    setState(() => _maximumDateTime = maximum);
  }

  void _scheduleMaximumDateRefresh([DateTime? current]) {
    _maximumDateTimer?.cancel();
    final now = current ?? _currentLocalNow();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    final delay = nextMinute.difference(now);
    if (delay <= Duration.zero) return;
    _maximumDateTimer = Timer(delay, () {
      if (!mounted) return;
      final refreshedAt = _currentLocalNow();
      _refreshMaximumDateTime(refreshedAt);
      _scheduleMaximumDateRefresh(refreshedAt);
    });
  }

  void _stopMaximumDateRefresh() {
    _maximumDateTimer?.cancel();
    _maximumDateTimer = null;
  }

  void _onDateTimeChanged(DateTime value) {
    if (_draftLocked) return;
    _draftChanged();
    setState(() => _draftDateTime = value);
  }

  void _toggleDateTimePicker() {
    if (_draftLocked) return;
    FocusScope.of(context).unfocus();
    _refreshMaximumDateTime();
    setState(() {
      _isMealTypePickerOpen = false;
      _isDateTimePickerOpen = !_isDateTimePickerOpen;
    });
    if (_isDateTimePickerOpen) {
      _scheduleMaximumDateRefresh();
    } else {
      _stopMaximumDateRefresh();
    }
  }

  void _closeDateTimePicker() {
    if (!_isDateTimePickerOpen) return;
    _stopMaximumDateRefresh();
    setState(() => _isDateTimePickerOpen = false);
  }

  QuickAddMealLogDraft? _currentDraft() {
    final categoryId = _selectedMealCategoryId;
    if (categoryId == null || _selectedCategoryLabel == null) return null;

    final caloriesText = _calories.text.trim();
    if (caloriesText.isEmpty ||
        _nutritionError(label: 'Calories', text: caloriesText) != null) {
      return null;
    }
    final calories = double.parse(caloriesText);

    num? optionalValue(TextEditingController controller, String label) {
      final text = controller.text.trim();
      if (text.isEmpty) return null;
      if (_nutritionError(label: label, text: text) != null) {
        throw const FormatException();
      }
      return double.parse(text);
    }

    try {
      return QuickAddMealLogDraft(
        mealCategoryId: categoryId,
        mealName: _mealName.text,
        consumedLocalDateTime: _draftDateTime,
        caloriesKcal: calories,
        carbohydrateGrams: optionalValue(_carbs, 'Carbs'),
        proteinGrams: optionalValue(_protein, 'Protein'),
        fatGrams: optionalValue(_fat, 'Fat'),
      );
    } on FormatException {
      return null;
    }
  }

  bool get _canSubmit {
    final create = _create;
    final edit = _edit;
    if (create == null && edit == null) return false;
    if (_isSubmitting) return false;
    if (create?.state.isOutcomeUnknown == true ||
        edit?.state.isOutcomeUnknown == true) {
      return true;
    }
    return _currentDraft() != null;
  }

  Future<void> _submit() async {
    if ((_create == null && _edit == null) || _isSubmitting) return;
    final draft = _currentDraft();
    if (draft == null) return;

    FocusScope.of(context).unfocus();
    _stopMaximumDateRefresh();
    if (_isMealTypePickerOpen || _isDateTimePickerOpen) {
      setState(() {
        _isMealTypePickerOpen = false;
        _isDateTimePickerOpen = false;
      });
    }

    final entry =
        _isEditing ? await _edit?.submit(draft) : await _create?.submit(draft);
    if (!mounted || entry == null) return;
    Navigator.of(context).pop(entry);
  }

  void _hydrateEntry(MealLogEntry entry) {
    final snapshot = entry.manualNutritionSnapshot;
    final local = QuickAddMealLogEditController.editableLocalDateTime(entry);
    if (snapshot == null || local == null) return;

    _hydrating = true;
    _activeEntry = entry;
    _chosenMealCategoryId = entry.mealCategoryId;
    _draftDateTime = local;
    _mealName.text = entry.mealName ?? '';
    _calories.text = _formatEditorAmount(
      snapshot.amountFor(NutrientId.energy),
    );
    _carbs.text = _formatEditorAmount(
      snapshot.amountFor(NutrientId.carbohydrate),
    );
    _protein.text = _formatEditorAmount(
      snapshot.amountFor(NutrientId.protein),
    );
    _fat.text = _formatEditorAmount(snapshot.amountFor(NutrientId.fat));
    _hydrating = false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final selectedDateLabel = localizations.formatShortMonthDay(_draftDateTime);
    final selectedTimeLabel =
        '${_draftDateTime.hour.toString().padLeft(2, '0')}:'
        '${_draftDateTime.minute.toString().padLeft(2, '0')}';
    final dateTimeLabel = '$selectedDateLabel, $selectedTimeLabel';
    final mutationMessage = _create?.state.message ?? _edit?.state.message;

    return PopScope(
      canPop: !_draftLocked && !_isMealTypePickerOpen && !_isDateTimePickerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _draftLocked) return;
        if (_isMealTypePickerOpen) {
          _closeMealTypePicker();
        } else {
          _closeDateTimePicker();
        }
      },
      child: MealCategoryPickerPopup(
        anchorKey: _mealCategoryAnchorKey,
        isOpen: _isMealTypePickerOpen,
        onDismiss: _closeMealTypePicker,
        options: _categoryOptions,
        selectedId: _selectedMealCategoryId,
        onSelected: _onMealCategorySelected,
        loadError: _categories?.state.loadError,
        isLoading: _categories?.state.status == MealCategoriesStatus.loading,
        onRetry: _categories?.retryLoad,
        passThroughAnchorKey: _dateTimeAnchorKey,
        child: TioDateTimePickerPopup(
          anchorKey: _dateTimeAnchorKey,
          isOpen: _isDateTimePickerOpen,
          onDismiss: _closeDateTimePicker,
          value: _draftDateTime,
          maximumDate: _maximumDateTime,
          resolveDateTime: _resolveMealDateTime,
          onChanged: _onDateTimeChanged,
          onPickerInteractionStart: _refreshMaximumDateTime,
          passThroughAnchorKey:
              _canOpenMealTypePicker ? _mealCategoryAnchorKey : null,
          child: TioEditorSheet(
            key: const ValueKey('quick-add-editor'),
            title: _isEditing ? 'Quick Edit' : 'Quick Add',
            canDismiss: !_draftLocked,
            flushActions: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TioInput.multiline(
                  key: const ValueKey('quick-add-meal-name'),
                  controller: _mealName,
                  hint: 'Meal name (optional)',
                  minLines: 1,
                  maxLines: 2,
                  enabled: !_draftLocked,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {},
                ),
                const SizedBox(height: TioSpacing.lg),
                _NutritionRow(
                  fieldKey: const ValueKey('quick-add-calories'),
                  controller: _calories,
                  label: 'Calories',
                  unit: 'kcal',
                  enabled: !_draftLocked,
                ),
                const SizedBox(height: TioSpacing.md),
                _NutritionRow(
                  fieldKey: const ValueKey('quick-add-carbs'),
                  controller: _carbs,
                  label: 'Carbs',
                  unit: 'g',
                  enabled: !_draftLocked,
                ),
                const SizedBox(height: TioSpacing.md),
                _NutritionRow(
                  fieldKey: const ValueKey('quick-add-protein'),
                  controller: _protein,
                  label: 'Protein',
                  unit: 'g',
                  enabled: !_draftLocked,
                ),
                const SizedBox(height: TioSpacing.md),
                _NutritionRow(
                  fieldKey: const ValueKey('quick-add-fat'),
                  controller: _fat,
                  label: 'Fat',
                  unit: 'g',
                  enabled: !_draftLocked,
                ),
                const SizedBox(height: TioSpacing.md),
              ],
            ),
            actions: MealLogActionFooter(
              mealCategoryLabel: _selectedCategoryLabel ?? _categoryPlaceholder,
              mealCategorySemanticLabel: _categorySemanticLabel,
              mealCategoryAnchorKey: _mealCategoryAnchorKey,
              onMealCategoryTap:
                  _canOpenMealTypePicker ? _toggleMealTypePicker : null,
              dateTimeLabel: dateTimeLabel,
              dateTimeSemanticLabel: 'Date and time. $dateTimeLabel. '
                  'Picker ${_isDateTimePickerOpen ? 'expanded' : 'collapsed'}.',
              onDateTimeTap: _draftLocked ? null : _toggleDateTimePicker,
              dateTimeAnchorKey: _dateTimeAnchorKey,
              primaryLabel: _isEditing ? 'Save Changes' : 'Log Meal',
              primarySemanticLabel: _primarySemanticLabel,
              primaryLoading: _isSubmitting,
              primaryLoadingLabel:
                  _isEditing ? 'Saving changes' : 'Logging meal',
              note: mutationMessage,
              onPrimaryPressed: _canSubmit ? _submit : null,
            ),
          ),
        ),
      ),
    );
  }
}

extension _QuickAddCategories on _QuickAddEditorSheetState {
  String get _categoryPlaceholder => 'Meal type';

  String get _categorySemanticLabel {
    final controller = _categories;
    if (controller == null) return 'Meal type. Not available yet.';
    switch (controller.state.status) {
      case MealCategoriesStatus.loading:
        return 'Meal type. Loading.';
      case MealCategoriesStatus.loadFailed:
        return 'Meal type. Could not load meal categories.';
      case MealCategoriesStatus.ready:
        final selected = _selectedCategoryLabel;
        return selected == null
            ? 'Meal type. None selected.'
            : 'Meal type. $selected.';
    }
  }

  String get _primarySemanticLabel {
    if (_isEditing) {
      final controller = _edit;
      if (controller == null) {
        return 'Save Changes. Not available yet.';
      }
      if (controller.state.isSubmitting) return 'Save Changes.';
      if (controller.state.isOutcomeUnknown) {
        return 'Retry Save Changes. Save status is uncertain.';
      }
      if (_canSubmit) return 'Save Changes.';
      return 'Save Changes. Enter calories and choose a meal type.';
    }
    final controller = _create;
    if (controller == null) return 'Log Meal. Not available yet.';
    if (controller.state.isSubmitting) return 'Log Meal.';
    if (controller.state.isOutcomeUnknown) {
      return 'Retry Log Meal. Save status is uncertain.';
    }
    if (_canSubmit) return 'Log Meal.';
    return 'Log Meal. Enter calories and choose a meal type.';
  }
}

String _formatEditorAmount(num? value) {
  if (value == null) return '';
  final numeric = value.toDouble();
  if (numeric == numeric.roundToDouble()) return numeric.toInt().toString();
  return numeric.toString();
}

String? _nutritionError({required String label, required String text}) {
  final normalized = text.trim();
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return 'Enter a number.';
  if (value < 0) return '$label cannot be negative.';
  return null;
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.unit,
    required this.enabled,
  });

  static const _valueWidth = TioSize.dp100;

  final ValueKey<String> fieldKey;
  final TextEditingController controller;
  final String label;
  final String unit;
  final bool enabled;

  String? get _error => _nutritionError(label: label, text: controller.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final error = _error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label ($unit)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: TioFontSize.size15,
                  fontWeight: TioFontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.md),
            SizedBox(
              width: _valueWidth,
              child: Semantics(
                validationResult: error == null
                    ? SemanticsValidationResult.none
                    : SemanticsValidationResult.invalid,
                child: TioInput.numericEditor(
                  key: fieldKey,
                  controller: controller,
                  hint: '0',
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.md,
                    vertical: TioSpacing.sm,
                  ),
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: TioSpacing.xs),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              key: ValueKey('${fieldKey.value}-error'),
              style: TextStyle(
                color: colors.danger,
                fontSize: TioFontSize.size13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
