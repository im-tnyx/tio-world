import 'package:flutter/foundation.dart';

/// Generic centre-fill treatments a caller may request for one date.
///
/// The names describe weight, not meaning. Workout may later use [solid] for a
/// completed session and something else may use [soft] for a partial state, but
/// core never learns which is which — that stays with the feature that supplies
/// the decoration.
enum TioDateFill {
  /// A tinted, low-emphasis centre fill.
  soft,

  /// A filled, high-emphasis centre treatment.
  solid,
}

/// Everything a feature can ask [TioDateCalendar] to draw on a single date.
///
/// This is presentation data only. Core never computes it and never interprets
/// it: calories, meal adherence, workout completion, plan status and schedule
/// counts all stay in the feature package that owns them.
///
/// The layers are independent by construction, so a caller may supply any
/// subset and the remaining layers simply do not render:
///
/// ```text
/// outermost  selection ring   derived from selectedDate, never supplied here
/// inside     progress ring    progress
/// centre     generic fill     fill
/// text       date label       Today emphasis derived from localToday
/// below      marker dots      markerCount
/// ```
@immutable
class TioDateDecoration {
  const TioDateDecoration({
    this.progress,
    this.fill,
    this.markerCount = 0,
    this.semanticsLabel,
  })  : assert(
          progress == null || (progress >= 0.0 && progress <= 1.0),
          'progress must be normalized to 0.0..1.0 by the caller.',
        ),
        assert(markerCount >= 0, 'markerCount cannot be negative.');

  /// Normalized progress in `0.0..1.0`, or null when the caller has no value.
  ///
  /// Null and `0.0` are deliberately different and must stay different all the
  /// way to the pixels: null means "not available", `0.0` means "known to be
  /// zero". A feature with no data yet passes null rather than collapsing the
  /// unknown into a real zero.
  final double? progress;

  /// Optional generic centre treatment. Null draws no fill.
  final TioDateFill? fill;

  /// How many caller-owned items sit on this date.
  ///
  /// This is the true count. Rendering is bounded by [maxRenderedMarkers], but
  /// the count itself is never clamped here, so the caller's multiplicity
  /// survives a compact presentation.
  final int markerCount;

  /// Extra meaning for assistive technology, such as what a fill or a marker
  /// row represents. Core has no way to describe a feature's semantics, so a
  /// decoration that carries visual meaning should carry this too.
  final String? semanticsLabel;

  /// The largest number of individual marker dots a date renders.
  static const int maxRenderedMarkers = 3;

  /// Whether this decoration asks for nothing at all.
  bool get isEmpty =>
      progress == null &&
      fill == null &&
      markerCount == 0 &&
      semanticsLabel == null;

  /// How many marker dots actually render, capped at [maxRenderedMarkers].
  int get visibleMarkerCount =>
      markerCount > maxRenderedMarkers ? maxRenderedMarkers : markerCount;

  /// Whether the marker row is a collapsed representation of a larger count.
  bool get hasCollapsedMarkers => markerCount > maxRenderedMarkers;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TioDateDecoration &&
        other.progress == progress &&
        other.fill == fill &&
        other.markerCount == markerCount &&
        other.semanticsLabel == semanticsLabel;
  }

  @override
  int get hashCode => Object.hash(progress, fill, markerCount, semanticsLabel);
}

/// Supplies the decoration for one date, or null when the date has none.
///
/// A builder is used instead of a `Map<DateTime, TioDateDecoration>` because
/// `DateTime` equality includes the time component, so a raw date-keyed map is
/// only correct while every caller normalizes perfectly. The builder receives a
/// date already normalized to midnight by core.
typedef TioDateDecorationBuilder = TioDateDecoration? Function(DateTime date);
