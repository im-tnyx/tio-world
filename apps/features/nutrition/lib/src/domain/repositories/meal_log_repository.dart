import 'package:tio_shared/shared.dart';

/// Raised when a manual MealLog create may already have reached durable
/// storage but the repository cannot confirm its outcome.
///
/// The caller must preserve the same [clientMutationId] and retry the same
/// logical create. Generating a fresh mutation identity after this failure can
/// create duplicate actual history.
final class MealLogCreateOutcomeUnknown implements Exception {
  const MealLogCreateOutcomeUnknown({
    required this.clientMutationId,
    this.cause,
  });

  final String clientMutationId;
  final Object? cause;

  @override
  String toString() =>
      'MealLogCreateOutcomeUnknown(clientMutationId: $clientMutationId)';
}

/// Raised when one stable create mutation identity is reused for different
/// manual MealLog facts.
///
/// Idempotency keys identify one logical operation. Reusing a key for a
/// different payload must fail instead of silently returning unrelated history.
final class MealLogCreateMutationConflict implements Exception {
  const MealLogCreateMutationConflict({required this.clientMutationId});

  final String clientMutationId;

  @override
  String toString() =>
      'MealLogCreateMutationConflict(clientMutationId: $clientMutationId)';
}

/// User/resolver-owned facts required to create one manual MealLog entry.
///
/// Physical row identity, authenticated user identity, mode, and database
/// timestamps are intentionally absent. [clientMutationId] identifies the
/// logical create operation only; it is not the durable MealLog row identity.
/// The repository/database own persistence facts and return the canonical
/// [MealLogEntry] after creation or same-key reconciliation.
final class ManualMealLogCreate {
  ManualMealLogCreate({
    required String clientMutationId,
    required this.mealCategoryId,
    String? mealName,
    String? note,
    required this.consumedAt,
    required this.consumedLocalDate,
    String? consumedTimezoneId,
    this.consumedUtcOffsetMinutes,
    this.captureSource,
    required this.manualNutritionSnapshot,
  })  : clientMutationId = _normalizeClientMutationId(clientMutationId),
        mealName = _normalizeOptionalText(mealName),
        note = _normalizeOptionalText(note),
        consumedTimezoneId = _normalizeOptionalText(consumedTimezoneId) {
    if (this.consumedTimezoneId == null &&
        consumedUtcOffsetMinutes == null) {
      throw ArgumentError(
        'Either consumedTimezoneId or consumedUtcOffsetMinutes must be provided.',
      );
    }
  }

  /// Stable UUID for this one logical create operation.
  ///
  /// A retry of the same logical create reuses this value. A different logical
  /// create, even with identical meal facts, uses a different value.
  final String clientMutationId;
  final String mealCategoryId;
  final String? mealName;
  final String? note;
  final DateTime consumedAt;
  final MealLogLocalDate consumedLocalDate;
  final String? consumedTimezoneId;
  final int? consumedUtcOffsetMinutes;
  final MealLogCaptureSource? captureSource;
  final NutritionSnapshot manualNutritionSnapshot;

  static final _canonicalUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String _normalizeClientMutationId(String value) {
    if (value.trim() != value || !_canonicalUuid.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'clientMutationId',
        'must be a canonical UUID string',
      );
    }
    return value.toLowerCase();
  }

  static String? _normalizeOptionalText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

/// Canonical Nutrition-owned persistence boundary for actual MealLog history.
///
/// TNYX-195 introduced manual create/read. TNYX-196 makes manual create
/// duplicate-safe through a stable client mutation identity. TNYX-197 adds the
/// first selected-Diary-date read contract while keeping update, delete,
/// stale-write handling, durable offline replay and presentation read models in
/// later bounded slices.
abstract interface class MealLogRepository {
  /// Persists one manual/coarse actual meal and returns the durable canonical
  /// aggregate, including store-owned identity and timestamps.
  ///
  /// Repeating this call for the same logical operation must reuse
  /// [ManualMealLogCreate.clientMutationId].
  Future<MealLogEntry> createManual(ManualMealLogCreate input);

  /// Reads one canonical manual MealLog entry by opaque row identity.
  ///
  /// Returns `null` only when that identity is not visible for the current
  /// repository owner. Invalid/blank identities are caller errors.
  Future<MealLogEntry?> readById(String id);

  /// Reads canonical actual history for one stored Diary local-date identity.
  ///
  /// Implementations must group by persisted [MealLogEntry.consumedLocalDate],
  /// never by recomputing a date from [MealLogEntry.consumedAt] in the device's
  /// current timezone. Results are deterministic: newest `consumedAt` first,
  /// then opaque row identity ascending as a stable tie-breaker.
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate);
}
