import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/detailed_meal_log_create_repository.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/usecases/meal_category_time_suggestion.dart';
import '../../../meal_diary/presentation/controllers/meal_categories_controller.dart';
import '../widgets/meal_category_picker_popup.dart';
import 'meal_editor_create_page.dart';

/// Full-screen review/persistence owner for a parsed text-meal draft.
///
/// This wrapper owns only the create context that sits around the existing
/// [MealEditorCreatePage]: selected meal category and consumed local date/time.
/// The parsed draft remains provider-neutral, and durable history is still
/// created only by the editor's explicit Log Meal action.
class MealEditorTextFlowPage extends StatefulWidget {
  const MealEditorTextFlowPage({
    required this.initialDraft,
    required this.selectedDiaryDate,
    required this.mealCategoriesRepository,
    required this.detailedCreateRepository,
    super.key,
    this.clock,
  });

  final MealLoggingDraft initialDraft;
  final DateTime selectedDiaryDate;
  final MealCategoriesRepository mealCategoriesRepository;
  final DetailedMealLogCreateRepository detailedCreateRepository;
  final DateTime Function()? clock;

  @override
  State<MealEditorTextFlowPage> createState() =>
      _MealEditorTextFlowPageState();
}

class _MealEditorTextFlowPageState extends State<MealEditorTextFlowPage> {
  final _mealCategoryAnchorKey = GlobalKey();
  final _dateTimeAnchorKey = GlobalKey();

  late final MealCategoriesController _categories;
  late DateTime _consumedLocalDateTime;
  late DateTime _maximumDateTime;

  String? _chosenMealCategoryId;
  var _isMealTypePickerOpen = false;
  var _isDateTimePickerOpen = false;

  @override
  void initState() {
    super.initState();
    _categories = MealCategoriesController(
      repository: widget.mealCategoriesRepository,
    )
      ..addListener(_onCategoriesChanged)
      ..load();

    final now = _minuteOnly(_currentLocalNow());
    final selected = widget.selectedDiaryDate;
    _consumedLocalDateTime = DateTime(
      selected.year,
      selected.month,
      selected.day,
      now.hour,
      now.minute,
    );
    _maximumDateTime = now;
  }

  @override
  void dispose() {
    _categories
      ..removeListener(_onCategoriesChanged)
      ..dispose();
    super.dispose();
  }

  DateTime _currentLocalNow() => widget.clock?.call() ?? DateTime.now();

  DateTime _minuteOnly(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );

  void _onCategoriesChanged() {
    if (mounted) setState(() {});
  }

  List<MealCategoryOption> get _categoryOptions => [
        for (final item in _categories.state.activeItems)
          MealCategoryOption(id: item.id, label: item.displayName),
      ];

  String? get _suggestedMealCategoryId => suggestedMealCategoryId(
        consumedLocal: _consumedLocalDateTime,
        activeItems: _categories.state.activeItems,
      );

  String? get _selectedMealCategoryId =>
      _chosenMealCategoryId ?? _suggestedMealCategoryId;

  String? get _selectedCategoryLabel {
    final selectedId = _selectedMealCategoryId;
    if (selectedId == null) return null;
    for (final option in _categoryOptions) {
      if (option.id == selectedId) return option.label;
    }
    return null;
  }

  bool get _canOpenMealTypePicker =>
      _categories.state.status != MealCategoriesStatus.loading;

  void _toggleMealTypePicker() {
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
    setState(() {
      _chosenMealCategoryId = id;
      _isMealTypePickerOpen = false;
    });
  }

  DateTime _resolveMealDateTime(DateTime candidate) {
    final now = _minuteOnly(_currentLocalNow());
    _maximumDateTime = now;
    return candidate.isAfter(now) ? now : candidate;
  }

  void _refreshMaximumDateTime() {
    final next = _minuteOnly(_currentLocalNow());
    if (next == _maximumDateTime) return;
    setState(() => _maximumDateTime = next);
  }

  void _toggleDateTimePicker() {
    FocusScope.of(context).unfocus();
    _refreshMaximumDateTime();
    setState(() {
      _isMealTypePickerOpen = false;
      _isDateTimePickerOpen = !_isDateTimePickerOpen;
    });
  }

  void _closeDateTimePicker() {
    if (!_isDateTimePickerOpen) return;
    setState(() => _isDateTimePickerOpen = false);
  }

  void _onDateTimeChanged(DateTime value) {
    setState(() => _consumedLocalDateTime = value);
  }

  String get _categorySemanticLabel {
    switch (_categories.state.status) {
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

  String _dateTimeLabel(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date =
        localizations.formatShortMonthDay(_consumedLocalDateTime);
    final time =
        '${_consumedLocalDateTime.hour.toString().padLeft(2, '0')}:'
        '${_consumedLocalDateTime.minute.toString().padLeft(2, '0')}';
    return '$date, $time';
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeLabel = _dateTimeLabel(context);

    return PopScope(
      canPop: !_isMealTypePickerOpen && !_isDateTimePickerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isMealTypePickerOpen) {
          _closeMealTypePicker();
        } else if (_isDateTimePickerOpen) {
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
        loadError: _categories.state.loadError,
        isLoading: _categories.state.status == MealCategoriesStatus.loading,
        onRetry: _categories.retryLoad,
        passThroughAnchorKey: _dateTimeAnchorKey,
        child: TioDateTimePickerPopup(
          anchorKey: _dateTimeAnchorKey,
          isOpen: _isDateTimePickerOpen,
          onDismiss: _closeDateTimePicker,
          value: _consumedLocalDateTime,
          maximumDate: _maximumDateTime,
          resolveDateTime: _resolveMealDateTime,
          onChanged: _onDateTimeChanged,
          onPickerInteractionStart: _refreshMaximumDateTime,
          passThroughAnchorKey:
              _canOpenMealTypePicker ? _mealCategoryAnchorKey : null,
          child: MealEditorCreatePage(
            initialDraft: widget.initialDraft,
            mealCategoryLabel: _selectedCategoryLabel ?? 'Meal type',
            dateTimeLabel: dateTimeLabel,
            mealCategoryId: _selectedMealCategoryId,
            consumedLocalDateTime: _consumedLocalDateTime,
            detailedCreateRepository: widget.detailedCreateRepository,
            mealCategoryAnchorKey: _mealCategoryAnchorKey,
            dateTimeAnchorKey: _dateTimeAnchorKey,
            onMealCategoryTap:
                _canOpenMealTypePicker ? _toggleMealTypePicker : null,
            onDateTimeTap: _toggleDateTimePicker,
            onBack: () => Navigator.of(context).maybePop(),
            onCreated: (entry) => Navigator.of(context).pop(entry),
          ),
        ),
      ),
    );
  }
}
