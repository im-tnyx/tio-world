import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Minimal Workout root shell for TNYX-255.
///
/// This page owns date-navigation presentation state only. Domain-backed
/// workout decorations belong to later Workout slices.
class WorkoutHomePage extends StatefulWidget {
  const WorkoutHomePage({
    super.key,
    this.resolvedFirstDayOfWeek,
    this.clock = DateTime.now,
  });

  final int? resolvedFirstDayOfWeek;
  final DateTime Function() clock;

  @override
  State<WorkoutHomePage> createState() => _WorkoutHomePageState();
}

class _WorkoutHomePageState extends State<WorkoutHomePage> {
  late DateTime _localToday;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _localToday = _dateOnly(widget.clock());
    _selectedDate = _localToday;
  }

  @override
  Widget build(BuildContext context) {
    // TNYX-255 intentionally supplies navigation range only. A real schedule
    // horizon belongs to W1/W2 once canonical Workout truth exists.
    final minDate = DateTime(_localToday.year - 1, _localToday.month, _localToday.day);
    final maxDate = DateTime(_localToday.year + 1, _localToday.month, _localToday.day);

    return Align(
      alignment: Alignment.topCenter,
      child: TioDateCalendar(
        selectedDate: _selectedDate,
        localToday: _localToday,
        minDate: minDate,
        maxDate: maxDate,
        resolvedFirstDayOfWeek: widget.resolvedFirstDayOfWeek,
        onDateSelected: (date) {
          setState(() => _selectedDate = _dateOnly(date));
        },
      ),
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
