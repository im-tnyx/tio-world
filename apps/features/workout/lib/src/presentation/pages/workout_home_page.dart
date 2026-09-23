import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../controllers/workout_date_controller.dart';

/// Minimal Workout root shell for TNYX-255.
///
/// This page owns date-navigation presentation state only. Domain-backed
/// workout decorations belong to later Workout slices.
class WorkoutHomePage extends ConsumerStatefulWidget {
  const WorkoutHomePage({
    super.key,
    this.resolvedFirstDayOfWeek,
  });

  final int? resolvedFirstDayOfWeek;

  @override
  ConsumerState<WorkoutHomePage> createState() => _WorkoutHomePageState();
}

class _WorkoutHomePageState extends ConsumerState<WorkoutHomePage>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

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
      ref.read(workoutDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
      return;
    }

    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final delay =
        ref.read(workoutDateControllerProvider).durationUntilNextLocalMidnight;
    if (delay <= Duration.zero) return;

    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(workoutDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(workoutDateControllerProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: TioDateCalendar(
        controller: dates.calendarController,
        selectedDate: dates.selectedDate,
        localToday: dates.localToday,
        minDate: dates.minDate,
        maxDate: dates.maxDate,
        resolvedFirstDayOfWeek: widget.resolvedFirstDayOfWeek,
        onDateSelected: dates.select,
        onVisibleDateRangeChanged: dates.updateVisibleDateRange,
      ),
    );
  }
}
