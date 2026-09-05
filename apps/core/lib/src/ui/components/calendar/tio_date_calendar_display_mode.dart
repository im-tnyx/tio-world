/// The two renderings a [TioDateCalendar] can show.
///
/// Both renderings are views of the same caller-controlled selected date, so
/// this is presentation state only. It never carries feature meaning.
enum TioDateCalendarDisplayMode {
  /// Horizontally scrollable chronological date strip. The default.
  compact,

  /// Inline month grid on the same screen, pushing content below it down.
  month;

  bool get isCompact => this == TioDateCalendarDisplayMode.compact;

  bool get isMonth => this == TioDateCalendarDisplayMode.month;
}
