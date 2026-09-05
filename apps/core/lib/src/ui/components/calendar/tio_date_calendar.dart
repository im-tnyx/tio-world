import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import 'tio_date_calendar_display_mode.dart';
import 'tio_date_decoration.dart';

/// Reports the inclusive primary date range owned by the visible page.
///
/// A compact page reports its seven-day week. An expanded page reports its
/// calendar month, excluding the neighbouring dates drawn only to fill rows.
typedef TioDateCalendarVisibleRangeChanged = void Function(
  DateTime firstVisibleDate,
  DateTime lastVisibleDate,
);

/// Drives a [TioDateCalendar] from outside the widget tree.
///
/// The only capability is [jumpToDate], which brings a date into view in both
/// renderings at once — it pages the compact week strip and moves the month
/// grid to that date's month. It deliberately cannot change the selection: the
/// selected date is owned by the caller's own state, so there is exactly one
/// selected-date truth.
class TioDateCalendarController extends ChangeNotifier {
  DateTime? _pendingJump;

  /// The date a [TioDateCalendar] has been asked to reveal but has not yet
  /// consumed. Exposed for the widget; callers do not need to read it.
  DateTime? get pendingJump => _pendingJump;

  /// Brings [date] into view in whichever rendering is showing, and leaves the
  /// other rendering positioned on the same date.
  void jumpToDate(DateTime date) {
    _pendingJump = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  /// Clears a jump the widget has already applied.
  void consumePendingJump() {
    _pendingJump = null;
  }
}

/// The reusable inline date calendar.
///
/// Two renderings of one caller-controlled date, sharing one weekday header so
/// they read as the same component rather than two widgets stacked:
///
/// ```text
/// MON TUE WED THU FRI SAT SUN     ← shared header
///  17  18  19  20  21  22  23     ← compact: one week per page
/// ──────────────╲__╱──────────    ← notch + handle
/// ```
///
/// Compact pages a week at a time rather than free-scrolling a flat list. A
/// free scroll leaves the columns misaligned with the header and lets the
/// selected date drift anywhere on screen; week paging keeps every date under
/// its own weekday for the whole life of the gesture.
///
/// ## What this component does not know
///
/// Core renders presentation values and nothing else. Calories, meal adherence,
/// workout completion, plan status and schedule counts are computed by the
/// feature that owns them and arrive here as a [TioDateDecoration]. That is
/// what lets Meal Diary use it today and Workout or Meal Plan use it later
/// without Core learning a single domain model.
///
/// Equally, a Today action, a `Day x/y` control and a planning-calendar
/// shortcut are the parent screen's top bar, not this component's business.
///
/// ## Selection is controlled
///
/// [selectedDate] is never mutated here. A tap reports [onDateSelected] and the
/// caller decides. Likewise [localToday] is supplied rather than read from
/// `DateTime.now()`, so the app keeps one local-date policy instead of the
/// calendar inventing its own.
///
/// ## Range is caller-controlled
///
/// Dates outside `minDate..maxDate` stay visible for week continuity but are
/// dimmed and inert, so a week never collapses into gaps. Core never forbids
/// the future on its own: Meal Diary passes `maxDate = localToday`, while a
/// future Workout or Meal Plan surface can pass its own horizon.
///
/// ## Identity
///
/// This is the inline date calendar and only that. The future Planning Calendar
/// and Progress Calendar are separate surfaces with materially different
/// interaction models; they must not become modes of this widget.
class TioDateCalendar extends StatefulWidget {
  const TioDateCalendar({
    required this.selectedDate,
    required this.localToday,
    required this.minDate,
    required this.maxDate,
    required this.onDateSelected,
    super.key,
    this.controller,
    this.resolvedFirstDayOfWeek,
    this.displayMode = TioDateCalendarDisplayMode.compact,
    this.allowExpansion = true,
    this.onDisplayModeChanged,
    this.onVisibleDateRangeChanged,
    this.decorationBuilder,
  });

  /// The currently selected date. Owned by the caller; never changed here.
  final DateTime selectedDate;

  /// Which date counts as today. Supplied rather than derived so one app-level
  /// local-date policy stays authoritative.
  final DateTime localToday;

  /// First selectable date, inclusive.
  final DateTime minDate;

  /// Last selectable date, inclusive.
  final DateTime maxDate;

  /// Reports a tap on an in-range date. The caller updates its own state.
  final ValueChanged<DateTime> onDateSelected;

  /// Optional external control for [TioDateCalendarController.jumpToDate].
  final TioDateCalendarController? controller;

  /// The resolved week start as a `DateTime.monday`..`DateTime.sunday` value.
  ///
  /// This is the already-resolved value, not a user preference: the app owns
  /// one global Calendar Preferences resolver and every calendar surface
  /// consumes its result. Null falls back to the locale's own week start via
  /// [MaterialLocalizations.firstDayOfWeekIndex].
  final int? resolvedFirstDayOfWeek;

  /// Which rendering to show. Changing it from the caller animates the switch;
  /// the handle can also change it, which reports [onDisplayModeChanged].
  final TioDateCalendarDisplayMode displayMode;

  /// Whether the notch handle is shown and the month grid is reachable.
  final bool allowExpansion;

  /// Reports a rendering change that started here, such as a handle tap.
  final ValueChanged<TioDateCalendarDisplayMode>? onDisplayModeChanged;

  /// Reports the inclusive week or month owned by the current pager page.
  final TioDateCalendarVisibleRangeChanged? onVisibleDateRangeChanged;

  /// Supplies what to draw on a given date, or null for an undecorated date.
  final TioDateDecorationBuilder? decorationBuilder;

  @override
  State<TioDateCalendar> createState() => _TioDateCalendarState();
}

// Composition geometry. Local layout sums built from governed primitives, not a
// new visual registry: none of it is reusable outside this component.
const int _daysPerWeek = 7;

/// Base geometry, expressed at a text scale of 1.0. Every scaled getter below
/// returns exactly these numbers at 1.0, so the owner-approved rendering is
/// byte-for-byte unchanged at normal text size; they only grow when the reader
/// has asked for larger text, which is the case where fixed boxes clip glyphs.
const double _weekdayHeaderHeight = TioSize.dp14;
const double _dateCellSize = TioSize.dp28;
const double _markerRowHeight = TioSize.dp6;
const double _markerDotSize = TioSize.dp4;
const int _monthGridRows = 6;

/// The notch and grabber are deliberately separate geometry. The wide
/// trapezoid stays transparent while the rounded bar remains visible inside.
const double _notchOuterWidth = TioSize.dp80;
const double _notchInnerWidth = TioSize.dp60;
const double _notchDepth = TioSize.dp6;
const double _grabberWidth = TioSize.dp60;
const double _grabberHeight = TioSize.dp3;
const double _grabberRadius = _grabberHeight / 2;

/// Only the invisible touch target reaches past the edge, so the affordance can
/// stay as small as the design wants while the tap target still clears the
/// accessible minimum.
const double _handleTouchHeight = TioSize.dp48;
const double _handleOverhang = _handleTouchHeight - _notchDepth;

/// Larger text may grow the calendar's boxes; smaller text must never shrink
/// the approved geometry, so the scale is floored at 1.
double _resolveTextScale(BuildContext context) =>
    math.max(1, MediaQuery.textScalerOf(context).scale(1));

/// Drag speed past which the gesture settles by direction instead of position.
/// Program behaviour, not a visual contract.
const double _handleFlingVelocity = 320;

class _TioDateCalendarState extends State<TioDateCalendar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expansion;
  PageController? _weekPages;
  PageController? _monthPages;

  late TioDateCalendarDisplayMode _mode;
  late DateTime _visibleMonth;
  int _weekPageCount = 1;
  int _monthPageCount = 1;
  double _dragStartValue = 0;
  DateTime? _pendingWeekReveal;
  DateTime? _pendingMonthReveal;
  DateTime? _lastReportedRangeStart;
  DateTime? _lastReportedRangeEnd;

  /// The exact inputs the two pagers were built from. Page counts alone are not
  /// enough: a range can move while its week count stays identical, which would
  /// leave both pagers anchored to dates that are no longer the range.
  int? _pagerFirstDayOfWeek;
  DateTime? _pagerMinDate;
  DateTime? _pagerMaxDate;

  /// Text scale is read once per frame and cached, so every geometry getter in
  /// one build agrees with the others.
  double _textScale = 1;

  double get _scaledDateCellSize => _dateCellSize * _textScale;
  double get _scaledMarkerRowHeight => _markerRowHeight * _textScale;

  double get _monthRowHeight =>
      _scaledDateCellSize +
      TioSpacing.xxs +
      _scaledMarkerRowHeight +
      TioSpacing.xxs;

  DateTime get _minDate => _dateOnly(widget.minDate);
  DateTime get _maxDate => _dateOnly(widget.maxDate);
  DateTime get _selectedDate => _dateOnly(widget.selectedDate);
  DateTime get _localToday => _dateOnly(widget.localToday);

  @override
  void initState() {
    super.initState();
    _expansion = AnimationController(vsync: this, duration: Duration.zero);
    _mode = widget.allowExpansion
        ? widget.displayMode
        : TioDateCalendarDisplayMode.compact;
    _expansion.value = _mode.isMonth ? 1 : 0;
    _visibleMonth = _monthOf(_selectedDate);
    widget.controller?.addListener(_handleControllerJump);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expansion.duration = context.tioMotion.normal;
    // Never below 1: larger text may grow the boxes, smaller text must not
    // shrink the approved geometry.
    _textScale = math.max(1, MediaQuery.textScalerOf(context).scale(1));
    _syncPagers();
  }

  @override
  void didUpdateWidget(covariant TioDateCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerJump);
      widget.controller?.addListener(_handleControllerJump);
    }
    if (oldWidget.onVisibleDateRangeChanged !=
        widget.onVisibleDateRangeChanged) {
      _lastReportedRangeStart = null;
      _lastReportedRangeEnd = null;
      _scheduleVisibleRangeReport();
    }

    if (!widget.allowExpansion && _mode.isMonth) {
      _applyMode(TioDateCalendarDisplayMode.compact, notify: false);
    } else if (widget.displayMode != oldWidget.displayMode &&
        widget.displayMode != _mode) {
      _applyMode(widget.displayMode, notify: false);
    }

    final rangeChanged = _dateOnly(oldWidget.minDate) != _minDate ||
        _dateOnly(oldWidget.maxDate) != _maxDate ||
        oldWidget.resolvedFirstDayOfWeek != widget.resolvedFirstDayOfWeek;
    final selectionChanged = _dateOnly(oldWidget.selectedDate) != _selectedDate;

    if (rangeChanged) {
      _syncPagers();
    }
    if (selectionChanged) {
      if (!_isSameMonth(_visibleMonth, _selectedDate)) {
        setState(() => _visibleMonth = _monthOf(_selectedDate));
      }
      _revealDate(_selectedDate);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerJump);
    _weekPages?.dispose();
    _monthPages?.dispose();
    _expansion.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- week pager

  int _firstDayOfWeek(BuildContext context) {
    final explicit = widget.resolvedFirstDayOfWeek;
    if (explicit != null) return explicit;
    final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    return index == 0 ? DateTime.sunday : index;
  }

  DateTime _startOfWeek(DateTime date, int firstDayOfWeek) {
    final offset = (date.weekday - firstDayOfWeek) % _daysPerWeek;
    return _addDays(date, -offset);
  }

  /// Rebuilds the pager whenever the range or the week start changes, because
  /// both of those move which week a page index means.
  void _syncPagers() {
    final firstDayOfWeek = _firstDayOfWeek(context);
    // Compare the range itself, not a count derived from it. Moving maxDate
    // from Aug 31 to Sep 1 leaves the week count at six while adding a whole
    // month page, and anchoring on the count alone would keep September
    // unreachable.
    if (_weekPages != null &&
        _pagerFirstDayOfWeek == firstDayOfWeek &&
        _pagerMinDate == _minDate &&
        _pagerMaxDate == _maxDate) {
      return;
    }
    _pagerFirstDayOfWeek = firstDayOfWeek;
    _pagerMinDate = _minDate;
    _pagerMaxDate = _maxDate;
    _weekPageCount = _computeWeekPageCount(firstDayOfWeek);
    _monthPageCount = _computeMonthPageCount();

    _weekPages?.dispose();
    _weekPages = PageController(
      initialPage: _weekPageOf(_selectedDate, firstDayOfWeek),
    );
    _monthPages?.dispose();
    _monthPages = PageController(initialPage: _monthPageOf(_selectedDate));

    // A jump requested before this widget existed has been sitting on the
    // controller with nobody listening. The pagers exist now, so honour it.
    final pending = widget.controller?.pendingJump;
    if (pending != null) {
      widget.controller?.consumePendingJump();
      if (!_isSameMonth(_visibleMonth, pending)) {
        _visibleMonth = _monthOf(pending);
      }
      _pendingWeekReveal = pending;
      _pendingMonthReveal = pending;
    }

    _scheduleVisibleRangeReport();
    if (mounted) setState(() {});
  }

  int _monthPageOf(DateTime date) {
    final first = _monthOf(_minDate);
    final page =
        ((date.year * 12) + date.month) - ((first.year * 12) + first.month);
    return page.clamp(0, _monthPageCount - 1);
  }

  int _computeMonthPageCount() {
    final first = _monthOf(_minDate);
    final last = _monthOf(_maxDate);
    return ((last.year * 12) + last.month) -
        ((first.year * 12) + first.month) +
        1;
  }

  DateTime _monthForPage(int page) {
    final first = _monthOf(_minDate);
    return DateTime(first.year, first.month + page);
  }

  void _scheduleVisibleRangeReport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mode.isMonth) {
        final pager = _monthPages;
        final page = pager != null && pager.hasClients
            ? pager.page?.round() ?? pager.initialPage
            : _monthPageOf(_selectedDate);
        _reportVisibleMonth(page);
        return;
      }
      final firstDayOfWeek = _firstDayOfWeek(context);
      final pager = _weekPages;
      final page = pager != null && pager.hasClients
          ? pager.page?.round() ?? pager.initialPage
          : _weekPageOf(_selectedDate, firstDayOfWeek);
      _reportVisibleWeek(
        page,
        firstDayOfWeek,
      );
    });
  }

  void _reportVisibleWeek(int page, int firstDayOfWeek) {
    final firstDate = _addDays(
      _startOfWeek(_minDate, firstDayOfWeek),
      page * _daysPerWeek,
    );
    _reportVisibleRange(firstDate, _addDays(firstDate, _daysPerWeek - 1));
  }

  void _reportVisibleMonth(int page) {
    final firstDate = _monthForPage(page);
    final lastDate = DateTime(firstDate.year, firstDate.month + 1, 0);
    _reportVisibleRange(firstDate, lastDate);
  }

  void _reportVisibleRange(DateTime firstDate, DateTime lastDate) {
    final start = _dateOnly(firstDate);
    final end = _dateOnly(lastDate);
    if (_lastReportedRangeStart == start && _lastReportedRangeEnd == end) {
      return;
    }
    _lastReportedRangeStart = start;
    _lastReportedRangeEnd = end;
    widget.onVisibleDateRangeChanged?.call(start, end);
  }

  int _computeWeekPageCount(int firstDayOfWeek) {
    final first = _startOfWeek(_minDate, firstDayOfWeek);
    final last = _startOfWeek(_maxDate, firstDayOfWeek);
    return (_daysBetween(first, last) ~/ _daysPerWeek) + 1;
  }

  int _weekPageOf(DateTime date, int firstDayOfWeek) {
    final first = _startOfWeek(_minDate, firstDayOfWeek);
    final target = _startOfWeek(date, firstDayOfWeek);
    final page = _daysBetween(first, target) ~/ _daysPerWeek;
    return page.clamp(0, _weekPageCount - 1);
  }

  /// Brings [date] into view in whichever pager is currently mounted, and
  /// remembers it for the other one. A pager that is not showing has no
  /// viewport, so the request has to survive until it is built — otherwise a
  /// date picked in the month grid would collapse onto the wrong week.
  void _revealDate(DateTime date) {
    _movePager(
      _weekPages,
      _weekPageOf(date, _firstDayOfWeek(context)),
      onDetached: () => _pendingWeekReveal = date,
      onMoved: () => _pendingWeekReveal = null,
    );
    _movePager(
      _monthPages,
      _monthPageOf(date),
      onDetached: () => _pendingMonthReveal = date,
      onMoved: () => _pendingMonthReveal = null,
    );
  }

  void _movePager(
    PageController? pager,
    int page, {
    required VoidCallback onDetached,
    required VoidCallback onMoved,
  }) {
    if (pager == null || !pager.hasClients) {
      onDetached();
      return;
    }
    onMoved();
    if (pager.page?.round() == page) return;

    final duration = context.tioMotion.normal;
    if (duration == Duration.zero) {
      pager.jumpToPage(page);
      return;
    }
    pager.animateToPage(page, duration: duration, curve: Curves.easeOutCubic);
  }

  /// Applies a reveal that was requested while [pager] had no viewport.
  void _drainPendingReveal(DateTime? pending) {
    if (pending == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealDate(pending);
    });
  }

  void _handleControllerJump() {
    final target = widget.controller?.pendingJump;
    if (target == null) return;
    widget.controller?.consumePendingJump();
    if (!_isSameMonth(_visibleMonth, target)) {
      setState(() => _visibleMonth = _monthOf(target));
    }
    _revealDate(target);
  }

  // --------------------------------------------------------------- mode change

  void _applyMode(TioDateCalendarDisplayMode mode, {required bool notify}) {
    if (mode.isMonth) {
      _visibleMonth = _monthOf(_selectedDate);
    }
    setState(() => _mode = mode);
    final duration = context.tioMotion.normal;
    if (duration == Duration.zero) {
      _expansion.value = mode.isMonth ? 1 : 0;
    } else {
      _expansion.animateTo(mode.isMonth ? 1 : 0, curve: Curves.easeOutCubic);
    }
    _revealDate(_selectedDate);
    // Switching rendering changes what "visible" means — a week becomes a
    // month. Without this the caller keeps the old week range and answers
    // questions like "is Today on screen?" from a page nobody is looking at.
    _scheduleVisibleRangeReport();
    if (notify) widget.onDisplayModeChanged?.call(mode);
  }

  void _toggleMode() {
    _applyMode(
      _mode.isMonth
          ? TioDateCalendarDisplayMode.compact
          : TioDateCalendarDisplayMode.month,
      notify: true,
    );
  }

  void _handleTapOutside(PointerDownEvent _) {
    if (!widget.allowExpansion || !_mode.isMonth) return;
    _applyMode(TioDateCalendarDisplayMode.compact, notify: true);
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStartValue = _expansion.value;
    if (_expansion.value == 0) {
      setState(() => _visibleMonth = _monthOf(_selectedDate));
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final extent = _monthBodyHeight - _compactBodyHeight;
    if (extent <= 0) return;
    _expansion.value = (_expansion.value + (details.primaryDelta ?? 0) / extent)
        .clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final TioDateCalendarDisplayMode settled;
    if (velocity.abs() >= _handleFlingVelocity) {
      settled = velocity > 0
          ? TioDateCalendarDisplayMode.month
          : TioDateCalendarDisplayMode.compact;
    } else {
      settled = _expansion.value >= 0.5
          ? TioDateCalendarDisplayMode.month
          : TioDateCalendarDisplayMode.compact;
    }
    final moved = settled != _mode || _expansion.value != _dragStartValue;
    _applyMode(settled, notify: moved && settled != _mode);
  }

  void _handleDateTap(DateTime date) {
    if (!_isSelectable(date)) return;
    widget.onDateSelected(date);
  }

  bool _isSelectable(DateTime date) =>
      !date.isBefore(_minDate) && !date.isAfter(_maxDate);

  // ------------------------------------------------------------------ geometry

  /// The compact body is one month row plus breathing room below it. Sizing the
  /// row itself identically to a month row is what keeps a date numeral from
  /// hopping vertically as the calendar expands: both centre the same content
  /// in the same box, and the spare height sits underneath rather than being
  /// absorbed into the centring.
  double get _compactRowHeight => _monthRowHeight;
  double get _compactBodyHeight =>
      _compactRowHeight + TioSpacing.xs + TioSpacing.xxs;

  /// Every month page is the same height. A grid that grew and shrank by a
  /// row as you swiped would make the whole screen below it jump.
  double get _monthBodyHeight =>
      (_monthRowHeight * _monthGridRows) + TioSpacing.xs;

  // --------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final firstDayOfWeek = _firstDayOfWeek(context);

    return TapRegion(
      onTapOutside: _handleTapOutside,
      child: AnimatedBuilder(
        animation: _expansion,
        builder: (context, _) {
          final t = _expansion.value;

          return Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _surface(context, t, firstDayOfWeek, colors),
                  // Transparent band that keeps the handle's full touch target
                  // inside this widget's own bounds. Flutter does not hit-test
                  // a child painted outside its parent, so an overhanging
                  // target would simply swallow nothing and the handle would
                  // feel dead.
                  if (widget.allowExpansion)
                    const SizedBox(height: _handleOverhang),
                ],
              ),
              if (widget.allowExpansion)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _handleTouchHeight,
                  child: _CalendarHandle(
                    expanded: _mode.isMonth,
                    onTap: _toggleMode,
                    onVerticalDragStart: _handleDragStart,
                    onVerticalDragUpdate: _handleDragUpdate,
                    onVerticalDragEnd: _handleDragEnd,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _surface(
    BuildContext context,
    double t,
    int firstDayOfWeek,
    TioColors colors,
  ) {
    final bodyHeight =
        _compactBodyHeight + (_monthBodyHeight - _compactBodyHeight) * t;

    return ClipPath(
      clipper: const _NotchedSurfaceClipper(
        notchOuterWidth: _notchOuterWidth,
        notchInnerWidth: _notchInnerWidth,
        notchDepth: _notchDepth,
      ),
      child: ColoredBox(
        color: colors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WeekdayHeader(firstDayOfWeek: firstDayOfWeek),
            SizedBox(
              height: bodyHeight,
              child: ClipRect(
                child: Stack(
                  children: [
                    if (t < 1)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: _compactBodyHeight,
                        child: Opacity(
                          opacity: 1 - t,
                          child: _buildWeekPager(firstDayOfWeek),
                        ),
                      ),
                    if (t > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: _monthBodyHeight,
                        child: Opacity(
                          opacity: t,
                          child: _buildMonthGrid(firstDayOfWeek),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.allowExpansion) const SizedBox(height: _notchDepth),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekPager(int firstDayOfWeek) {
    final pager = _weekPages;
    if (pager == null) return const SizedBox.shrink();

    _drainPendingReveal(_pendingWeekReveal);

    return PageView.builder(
      key: const ValueKey('tio-date-calendar-week-pager'),
      controller: pager,
      itemCount: _weekPageCount,
      onPageChanged: (page) {
        // Both pagers stay mounted through the expand animation, and moving
        // one moves the other. Only the rendering actually on screen may
        // report what is visible.
        if (_mode.isMonth) return;
        _reportVisibleWeek(page, firstDayOfWeek);
      },
      itemBuilder: (context, page) {
        final weekStart = _addDays(
            _startOfWeek(_minDate, firstDayOfWeek), page * _daysPerWeek);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: _compactRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.xs),
              child: Row(
                children: [
                  for (var i = 0; i < _daysPerWeek; i++)
                    Expanded(child: _cellFor(_addDays(weekStart, i))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(int firstDayOfWeek) {
    final pager = _monthPages;
    if (pager == null) return const SizedBox.shrink();

    _drainPendingReveal(_pendingMonthReveal);

    return PageView.builder(
      key: const ValueKey('tio-date-calendar-month-pager'),
      controller: pager,
      itemCount: _monthPageCount,
      onPageChanged: (page) {
        setState(() => _visibleMonth = _monthForPage(page));
        if (!_mode.isMonth) return;
        _reportVisibleMonth(page);
      },
      itemBuilder: (context, page) {
        final month = _monthForPage(page);
        final leading =
            (DateTime(month.year, month.month).weekday - firstDayOfWeek) %
                _daysPerWeek;

        return Column(
          children: [
            for (var row = 0; row < _monthGridRows; row++)
              SizedBox(
                height: _monthRowHeight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: TioSpacing.xs),
                  child: Row(
                    children: [
                      for (var column = 0; column < _daysPerWeek; column++)
                        Expanded(
                          child: _cellFor(
                            DateTime(
                              month.year,
                              month.month,
                              1 + (row * _daysPerWeek) + column - leading,
                            ),
                            contextMonth: month,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _cellFor(DateTime date, {DateTime? contextMonth}) {
    final outsideMonth =
        contextMonth != null && !_isSameMonth(date, contextMonth);
    return _DateCell(
      key: ValueKey(date),
      date: date,
      isSelected: date == _selectedDate,
      isToday: date == _localToday,
      // Out of range, or a neighbouring month's day shown only to keep the grid
      // square. Both stay visible so a week never breaks into holes, and both
      // are inert so neither can pass for a date you could pick.
      isEnabled: _isSelectable(date) && !outsideMonth,
      decoration: widget.decorationBuilder?.call(date),
      onTap: _handleDateTap,
    );
  }
}

/// One weekday row shared by both renderings. Keeping it outside the animated
/// body is what makes compact and month read as the same component: the columns
/// never move, only what sits under them.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.firstDayOfWeek});

  final int firstDayOfWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toString();
    final shortWeekdays = List<String>.generate(
      _daysPerWeek,
      (index) => DateFormat.E(localeName)
          .format(DateTime(2024, DateTime.january, 7 + index))
          .toUpperCase(),
      growable: false,
    );

    return Padding(
      padding: const EdgeInsets.all(TioSpacing.xs),
      child: SizedBox(
        key: const ValueKey('tio-date-calendar-weekday-header'),
        height: _weekdayHeaderHeight * _resolveTextScale(context),
        child: Row(
          children: [
            for (var column = 0; column < _daysPerWeek; column++)
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    shortWeekdays[(firstDayOfWeek + column) % _daysPerWeek],
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: (firstDayOfWeek + column) % _daysPerWeek == 0
                          ? colors.danger.withAlpha(TioAlpha.alpha140)
                          : colors.textMuted,
                      fontWeight: TioFontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The centered notch handle. It is the only part of the calendar that owns a
/// vertical drag, which is what keeps an ordinary page scroll from expanding
/// the calendar by accident.
class _CalendarHandle extends StatelessWidget {
  const _CalendarHandle({
    required this.expanded,
    required this.onTap,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  final bool expanded;
  final VoidCallback onTap;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final localizations = MaterialLocalizations.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _notchOuterWidth,
        height: _handleTouchHeight,
        child: Semantics(
          button: true,
          expanded: expanded,
          label: expanded
              ? localizations.expandedIconTapHint
              : localizations.collapsedIconTapHint,
          child: GestureDetector(
            key: const ValueKey('tio-date-calendar-handle'),
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onVerticalDragStart: onVerticalDragStart,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _notchOuterWidth,
                height: _notchDepth,
                child: Center(
                  child: SizedBox(
                    width: _grabberWidth,
                    height: _grabberHeight,
                    child: DecoratedBox(
                      key: const ValueKey('tio-date-calendar-grabber'),
                      decoration: BoxDecoration(
                        color: colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(_grabberRadius),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A centered trapezoid cut with a narrower inner edge, drawn from the origin.
Path _notchPath(double outerWidth, double innerWidth, double depth) {
  final inset = (outerWidth - innerWidth) / 2;
  return Path()
    ..moveTo(0, depth)
    ..lineTo(inset, 0)
    ..lineTo(outerWidth - inset, 0)
    ..lineTo(outerWidth, depth)
    ..close();
}

/// One date in either rendering.
///
/// The layers are independent by construction: the numeral carries Today, a
/// ring outside it carries selection, a ring inside carries progress, the
/// centre carries an optional generic fill, and markers sit below. No layer can
/// overwrite another, which is what lets Nutrition draw progress and Workout
/// draw completion on the same calendar later without colliding.
class _DateCell extends StatelessWidget {
  const _DateCell({
    required super.key,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.decoration,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final TioDateDecoration? decoration;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);
    final scale = _resolveTextScale(context);
    final resolved = isEnabled ? decoration : null;
    final isSunday = date.weekday == DateTime.sunday;

    final Color numeralColor;
    if (!isEnabled) {
      numeralColor = isSunday
          ? colors.danger.withAlpha(TioAlpha.alpha80)
          : colors.textMuted.withAlpha(TioAlpha.alpha100);
    } else if (resolved?.fill == TioDateFill.solid) {
      numeralColor = colors.onPrimary;
    } else if (isSunday) {
      numeralColor = isSelected || isToday
          ? colors.danger
          : colors.danger.withAlpha(TioAlpha.alpha179);
    } else if (isSelected || isToday) {
      numeralColor = colors.textPrimary;
    } else {
      numeralColor = colors.textSecondary;
    }

    final numeral = CustomPaint(
      painter: _DateCirclePainter(
        isSelected: isSelected && isEnabled,
        progress: resolved?.progress,
        fill: resolved?.fill,
        accent: colors.primary,
        track: colors.outlineStrong,
      ),
      child: SizedBox(
        width: _dateCellSize * scale,
        height: _dateCellSize * scale,
        child: Center(
          child: Text(
            localizations.formatDecimal(date.day),
            style: textTheme.bodyLarge?.copyWith(
              color: numeralColor,
              fontWeight: isToday ? TioFontWeight.w700 : TioFontWeight.w400,
            ),
          ),
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        numeral,
        const SizedBox(height: TioSpacing.xxs),
        SizedBox(
          height: _markerRowHeight * scale,
          child: _MarkerRow(decoration: resolved, color: colors.primary),
        ),
      ],
    );

    if (!isEnabled) {
      return ExcludeSemantics(child: Center(child: content));
    }

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: _semanticsLabel(localizations, resolved),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(date),
          child: ExcludeSemantics(child: Center(child: content)),
        ),
      ),
    );
  }

  /// Everything the cell means, in words. Colour, ring and fill never carry
  /// meaning on their own, so each one that is present is also said here.
  String _semanticsLabel(
    MaterialLocalizations localizations,
    TioDateDecoration? decoration,
  ) {
    final parts = <String>[localizations.formatFullDate(date)];
    if (isToday) parts.add(localizations.currentDateLabel);
    if (isSelected) parts.add(localizations.selectedDateLabel);
    final featureLabel = decoration?.semanticsLabel;
    if (featureLabel != null && featureLabel.isNotEmpty) {
      parts.add(featureLabel);
    }
    return parts.join(', ');
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({required this.decoration, required this.color});

  final TioDateDecoration? decoration;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final resolved = decoration;
    if (resolved == null || resolved.markerCount == 0) {
      return const SizedBox.shrink();
    }

    final visible = resolved.visibleMarkerCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < visible; index++) ...[
          if (index > 0) const SizedBox(width: TioSpacing.xxs),
          Container(
            // The last marker widens when the true count exceeds what fits, so
            // a compact row reads as "and more" without the caller's real count
            // ever being clamped.
            width: resolved.hasCollapsedMarkers && index == visible - 1
                ? TioSize.dp8
                : _markerDotSize,
            height: _markerDotSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(TioRadius.full),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateCirclePainter extends CustomPainter {
  const _DateCirclePainter({
    required this.isSelected,
    required this.progress,
    required this.fill,
    required this.accent,
    required this.track,
  });

  final bool isSelected;
  final double? progress;
  final TioDateFill? fill;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    const selectionStroke = TioStroke.width05;
    const progressStroke = TioStroke.width2;
    const gap = TioSize.dp2;

    final progressRadius =
        outerRadius - selectionStroke - gap - (progressStroke / 2);
    final fillRadius = progress == null
        ? outerRadius - selectionStroke - gap
        : progressRadius - (progressStroke / 2) - gap;

    if (fill != null && fillRadius > 0) {
      canvas.drawCircle(
        centre,
        fillRadius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = fill == TioDateFill.solid
              ? accent
              : accent.withValues(alpha: TioOpacity.opacity12),
      );
    }

    final progressValue = progress;
    if (progressValue != null && progressRadius > 0) {
      canvas.drawCircle(
        centre,
        progressRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = progressStroke
          ..color = track.withValues(alpha: TioOpacity.opacity20),
      );
      if (progressValue > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: progressRadius),
          -1.5707963267948966, // 12 o'clock
          6.283185307179586 * progressValue,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = progressStroke
            ..strokeCap = StrokeCap.round
            ..color = accent,
        );
      }
    }

    if (isSelected) {
      canvas.drawCircle(
        centre,
        outerRadius - (selectionStroke / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selectionStroke
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DateCirclePainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.progress != progress ||
        oldDelegate.fill != fill ||
        oldDelegate.accent != accent ||
        oldDelegate.track != track;
  }
}

/// Square-edged surface with a transparent notch cut from the bottom edge.
class _NotchedSurfaceClipper extends CustomClipper<Path> {
  const _NotchedSurfaceClipper({
    required this.notchOuterWidth,
    required this.notchInnerWidth,
    required this.notchDepth,
  });

  final double notchOuterWidth;
  final double notchInnerWidth;
  final double notchDepth;

  @override
  Path getClip(Size size) {
    final resolvedOuterWidth =
        notchOuterWidth.clamp(0.0, size.width).toDouble();
    final resolvedInnerWidth =
        notchInnerWidth.clamp(0.0, resolvedOuterWidth).toDouble();
    final resolvedDepth = notchDepth.clamp(0.0, size.height).toDouble();
    final cut = _notchPath(
      resolvedOuterWidth,
      resolvedInnerWidth,
      resolvedDepth,
    ).shift(
      Offset(
        (size.width - resolvedOuterWidth) / 2,
        size.height - resolvedDepth,
      ),
    );
    final surface = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    return Path.combine(PathOperation.difference, surface, cut);
  }

  @override
  bool shouldReclip(covariant _NotchedSurfaceClipper oldClipper) =>
      oldClipper.notchOuterWidth != notchOuterWidth ||
      oldClipper.notchInnerWidth != notchInnerWidth ||
      oldClipper.notchDepth != notchDepth;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

bool _isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// Day distance that does not drift across a daylight-saving boundary.
int _daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}
