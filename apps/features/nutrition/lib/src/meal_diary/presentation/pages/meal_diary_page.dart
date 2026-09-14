import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/models/daily_nutrition_summary.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/repositories/meal_log_range_read_repository.dart';
import '../../../domain/repositories/meal_log_repository.dart';
import '../../../meal_logging/quick_add_meal_log_edit_controller.dart';
import '../../../meal_logging/presentation/widgets/add_food_sheet.dart';
import '../../../meal_logging/presentation/widgets/quick_add_editor_sheet.dart';
import '../../meal_diary_history_providers.dart';
import '../../meal_diary_nutrition_summary_providers.dart';
import '../controllers/meal_diary_date_controller.dart';
import '../widgets/meal_diary_daily_nutrition_summary.dart';
import '../widgets/meal_diary_history_view.dart';
import '../widgets/meal_diary_log_action.dart';

/// Vertical room the floating `+` occupies at the bottom of the diary body:
/// the button itself plus the padding above and below it.
///
/// This is only the button's own footprint. The action also sits inside a
/// `SafeArea`, so on a viewport with a bottom inset — the shell's navigation
/// hidden, a gesture bar present — it rides that much higher and the body has
/// to reserve the inset too. See [_reservedClearance].
const double _actionClearance = TioSize.dp56 + TioSpacing.xl * 2;

/// The calendar reserves a 42dp transparent band below its surface so the
/// expansion handle keeps a full 48dp hit target. A resolved Daily Nutrition
/// summary is read-only content, so it may visually occupy most of that band.
/// The summary itself ignores pointer input while overlapped, which lets the
/// calendar handle keep its complete hit target even though the pixels are
/// closer together. Loading/error surfaces keep the ordinary clearance because
/// the error surface contains an interactive Retry action.
const double _dailySummaryCalendarOverlap = TioSize.dp32;

/// The Meal Diary surface, and the first production consumer of the reusable
/// core date calendar.
///
/// Nutrition owns selected-date policy, MealLog truth, DailyNutritionBudget
/// resolution and the meaning of calendar progress. Core receives only a
/// normalized generic [TioDateDecoration].
///
/// Quick Add owns its own current-local consumed draft. A confirmed mutation
/// refreshes the affected history and derived daily-summary/calendar read
/// models without moving a historical selection.
class MealDiaryPage extends ConsumerStatefulWidget {
  const MealDiaryPage({
    super.key,
    this.resolvedFirstDayOfWeek,
    this.quickAddClock,
    this.mealCategoriesRepository,
  });

  /// The app-global week start, already resolved, supplied by app composition.
  final int? resolvedFirstDayOfWeek;

  /// Canonical Meal Categories owner supplied by app composition.
  final MealCategoriesRepository? mealCategoriesRepository;

  /// Testable local clock seam for a brand-new Quick Add draft.
  final DateTime Function()? quickAddClock;

  @override
  ConsumerState<MealDiaryPage> createState() => _MealDiaryPageState();
}

class _MealDiaryPageState extends ConsumerState<MealDiaryPage>
    with WidgetsBindingObserver {
  /// One shot, aimed at the next local midnight, owned by this screen.
  Timer? _midnightTimer;

  /// Whether the calendar is currently showing its month grid.
  var _isCalendarExpanded = false;

  /// Guards the async row-read gap before the Quick Edit sheet barrier appears.
  var _isOpeningQuickEdit = false;

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
    final delay = ref
        .read(mealDiaryDateControllerProvider)
        .durationUntilNextLocalMidnight;
    if (delay <= Duration.zero) return;
    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(mealDiaryDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
    });
  }

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

        _invalidateDiaryDate(
          repository: mealLogRepository,
          categoriesRepository: mealCategoriesRepository,
          localDate: created.consumedLocalDate,
        );
    }
  }

  Future<void> _openQuickEdit(String id) async {
    if (_isOpeningQuickEdit) return;
    _isOpeningQuickEdit = true;

    final mealLogRepository = ref.read(mealDiaryMealLogRepositoryProvider);
    final mealCategoriesRepository = widget.mealCategoriesRepository;
    if (mealLogRepository == null || mealCategoriesRepository == null) {
      _isOpeningQuickEdit = false;
      return;
    }

    MealLogEntry? entry;
    try {
      entry = await mealLogRepository.readById(id);
    } on Object {
      _isOpeningQuickEdit = false;
      if (mounted) _showMealEditMessage("Couldn't open this meal. Try again.");
      return;
    }
    if (!mounted) {
      _isOpeningQuickEdit = false;
      return;
    }
    if (entry == null) {
      _isOpeningQuickEdit = false;
      _showMealEditMessage('This meal is no longer available.');
      return;
    }
    if (entry.mode != MealLogMode.manual ||
        entry.manualNutritionSnapshot == null ||
        QuickAddMealLogEditController.editableLocalDateTime(entry) == null) {
      _isOpeningQuickEdit = false;
      _showMealEditMessage('Editing is not available for this meal yet.');
      return;
    }

    final originalDate = entry.consumedLocalDate;
    final sheetFuture = showQuickAddEditorSheet(
      context,
      clock: widget.quickAddClock,
      mealCategoriesRepository: mealCategoriesRepository,
      mealLogRepository: mealLogRepository,
      initialEntry: entry,
    );
    _isOpeningQuickEdit = false;
    final updated = await sheetFuture;
    if (!mounted) return;

    // Refresh the original date even when the sheet returns no result: an
    // ambiguous durable write can still have landed before the editor closed.
    _invalidateDiaryDate(
      repository: mealLogRepository,
      categoriesRepository: mealCategoriesRepository,
      localDate: originalDate,
    );
    if (updated == null) return;

    if (updated.consumedLocalDate != originalDate) {
      _invalidateDiaryDate(
        repository: mealLogRepository,
        categoriesRepository: mealCategoriesRepository,
        localDate: updated.consumedLocalDate,
      );
    }
  }

  void _invalidateDiaryDate({
    required MealLogRepository repository,
    required MealCategoriesRepository categoriesRepository,
    required MealLogLocalDate localDate,
  }) {
    ref.invalidate(
      mealDiaryHistoryProvider(
        MealDiaryHistoryRequest(
          mealLogRepository: repository,
          mealCategoriesRepository: categoriesRepository,
          localDate: localDate,
        ),
      ),
    );

    final targetsRepository =
        ref.read(mealDiaryNutritionTargetsRepositoryProvider);
    if (targetsRepository == null) return;

    ref.invalidate(
      mealDiaryDailyNutritionSummaryProvider(
        MealDiaryDailySummaryRequest(
          mealLogRepository: repository,
          nutritionTargetsRepository: targetsRepository,
          localDate: localDate,
        ),
      ),
    );

    if (repository is! MealLogRangeReadRepository) return;

    final dates = ref.read(mealDiaryDateControllerProvider);
    final visibleRange = _clampedVisibleRange(dates);
    if (visibleRange == null ||
        !_localDateFallsWithin(
          localDate,
          visibleRange.$1,
          visibleRange.$2,
        )) {
      return;
    }

    ref.invalidate(
      mealDiaryNutritionSummaryRangeProvider(
        MealDiarySummaryRangeRequest.fromVisibleDates(
          mealLogRepository: repository,
          nutritionTargetsRepository: targetsRepository,
          firstDate: visibleRange.$1,
          lastDate: visibleRange.$2,
        ),
      ),
    );
  }

  void _showMealEditMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(mealDiaryDateControllerProvider);
    final mealLogRepository = ref.watch(mealDiaryMealLogRepositoryProvider);
    final mealCategoriesRepository = widget.mealCategoriesRepository;
    final targetsRepository =
        ref.watch(mealDiaryNutritionTargetsRepositoryProvider);

    final historyRequest =
        mealLogRepository == null || mealCategoriesRepository == null
            ? null
            : MealDiaryHistoryRequest.forSelectedDate(
                mealLogRepository: mealLogRepository,
                mealCategoriesRepository: mealCategoriesRepository,
                selectedDate: dates.selectedDate,
              );

    final dailySummaryRequest =
        mealLogRepository == null || targetsRepository == null
            ? null
            : MealDiaryDailySummaryRequest.forSelectedDate(
                mealLogRepository: mealLogRepository,
                nutritionTargetsRepository: targetsRepository,
                selectedDate: dates.selectedDate,
              );
    final dailySummary = dailySummaryRequest == null
        ? null
        : ref.watch(
            mealDiaryDailyNutritionSummaryProvider(dailySummaryRequest),
          );

    final visibleRange = _clampedVisibleRange(dates);
    final rangeRequest = mealLogRepository == null ||
            mealLogRepository is! MealLogRangeReadRepository ||
            targetsRepository == null ||
            visibleRange == null
        ? null
        : MealDiarySummaryRangeRequest.fromVisibleDates(
            mealLogRepository: mealLogRepository,
            nutritionTargetsRepository: targetsRepository,
            firstDate: visibleRange.$1,
            lastDate: visibleRange.$2,
          );
    final rangeSummaries = rangeRequest == null
        ? null
        : ref.watch(
            mealDiaryNutritionSummaryRangeProvider(rangeRequest),
          );
    final hasRangeError = rangeSummaries?.hasError == true;
    final canOverlapDailySummary = dailySummary?.hasValue == true &&
        dailySummary?.hasError != true &&
        !hasRangeError;

    return Stack(
      fit: StackFit.expand,
      children: [
        _diaryBody(
          dates,
          historyRequest,
          _dailySummarySurface(
            dailySummary,
            forceError: hasRangeError,
          ),
          _calendarDecorationBuilder(
            hasRangeError ? null : rangeSummaries?.valueOrNull,
          ),
          overlapDailySummary: canOverlapDailySummary,
        ),
        // The expanded month grid can reach the bottom of a short viewport,
        // so the floating action temporarily steps out of its way.
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

  Widget _dailySummarySurface(
    AsyncValue<DailyNutritionSummary>? summary, {
    required bool forceError,
  }) {
    if (summary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        TioSpacing.lg,
        TioSpacing.none,
        TioSpacing.lg,
        TioSpacing.lg,
      ),
      child: forceError
          ? const MealDiaryDailyNutritionSummaryStatus.error()
          : summary.when(
              loading: () =>
                  const MealDiaryDailyNutritionSummaryStatus.loading(),
              error: (_, __) =>
                  const MealDiaryDailyNutritionSummaryStatus.error(),
              data: (data) => IgnorePointer(
                child: MealDiaryDailyNutritionSummary(summary: data),
              ),
            ),
    );
  }

  TioDateDecorationBuilder? _calendarDecorationBuilder(
    Map<MealLogLocalDate, DailyNutritionSummary>? summaries,
  ) {
    if (summaries == null) return null;

    return (date) {
      final localDate = MealLogLocalDate(
        year: date.year,
        month: date.month,
        day: date.day,
      );
      final summary = summaries[localDate];
      final progress = summary?.calorieProgress;
      final eaten = summary?.eatenCaloriesKcal;
      final target = summary?.targetCaloriesKcal;
      if (progress == null ||
          eaten == null ||
          target == null ||
          target <= 0) {
        return null;
      }

      final percent = ((eaten / target) * 100).round();
      return TioDateDecoration(
        progress: progress,
        semanticsLabel:
            '${_formatAmount(eaten)} of ${_formatAmount(target)} calorie target, $percent percent',
      );
    };
  }

  /// The clearance for a given viewport: the button's footprint plus whatever
  /// bottom inset pushed it up.
  double _reservedClearance(BuildContext context) =>
      _actionClearance + MediaQuery.paddingOf(context).bottom;

  Widget _diaryBody(
    MealDiaryDateController dates,
    MealDiaryHistoryRequest? historyRequest,
    Widget dailySummarySurface,
    TioDateDecorationBuilder? decorationBuilder, {
    required bool overlapDailySummary,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overlap = overlapDailySummary
            ? _dailySummaryCalendarOverlap
            : TioSpacing.none;
        final reservedClearance = _reservedClearance(context);
        final scrollClearance = math.max(0.0, reservedClearance - overlap);

        final belowCalendar = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dailySummarySurface,
            MealDiaryHistoryView(
              date: dates.selectedDate,
              request: historyRequest,
              onEdit: historyRequest == null ? null : _openQuickEdit,
            ),
          ],
        );

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: scrollClearance),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0.0,
                constraints.maxHeight - scrollClearance,
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
                  decorationBuilder: decorationBuilder,
                  onDisplayModeChanged: (mode) {
                    if (_isCalendarExpanded == mode.isMonth) return;
                    setState(() => _isCalendarExpanded = mode.isMonth);
                  },
                  resolvedFirstDayOfWeek: widget.resolvedFirstDayOfWeek,
                ),
                if (overlap > 0)
                  Transform.translate(
                    key: const ValueKey('meal-diary-summary-calendar-overlap'),
                    offset: Offset(0, -overlap),
                    child: belowCalendar,
                  )
                else
                  belowCalendar,
              ],
            ),
          ),
        );
      },
    );
  }

  (DateTime, DateTime)? _clampedVisibleRange(MealDiaryDateController dates) {
    final first = dates.visibleFirstDate;
    final last = dates.visibleLastDate;
    if (first == null || last == null) return null;

    final start = first.isBefore(dates.minDate) ? dates.minDate : first;
    final end = last.isAfter(dates.maxDate) ? dates.maxDate : last;
    if (start.isAfter(end)) return null;
    return (start, end);
  }

  bool _localDateFallsWithin(
    MealLogLocalDate localDate,
    DateTime start,
    DateTime end,
  ) {
    final date = DateTime(localDate.year, localDate.month, localDate.day);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  String _formatAmount(num value) {
    final number = value.toDouble();
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
  }
}
