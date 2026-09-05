import 'package:intl/intl.dart';

/// Compact month-and-year label for a calendar position, such as `Sep ’26`.
///
/// Deliberately not `Sep 26`: a bare two-digit number sitting next to a month
/// name reads as a day of that month. The apostrophe is what marks it as a
/// year, so the label stays unambiguous at a glance.
///
/// The month name comes from the locale rather than a hard-coded table, so a
/// reader in another language gets their own abbreviation.
String tioCompactMonthYearLabel(DateTime month, {String? localeName}) {
  final abbreviation = DateFormat.MMM(localeName).format(month);
  final year = (month.year % 100).toString().padLeft(2, '0');
  return '$abbreviation ’$year';
}
