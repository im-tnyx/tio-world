/// User-intended local calendar date for a durable meal log.
///
/// This is deliberately not a [DateTime]: a Diary date is calendar identity,
/// not an instant that should move when the device timezone changes.
final class MealLogLocalDate {
  factory MealLogLocalDate({
    required int year,
    required int month,
    required int day,
  }) {
    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year', 'must be between 1 and 9999');
    }

    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError.value(
        '$year-$month-$day',
        'date',
        'must be a valid Gregorian calendar date',
      );
    }

    return MealLogLocalDate._(year, month, day);
  }

  const MealLogLocalDate._(this.year, this.month, this.day);

  /// Decodes the canonical `YYYY-MM-DD` representation.
  factory MealLogLocalDate.fromIso8601String(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('MealLogLocalDate must use YYYY-MM-DD.');
    }

    try {
      return MealLogLocalDate(
        year: int.parse(match.group(1)!),
        month: int.parse(match.group(2)!),
        day: int.parse(match.group(3)!),
      );
    } on ArgumentError {
      throw FormatException('Invalid MealLogLocalDate: $value.');
    }
  }

  final int year;
  final int month;
  final int day;

  /// Canonical calendar-date representation, independent of timezone.
  String toIso8601String() {
    final encodedYear = year.toString().padLeft(4, '0');
    final encodedMonth = month.toString().padLeft(2, '0');
    final encodedDay = day.toString().padLeft(2, '0');
    return '$encodedYear-$encodedMonth-$encodedDay';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLogLocalDate &&
          other.year == year &&
          other.month == month &&
          other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso8601String();
}
