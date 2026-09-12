import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../meal_logging/presentation/widgets/add_food_sheet.dart';
import '../../../meal_logging/presentation/widgets/quick_add_editor_sheet.dart';
import '../../meal_diary_history_providers.dart';
import '../controllers/meal_diary_date_controller.dart';
import '../widgets/meal_diary_history_view.dart';
import '../widgets/meal_diary_log_action.dart';

const double _actionClearance = TioSize.dp56 + TioSpacing.xl * 2;

/// The Meal Diary surface and owner of the selected actual-history day.
///
/// Quick Add deliberately owns its own current-local consumed draft; creating a
/// meal must never move the historical Diary day the reader was viewing. A
/// confirmed create only invalidates the matching canonical history request.
class MealDiaryPage extends ConsumerStatefulWidget {
  const MealDiaryPage({
    super.key,
    this.resolvedFirstDayOfWeek,
    this.quickAddClock,
    this.mealCategoriesRepository,
  });

  final int? resolvedFirstDayOfWeek;
  final MealCategoriesRepository? mealCategoriesRepository;
  final DateTime Function()? quickAddClock;

  @override
  ConsumerState<MealDiaryPage> createState() => _MealDiaryPageState();
}

class _MealDiaryPageState extends ConsumerState<MealDiaryPage>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;
  var _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(mealDiaryDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
      return;
    }
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final delay =
        ref.read(mealDiaryDateControllerProvider).durationUntilNextLocalMidnight;
    if (delay <= Duration.zero) return;
    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(mealDiaryDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
    });
  }

  /// Meal Diary → Add Food → Quick Add.
  ///
  /// The Diary's selected date deliberately does not cross this boundary. A
  /// new Quick Add owns a fresh current-local DateTime snapshot. The canonical
  /// MealLog repository is passed in from the existing feature seam rather than
  /// introducing a second persistence owner inside the editor.
  Future<void> _openAddFood() async {
    final choice = await showMealDiaryAddFoodSheet(context);
    if (choice == null || !mounted) return;

    switch (choice) {
      case MealDiaryAddFoodChoice.quickAdd:
        final mealLogRepository = ref.read(mealDiaryMealLogRepositoryProvider);
        final mealCategoriesRepository = widget.mealCategoriesRepository;
        final created = await showQuickAddEditorSheet(
          context,
          clock: widget.quickAddClock,
          mealCategoriesRepository: mealCategoriesRepository,
          mealLogRepository: mealLogRepository,
        );
        if (!mounted ||
            created == null ||
            mealLogRepository == null ||
            mealCategoriesRepository == null) {
          return;
        }

        // Refresh exactly the local-date read model the confirmed entry belongs
        // to. If the reader is looking at that day it updates immediately; if
        // they are looking at another historical day, its selection is left
        // untouched and no unrelated request is invalidated.
        ref.invalidate(
          mealDiaryHistoryProvider(
            MealDiaryHistoryRequest(
              mealLogRepository: mealLogRepository,
              mealCategoriesRepository: mealCategoriesRepository,
              localDate: created.consumedLocalDate,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(mealDiaryDateControllerProvider);
    final mealLogRepository = ref.watch(mealDiaryMealLogRepositoryProvider);
    final mealCategoriesRepository = widget.mealCategoriesRepository;
    final historyRequest =
        mealLogRepository == null || mealCategoriesRepository == null
            ? null
            : MealDiaryHistoryRequest.forSelectedDate(
                mealLogRepository: mealLogRepository,
                mealCategoriesRepository: mealCategoriesRepository,
                selectedDate: dates.selectedDate,
              );

    return Stack(
      fit: StackFit.expand,
      children: [
        _diaryBody(dates, historyRequest),
        if (!_isCalendarExpanded)
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsets.all(TioSpacing.xl),
                  child: MealDiaryLogAction(
                    key: const ValueKey('meal-diary-add-food-action'),
                    onPressed: _openAddFood,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _reservedClearance(BuildContext context) =>
      _actionClearance + MediaQuery.paddingOf(context).bottom;

  Widget _diaryBody(
    MealDiaryDateController dates,
    MealDiaryHistoryRequest? historyRequest,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: _reservedClearance(context)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0,
                constraints.maxHeight - _reservedClearance(context),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TioDateCalendar(
                  controller: dates.calendarController,
                  selectedDate: dates.selectedDate,
                  localToday: dates.localToday,
                  minDate: dates.minDate,
                  maxDate: dates.maxDate,
                  onDateSelected: dates.select,
                  onVisibleDateRangeChanged: dates.updateVisibleDateRange,
                  onDisplayModeChanged: (mode) {
                    if (_isCalendarExpanded == mode.isMonth) return;
                    setState(() => _isCalendarExpanded = mode.isMonth);
                  },
                  resolvedFirstDayOfWeek: widget.resolvedFirstDayOfWeek,
                ),
                const SizedBox(height: TioSpacing.xl),
                MealDiaryHistoryView(
                  date: dates.selectedDate,
                  request: historyRequest,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
