import 'package:tio_core/core.dart';

/// Narrow account-owned capability for persisting display/input unit choices.
///
/// Implementations must mutate only measurement preference fields and leave
/// canonical metric values plus unrelated profile/account data untouched.
abstract interface class MeasurementUnitPreferencesRepository {
  Future<void> updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  );
}
