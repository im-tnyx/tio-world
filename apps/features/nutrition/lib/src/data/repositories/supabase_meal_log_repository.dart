import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/manual_meal_log_update_repository.dart';
import '../../domain/repositories/meal_categories_repository.dart';
import '../../domain/repositories/meal_log_repository.dart';

typedef CurrentMealLogUserId = String? Function();

/// Injectable table seam for focused mapping/error tests.
abstract interface class MealLogTableGateway {
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload);

  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  });

  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  });

  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  });

  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  });
}

final class SupabaseMealLogTableGateway implements MealLogTableGateway {
  const SupabaseMealLogTableGateway(this._client);

  static const _columns =
      'id, user_id, mode, meal_category_id, meal_name, note, consumed_at, '
      'consumed_local_date, consumed_timezone_id, consumed_utc_offset_minutes, '
      'capture_source, manual_nutrition_snapshot, created_at, updated_at, '
      'client_mutation_id, revision';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) async {
    final row = await _client
        .from('meal_log_entries')
        .insert(payload)
        .select(_columns)
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>?> updateRow({
    required String userId,
    required String id,
    required int expectedRevision,
    required Map<String, dynamic> payload,
  }) async {
    final row = await _client
        .from('meal_log_entries')
        .update(payload)
        .eq('user_id', userId)
        .eq('id', id)
        .eq('revision', expectedRevision)
        .select(_columns)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) async {
    final row = await _client
        .from('meal_log_entries')
        .select(_columns)
        .eq('user_id', userId)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>?> readRowByClientMutationId({
    required String userId,
    required String clientMutationId,
  }) async {
    final row = await _client
        .from('meal_log_entries')
        .select(_columns)
        .eq('user_id', userId)
        .eq('client_mutation_id', clientMutationId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDate({
    required String userId,
    required String localDate,
  }) async {
    final rows = await _client
        .from('meal_log_entries')
        .select(_columns)
        .eq('user_id', userId)
        .eq('consumed_local_date', localDate)
        .order('consumed_at', ascending: false)
        .order('id');
    return [
      for (final row in rows) Map<String, dynamic>.from(row),
    ];
  }
}

/// Supabase adapter for canonical manual MealLog persistence.
///
/// Authenticated identity is derived from the current Supabase session and RLS
/// remains the final database ownership authority. TNYX-196 adds stable create
/// idempotency: the database unique invariant is the final duplicate guard, and
/// transport ambiguity is reconciled with the same client mutation identity.
/// TNYX-197 adds owner-scoped selected-local-date history reads. TNYX-203 adds
/// optimistic manual updates using the durable row revision without changing
/// manual-mode identity or capture provenance.
final class SupabaseMealLogRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  SupabaseMealLogRepository({
    required SupabaseClient client,
    required MealCategoriesRepository mealCategoriesRepository,
    MealLogTableGateway? gateway,
    CurrentMealLogUserId? currentUserId,
  })  : _mealCategoriesRepository = mealCategoriesRepository,
        _gateway = gateway ?? SupabaseMealLogTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final MealCategoriesRepository _mealCategoriesRepository;
  final MealLogTableGateway _gateway;
  final CurrentMealLogUserId _currentUserId;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    final userId = _requireUserId();

    // Reconcile before validating current category activity. A previous attempt
    // may already have committed and lost its response; that historical fact
    // must remain returnable even if the category was archived afterwards.
    final existing = await _readMutationForCreate(
      userId: userId,
      input: input,
    );
    if (existing != null) {
      return _decodeCreateResult(
        existing,
        expectedUserId: userId,
        input: input,
      );
    }

    await _requireActiveMealCategory(input.mealCategoryId);
    final payload = <String, dynamic>{
      'user_id': userId,
      'mode': MealLogMode.manual.storageValue,
      'meal_category_id': input.mealCategoryId,
      'meal_name': input.mealName,
      'note': input.note,
      'consumed_at': input.consumedAt.toUtc().toIso8601String(),
      'consumed_local_date': input.consumedLocalDate.toIso8601String(),
      'consumed_timezone_id': input.consumedTimezoneId,
      'consumed_utc_offset_minutes': input.consumedUtcOffsetMinutes,
      'capture_source': input.captureSource?.storageValue,
      'manual_nutrition_snapshot': input.manualNutritionSnapshot.toJson(),
      'client_mutation_id': input.clientMutationId,
    };

    Map<String, dynamic> row;
    try {
      row = await _gateway.insertRow(payload);
    } on Object catch (error) {
      if (!_shouldReconcileInsertFailure(error)) rethrow;
      return _reconcileAfterInsertFailure(
        userId: userId,
        input: input,
        cause: error,
      );
    }

    return _decodeCreateResult(
      row,
      expectedUserId: userId,
      input: input,
    );
  }

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    final userId = _requireUserId();
    final beforeRow = await _gateway.readRow(userId: userId, id: input.id);
    if (beforeRow == null) {
      throw MealLogUpdateNotFound(id: input.id);
    }
    final before = _decodeManualRow(beforeRow, expectedUserId: userId);
    if (before.id != input.id) {
      throw const FormatException(
        'Invalid MealLog row: id does not match update target.',
      );
    }
    if (before.revision != input.expectedRevision) {
      throw MealLogUpdateConflict(
        id: input.id,
        expectedRevision: input.expectedRevision,
        actualRevision: before.revision,
      );
    }

    // Retaining a historical/archived category is valid. Moving this entry to
    // a different category requires the destination to be active now.
    if (input.mealCategoryId != before.mealCategoryId) {
      await _requireActiveMealCategory(input.mealCategoryId);
    }

    final payload = <String, dynamic>{
      'meal_category_id': input.mealCategoryId,
      'meal_name': input.mealName,
      'note': input.note,
      'consumed_at': input.consumedAt.toUtc().toIso8601String(),
      'consumed_local_date': input.consumedLocalDate.toIso8601String(),
      'consumed_timezone_id': input.consumedTimezoneId,
      'consumed_utc_offset_minutes': input.consumedUtcOffsetMinutes,
      'manual_nutrition_snapshot': input.manualNutritionSnapshot.toJson(),
    };

    Map<String, dynamic>? row;
    try {
      row = await _gateway.updateRow(
        userId: userId,
        id: input.id,
        expectedRevision: input.expectedRevision,
        payload: payload,
      );
    } on Object catch (error) {
      if (!_isAmbiguousGatewayFailure(error)) rethrow;
      return _reconcileAfterUpdateAttempt(
        userId: userId,
        before: before,
        beforeRow: beforeRow,
        input: input,
        cause: error,
      );
    }

    if (row == null) {
      return _reconcileAfterUpdateAttempt(
        userId: userId,
        before: before,
        beforeRow: beforeRow,
        input: input,
      );
    }

    return _decodeUpdateResult(
      row,
      expectedUserId: userId,
      before: before,
      beforeRow: beforeRow,
      input: input,
    );
  }

  @override
  Future<MealLogEntry?> readById(String id) async {
    final userId = _requireUserId();
    _requireNonBlank(id, 'id');
    final row = await _gateway.readRow(userId: userId, id: id);
    if (row == null) return null;
    return _decodeManualRow(row, expectedUserId: userId);
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(
    MealLogLocalDate localDate,
  ) async {
    final userId = _requireUserId();
    final rows = await _gateway.listRowsByLocalDate(
      userId: userId,
      localDate: localDate.toIso8601String(),
    );
    final entries = [
      for (final row in rows)
        _decodeManualRow(row, expectedUserId: userId),
    ]..sort(_compareDiaryOrder);
    return List<MealLogEntry>.unmodifiable(entries);
  }

  Future<Map<String, dynamic>?> _readMutationForCreate({
    required String userId,
    required ManualMealLogCreate input,
  }) async {
    try {
      return await _gateway.readRowByClientMutationId(
        userId: userId,
        clientMutationId: input.clientMutationId,
      );
    } on Object catch (error) {
      if (!_isAmbiguousGatewayFailure(error)) rethrow;
      throw MealLogCreateOutcomeUnknown(
        clientMutationId: input.clientMutationId,
        cause: error,
      );
    }
  }

  Future<MealLogEntry> _reconcileAfterInsertFailure({
    required String userId,
    required ManualMealLogCreate input,
    required Object cause,
  }) async {
    Map<String, dynamic>? row;
    try {
      row = await _gateway.readRowByClientMutationId(
        userId: userId,
        clientMutationId: input.clientMutationId,
      );
    } on Object catch (readError) {
      if (!_isAmbiguousGatewayFailure(readError)) rethrow;
      throw MealLogCreateOutcomeUnknown(
        clientMutationId: input.clientMutationId,
        cause: cause,
      );
    }

    if (row == null) {
      throw MealLogCreateOutcomeUnknown(
        clientMutationId: input.clientMutationId,
        cause: cause,
      );
    }

    return _decodeCreateResult(
      row,
      expectedUserId: userId,
      input: input,
    );
  }

  Future<MealLogEntry> _reconcileAfterUpdateAttempt({
    required String userId,
    required MealLogEntry before,
    required Map<String, dynamic> beforeRow,
    required ManualMealLogUpdate input,
    Object? cause,
  }) async {
    Map<String, dynamic>? row;
    try {
      row = await _gateway.readRow(userId: userId, id: input.id);
    } on Object catch (readError) {
      if (!_isAmbiguousGatewayFailure(readError)) rethrow;
      throw MealLogUpdateOutcomeUnknown(
        id: input.id,
        expectedRevision: input.expectedRevision,
        cause: cause ?? readError,
      );
    }

    if (row == null) {
      if (cause == null) {
        throw MealLogUpdateNotFound(id: input.id);
      }
      throw MealLogUpdateOutcomeUnknown(
        id: input.id,
        expectedRevision: input.expectedRevision,
        cause: cause,
      );
    }

    final current = _decodeManualRow(row, expectedUserId: userId);
    if (current.revision == input.expectedRevision + 1 &&
        _matchesUpdateInput(current, input) &&
        _preservesUpdateImmutableFacts(
          before: before,
          beforeRow: beforeRow,
          current: current,
          currentRow: row,
        )) {
      return current;
    }

    if (current.revision != input.expectedRevision) {
      throw MealLogUpdateConflict(
        id: input.id,
        expectedRevision: input.expectedRevision,
        actualRevision: current.revision,
      );
    }

    throw MealLogUpdateOutcomeUnknown(
      id: input.id,
      expectedRevision: input.expectedRevision,
      cause: cause,
    );
  }

  static bool _shouldReconcileInsertFailure(Object error) {
    if (error is! PostgrestException) return true;
    if (error.code == '23505') return true;
    return _isAmbiguousPostgrestFailure(error);
  }

  static bool _isAmbiguousGatewayFailure(Object error) {
    if (error is! PostgrestException) return true;
    return _isAmbiguousPostgrestFailure(error);
  }

  static bool _isAmbiguousPostgrestFailure(PostgrestException error) {
    final code = error.code;
    if (code == null || code.isEmpty) return true;

    // Data/integrity/auth/request-shape failures are explicit rejections, not
    // response-loss ambiguity. Uniqueness is handled separately because it is
    // the expected concurrent/same-key idempotency signal.
    if (code.startsWith('22') ||
        (code.startsWith('23') && code != '23505') ||
        code.startsWith('28') ||
        code == '42501' ||
        code.startsWith('PGRST1') ||
        code.startsWith('PGRST3')) {
      return false;
    }
    return true;
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to access MealLog history.');
    }
    return userId;
  }

  Future<void> _requireActiveMealCategory(String id) async {
    if (id.isEmpty || id.trim() != id) {
      throw ArgumentError.value(
        id,
        'mealCategoryId',
        'must be a canonical Meal Category identity',
      );
    }
    final config = await _mealCategoriesRepository.read();
    final category = config.findById(id);
    if (category == null || !category.active) {
      throw ArgumentError.value(
        id,
        'mealCategoryId',
        'must reference an active Meal Category',
      );
    }
  }

  static int _compareDiaryOrder(MealLogEntry left, MealLogEntry right) {
    final byConsumedAt = right.consumedAt.compareTo(left.consumedAt);
    if (byConsumedAt != 0) return byConsumedAt;
    return left.id.compareTo(right.id);
  }

  static MealLogEntry _decodeCreateResult(
    Map<String, dynamic> row, {
    required String expectedUserId,
    required ManualMealLogCreate input,
  }) {
    _requireKeys(row);
    final mutationId = _nullableString(row, 'client_mutation_id');
    if (mutationId != input.clientMutationId) {
      throw const FormatException(
        'Invalid MealLog row: client_mutation_id does not match create operation.',
      );
    }

    final entry = _decodeManualRow(row, expectedUserId: expectedUserId);
    if (entry.revision == 1) {
      if (!_matchesCreateInput(entry, input)) {
        throw MealLogCreateMutationConflict(
          clientMutationId: input.clientMutationId,
        );
      }
      return entry;
    }

    // Once the same durable row has been edited, mutable create-time facts can
    // legitimately differ from the original create request. The immutable
    // mutation identity still prevents a duplicate insert; capture provenance
    // remains immutable and is the only create input that is still comparable.
    if (entry.captureSource != input.captureSource) {
      throw MealLogCreateMutationConflict(
        clientMutationId: input.clientMutationId,
      );
    }
    return entry;
  }

  static MealLogEntry _decodeUpdateResult(
    Map<String, dynamic> row, {
    required String expectedUserId,
    required MealLogEntry before,
    required Map<String, dynamic> beforeRow,
    required ManualMealLogUpdate input,
  }) {
    final entry = _decodeManualRow(row, expectedUserId: expectedUserId);
    if (entry.id != input.id ||
        entry.revision != input.expectedRevision + 1 ||
        !_matchesUpdateInput(entry, input) ||
        !_preservesUpdateImmutableFacts(
          before: before,
          beforeRow: beforeRow,
          current: entry,
          currentRow: row,
        )) {
      throw const FormatException(
        'Invalid MealLog row: update result violates the optimistic update contract.',
      );
    }
    return entry;
  }

  static bool _matchesCreateInput(
    MealLogEntry entry,
    ManualMealLogCreate input,
  ) {
    return entry.mealCategoryId == input.mealCategoryId &&
        entry.mealName == input.mealName &&
        entry.note == input.note &&
        entry.consumedAt == input.consumedAt.toUtc() &&
        entry.consumedLocalDate == input.consumedLocalDate &&
        entry.consumedTimezoneId == input.consumedTimezoneId &&
        entry.consumedUtcOffsetMinutes == input.consumedUtcOffsetMinutes &&
        entry.captureSource == input.captureSource &&
        entry.manualNutritionSnapshot == input.manualNutritionSnapshot;
  }

  static bool _matchesUpdateInput(
    MealLogEntry entry,
    ManualMealLogUpdate input,
  ) {
    return entry.id == input.id &&
        entry.mealCategoryId == input.mealCategoryId &&
        entry.mealName == input.mealName &&
        entry.note == input.note &&
        entry.consumedAt == input.consumedAt.toUtc() &&
        entry.consumedLocalDate == input.consumedLocalDate &&
        entry.consumedTimezoneId == input.consumedTimezoneId &&
        entry.consumedUtcOffsetMinutes == input.consumedUtcOffsetMinutes &&
        entry.manualNutritionSnapshot == input.manualNutritionSnapshot;
  }

  static bool _preservesUpdateImmutableFacts({
    required MealLogEntry before,
    required Map<String, dynamic> beforeRow,
    required MealLogEntry current,
    required Map<String, dynamic> currentRow,
  }) {
    return current.id == before.id &&
        current.userId == before.userId &&
        current.mode == before.mode &&
        current.captureSource == before.captureSource &&
        current.createdAt == before.createdAt &&
        _nullableString(currentRow, 'client_mutation_id') ==
            _nullableString(beforeRow, 'client_mutation_id');
  }

  static MealLogEntry _decodeManualRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    _requireKeys(row);

    final userId = _requiredString(row, 'user_id');
    if (userId != expectedUserId) {
      throw const FormatException(
        'Invalid MealLog row: user_id does not match the authenticated owner.',
      );
    }

    final rawMode = _requiredString(row, 'mode');
    final mode = MealLogMode.fromStorageValue(rawMode);
    if (mode != MealLogMode.manual) {
      throw FormatException('Unsupported MealLog mode: $rawMode.');
    }

    MealLogCaptureSource? captureSource;
    final rawCaptureSource = _nullableString(row, 'capture_source');
    if (rawCaptureSource != null) {
      captureSource = MealLogCaptureSource.fromStorageValue(rawCaptureSource);
      if (captureSource == null) {
        throw FormatException(
          'Unsupported MealLog capture source: $rawCaptureSource.',
        );
      }
    }

    final timezoneId = _normalizeOptionalText(
      _nullableString(row, 'consumed_timezone_id'),
    );
    final utcOffsetMinutes = _nullableInt(row, 'consumed_utc_offset_minutes');
    if (timezoneId == null && utcOffsetMinutes == null) {
      throw const FormatException(
        'Invalid MealLog row: consumed timezone context is missing.',
      );
    }

    final snapshotJson = _jsonObject(row['manual_nutrition_snapshot']);
    final snapshot = NutritionSnapshot.fromJson(snapshotJson);

    return MealLogEntry.manual(
      id: _requiredString(row, 'id'),
      userId: userId,
      mealCategoryId: _requiredString(row, 'meal_category_id'),
      mealName: _nullableString(row, 'meal_name'),
      note: _nullableString(row, 'note'),
      consumedAt: _requiredDateTime(row, 'consumed_at'),
      consumedLocalDate: MealLogLocalDate.fromIso8601String(
        _requiredString(row, 'consumed_local_date'),
      ),
      consumedTimezoneId: timezoneId,
      consumedUtcOffsetMinutes: utcOffsetMinutes,
      captureSource: captureSource,
      manualNutritionSnapshot: snapshot,
      revision: _requiredInt(row, 'revision'),
      createdAt: _requiredDateTime(row, 'created_at'),
      updatedAt: _requiredDateTime(row, 'updated_at'),
    );
  }

  static const _requiredRowKeys = <String>{
    'id',
    'user_id',
    'mode',
    'meal_category_id',
    'meal_name',
    'note',
    'consumed_at',
    'consumed_local_date',
    'consumed_timezone_id',
    'consumed_utc_offset_minutes',
    'capture_source',
    'manual_nutrition_snapshot',
    'created_at',
    'updated_at',
    'client_mutation_id',
    'revision',
  };

  static final _instantOffsetSuffix = RegExp(
    r'(?:[zZ]|[+-]\d{2}:\d{2})$',
  );

  static void _requireKeys(Map<String, dynamic> row) {
    for (final key in _requiredRowKeys) {
      if (!row.containsKey(key)) {
        throw FormatException('Invalid MealLog row: missing $key.');
      }
    }
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String) {
      throw FormatException('Invalid MealLog row: $key must be a string.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException(
        'Invalid MealLog row: $key must be a string or null.',
      );
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! int) {
      throw FormatException('Invalid MealLog row: $key must be an integer.');
    }
    return value;
  }

  static int? _nullableInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException(
        'Invalid MealLog row: $key must be an integer or null.',
      );
    }
    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> row, String key) {
    final raw = _requiredString(row, key);
    if (!_instantOffsetSuffix.hasMatch(raw)) {
      throw FormatException(
        'Invalid MealLog row: $key must include an explicit UTC offset.',
      );
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Invalid MealLog row: $key is not a timestamp.');
    }
    return parsed.toUtc();
  }

  static Map<String, Object?> _jsonObject(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException(
        'Invalid MealLog row: manual_nutrition_snapshot must be an object.',
      );
    }

    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException(
          'Invalid MealLog row: snapshot keys must be strings.',
        );
      }
      result[key] = entry.value;
    }
    return result;
  }

  static String? _normalizeOptionalText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  static String _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
    return value;
  }
}
