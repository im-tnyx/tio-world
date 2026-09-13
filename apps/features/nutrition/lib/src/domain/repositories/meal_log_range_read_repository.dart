import 'package:tio_shared/shared.dart';

import 'meal_log_repository.dart';

/// Optional canonical MealLog read capability for one inclusive Diary-local
/// date range.
///
/// This sits beside [MealLogRepository]'s single-day contract rather than
/// widening that established interface for every test/future adapter. Runtime
/// repositories that support calendar-range reads implement both contracts.
abstract interface class MealLogRangeReadRepository {
  /// Reads actual MealLog rows whose persisted local-date identity is within
  /// [startDate]..[endDate], inclusive.
  ///
  /// Implementations must reject an inverted range and must filter using
  /// [MealLogEntry.consumedLocalDate], never a device-timezone conversion of
  /// [MealLogEntry.consumedAt]. Results are deterministic: local date ascending,
  /// then newest `consumedAt` first, then opaque row identity ascending.
  Future<List<MealLogEntry>> listByLocalDateRange({
    required MealLogLocalDate startDate,
    required MealLogLocalDate endDate,
  });
}
