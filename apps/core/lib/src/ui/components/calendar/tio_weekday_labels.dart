import 'package:intl/intl.dart';

/// The seven weekday abbreviations in the order a week starting on
/// [firstDayOfWeek] renders them, upper-cased.
///
/// `DateTime.monday`..`DateTime.sunday` are all accepted. Any day may start a
/// week: Monday, Sunday and Saturday cover most of the world, and the rest are
/// supported because the arithmetic never needed to special-case them.
///
/// Names come from the locale rather than a hard-coded table, so a reader in
/// another language gets their own abbreviations. Shared by the calendar's own
/// header and by any surface that needs to show what an ordering looks like,
/// so the two can never drift apart.
List<String> tioOrderedWeekdayLabels({
  required int firstDayOfWeek,
  String? localeName,
}) {
  final format = DateFormat.E(localeName);
  // 7 January 2024 was a Sunday, so offset 0 is Sunday. That lines the table up
  // with `DateTime`'s own numbering (Monday 1 .. Sunday 7) under a single
  // modulo, which is also how the calendar places its columns and its cells.
  return List<String>.generate(
    DateTime.daysPerWeek,
    (column) => format.format(_referenceDay(firstDayOfWeek + column)).toUpperCase(),
    growable: false,
  );
}

/// The locale's full name for a `DateTime.monday`..`DateTime.sunday` value.
///
/// Used wherever a week start is named rather than drawn — a Settings option,
/// a summary row — so those surfaces never hard-code an English day name that
/// the calendar beside them would render differently.
String tioWeekdayName(int weekday, {String? localeName}) =>
    DateFormat.EEEE(localeName).format(_referenceDay(weekday));

/// A day in a known week: 7 January 2024 was a Sunday, so this maps
/// `DateTime`'s Monday-1..Sunday-7 numbering onto a real date with one modulo.
DateTime _referenceDay(int weekday) => DateTime(
      2024,
      DateTime.january,
      7 + (weekday % DateTime.daysPerWeek),
    );
