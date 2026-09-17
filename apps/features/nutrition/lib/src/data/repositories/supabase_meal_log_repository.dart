import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/detailed_meal_log_create_repository.dart';
import '../../domain/repositories/manual_meal_log_update_repository.dart';
import '../../domain/repositories/meal_categories_repository.dart';
import '../../domain/repositories/meal_log_range_read_repository.dart';
import '../../domain/repositories/meal_log_repository.dart';

typedef CurrentMealLogUserId = String? Function();

/// Injectable parent-table seam for focused mapping/error tests.
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

/// Optional gateway capability used only by calendar-range consumers.
///
/// Keeping this separate means existing injected gateways that exercise the
/// established create/read/update contract do not need a synthetic range API.
abstract interface class MealLogRangeTableGateway {
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRange({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
  });
}

/// Atomic detailed-create RPC seam.
abstract interface class DetailedMealLogCreateGateway {
  Future<String> createDetailed(Map<String, dynamic> params);
}

/// Batch detailed-item read seam used to avoid per-parent N+1 requests.
abstract interface class MealLogItemReadGateway {
  Future<List<Map<String, dynamic>>> listItemRowsByEntryIds(
    List<String> entryIds,
  );
}

final class SupabaseMealLogTableGateway implements
    MealLogTableGateway,
    MealLogRangeTableGateway,
    DetailedMealLogCreateGateway,
    MealLogItemReadGateway {
  const SupabaseMealLogTableGateway(this._client);

  static const _columns =
      'id, user_id, mode, meal_category_id, meal_name, note, consumed_at, '
      'consumed_local_date, consumed_timezone_id, consumed_utc_offset_minutes, '
      'capture_source, manual_nutrition_snapshot, created_at, updated_at, '
      'client_mutation_id, revision';
  static const _itemColumns =
      'id, meal_log_entry_id, position, display_name, brand_name, quantity, '
      'serving_unit, nutrition_snapshot';

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
  Future<String> createDetailed(Map<String, dynamic> params) async {
    final result = await _client.rpc<String>(
      'create_detailed_meal_log',
      params: params,
    );
    if (result.trim().isEmpty) {
      throw const FormatException(
        'Detailed MealLog create RPC must return a non-empty parent id.',
      );
    }
    return result;
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

  @override
  Future<List<Map<String, dynamic>>> listRowsByLocalDateRange({
    required String userId,
    required String startLocalDate,
    required String endLocalDate,
  }) async {
    final rows = await _client
        .from('meal_log_entries')
        .select(_columns)
        .eq('user_id', userId)
        .gte('consumed_local_date', startLocalDate)
        .lte('consumed_local_date', endLocalDate)
        .order('consumed_local_date')
        .order('consumed_at', ascending: false)
        .order('id');
    return [
      for (final row in rows) Map<String, dynamic>.from(row),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> listItemRowsByEntryIds(
    List<String> entryIds,
  ) async {
    if (entryIds.isEmpty) return const <Map<String, dynamic>>[];
    final rows = await _client
        .from('meal_log_item_snapshots')
        .select(_itemColumns)
        .inFilter('meal_log_entry_id', entryIds)
        .order('meal_log_entry_id')
        .order('position');
    return [
      for (final row in rows) Map<String, dynamic>.from(row),
    ];
  }
}

/// Supabase adapter for canonical manual and detailed MealLog persistence.
///
/// Authenticated identity is derived from the current Supabase session and RLS
/// remains the database read/ownership authority. Manual creates keep their
/// existing direct-parent idempotency flow. Detailed creates use one atomic RPC
/// because a valid detailed aggregate requires parent + ordered children to
/// commit together while direct authenticated child writes stay disabled.
final class SupabaseMealLogRepository implements
    MealLogRepository,
    DetailedMealLogCreateRepository,
    ManualMealLogUpdateRepository,
    MealLogRangeReadRepository {
  SupabaseMealLogRepository({
    required SupabaseClient client,
    required MealCategoriesRepository mealCategoriesRepository,
    MealLogTableGateway? gateway,
    DetailedMealLogCreateGateway? detailedCreateGateway,
    MealLogItemReadGateway? itemReadGateway,
    CurrentMealLogUserId? currentUserId,
  })  : _mealCategoriesRepository = mealCategoriesRepository,
        _gateway = gateway ?? SupabaseMealLogTableGateway(client),
        _detailedCreateGateway =
            detailedCreateGateway ?? SupabaseMealLogTableGateway(client),
        _itemReadGateway =
            itemReadGateway ?? SupabaseMealLogTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final MealCategoriesRepository _mealCategoriesRepository;
  final MealLogTableGateway _gateway;
  final DetailedMealLogCreateGateway _detailedCreateGateway;
  final MealLogItemReadGateway _itemReadGateway;
  final CurrentMealLogUserId _currentUserId;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    final userId = _requireUserId();

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
  Future<MealLogEntry> createDetailed(DetailedMealLogCreate input) async {
    final userId = _requireUserId();

    final existing = await _readDetailedMutationForCreate(
      userId: userId,
      input: input,
    );
    if (existing != null) return existing;

    await _requireActiveMealCategory(input.mealCategoryId);
    final params = <String, dynamic>{
      'p_client_mutation_id': input.clientMutationId,
      'p_meal_category_id': input.mealCategoryId,
      'p_meal_name': input.mealName,
      'p_note': input.note,
      'p_consumed_at': input.consumedAt.toUtc().toIso8601String(),
      'p_consumed_local_date': input.consumedLocalDate.toIso8601String(),
      'p_consumed_timezone_id': input.consumedTimezoneId,
      'p_consumed_utc_offset_minutes': input.consumedUtcOffsetMinutes,
      'p_capture_source': input.captureSource?.storageValue,
      'p_items': [
        for (final item in input.items)
          <String, dynamic>{
            'display_name': item.displayName,
            'brand_name': item.brandName,
            'quantity': item.quantity,
            'serving_unit': item.servingUnit,
            'nutrition_snapshot': item.nutritionSnapshot.toJson(),
          },
      ],
    };

    String id;
    try {
      id = await _detailedCreateGateway.createDetailed(params);
    } on Object catch (error) {
      if (_isDetailedMutationConflict(error)) {
        throw MealLogCreateMutationConflict(
          clientMutationId: input.clientMutationId,
        );
      }
      if (!_isAmbiguousGatewayFailure(error)) rethrow;
      return _reconcileDetailedAfterCreateFailure(
        userId: userId,
        input: input,
        cause: error,
      );
    }

    try {
      final row = await _gateway.readRow(userId: userId, id: id);
      if (row == null) {
        throw MealLogCreateOutcomeUnknown(
          clientMutationId: input.clientMutationId,
        );
      }
      return await _decodeDetailedCreateResult(
        row,
        expectedUserId: userId,
        input: input,
      );
    } on MealLogCreateMutationConflict {
      rethrow;
    } on Object catch (error) {
      if (error is MealLogCreateOutcomeUnknown) rethrow;
      if (!_isAmbiguousGatewayFailure(error)) rethrow;
      throw MealLogCreateOutcomeUnknown(
        clientMutationId: input.clientMutationId,
        cause: error,
      );
    }
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

    if (before.revision == input.expectedRevision + 1 &&
        _matchesUpdateInput(before, input)) {
      return before;
    }

    if (before.revision != input.expectedRevision) {
      throw MealLogUpdateConflict(
        id: input.id,
        expectedRevision: input.expectedRevision,
        actualRevision: before.revision,
      );
    }

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
    final entries = await _decodeRows([row], expectedUserId: userId);
    return entries.single;
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
    final entries = await _decodeRows(rows, expectedUserId: userId);
    entries.sort(_compareDiaryOrder);
    return List<MealLogEntry>.unmodifiable(entries);
  }

  @override
  Future<List<MealLogEntry>> listByLocalDateRange({
    required MealLogLocalDate startDate,
    required MealLogLocalDate endDate,
  }) async {
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();
    if (start.compareTo(end) > 0) {
      throw ArgumentError.value(
        '$start..$end',
        'localDateRange',
        'startDate must not be after endDate',
      );
    }
    final gateway = _gateway;
    if (gateway is! MealLogRangeTableGateway) {
      throw StateError('MealLog range reads are unavailable for this gateway.');
    }
    final rangeGateway = gateway as MealLogRangeTableGateway;

    final userId = _requireUserId();
    final rows = await rangeGateway.listRowsByLocalDateRange(
      userId: userId,
      startLocalDate: start,
      endLocalDate: end,
    );
    final entries = await _decodeRows(rows, expectedUserId: userId);
    entries.sort(_compareDiaryRangeOrder);
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

  Future<MealLogEntry?> _readDetailedMutationForCreate({
    required String userId,
    required DetailedMealLogCreate input,
  }) async {
    Map<String, dynamic>? row;
    try {
      row = await _gateway.readRowByClientMutationId(
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
    if (row == null) return null;
    return _decodeDetailedCreateResult(
      row,
      expectedUserId: userId,
      input: input,
    );
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

  Future<MealLogEntry> _reconcileDetailedAfterCreateFailure({
    required String userId,
    required DetailedMealLogCreate input,
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
    return _decodeDetailedCreateResult(
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

  static bool _isDetailedMutationConflict(Object error) {
    return error is PostgrestException &&
        error.code == 'P0001' &&
        error.message == 'meal_log_create_mutation_conflict';
  }

  static bool _isAmbiguousGatewayFailure(Object error) {
    if (error is! PostgrestException) return true;
    return _isAmbiguousPostgrestFailure(error);
  }

  static bool _isAmbiguousPostgrestFailure(PostgrestException error) {
    final code = error.code;
    if (code == null || code.isEmpty) return true;

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

  static int _compareDiaryRangeOrder(MealLogEntry left, MealLogEntry right) {
    final byDate = left.consumedLocalDate
        .toIso8601String()
        .compareTo(right.consumedLocalDate.toIso8601String());
    if (byDate != 0) return byDate;
    return _compareDiaryOrder(left, right);
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
    if (_modeFromRow(row) != MealLogMode.manual) {
      throw MealLogCreateMutationConflict(
        clientMutationId: input.clientMutationId,
      );
    }

    final entry = _decodeManualRow(row, expectedUserId: expectedUserId);
    if (entry.revision != 1 || !_matchesCreateInput(entry, input)) {
      throw MealLogCreateMutationConflict(
        clientMutationId: input.clientMutationId,
      );
    }
    return entry;
  }

  Future<MealLogEntry> _decodeDetailedCreateResult(
    Map<String, dynamic> row, {
    required String expectedUserId,
    required DetailedMealLogCreate input,
  }) async {
    _requireKeys(row);
    final mutationId = _nullableString(row, 'client_mutation_id');
    if (mutationId != input.clientMutationId ||
        _modeFromRow(row) != MealLogMode.detailed) {
      throw MealLogCreateMutationConflict(
        clientMutationId: input.clientMutationId,
      );
    }
    final entries = await _decodeRows([row], expectedUserId: expectedUserId);
    final entry = entries.single;
    if (entry.revision != 1 || !_matchesDetailedCreateInput(entry, input)) {
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

  Future<List<MealLogEntry>> _decodeRows(
    List<Map<String, dynamic>> rows, {
    required String expectedUserId,
  }) async {
    if (rows.isEmpty) return <MealLogEntry>[];

    final detailedIds = <String>[];
    for (final row in rows) {
      _requireKeys(row);
      _requireExpectedUser(row, expectedUserId);
      if (_modeFromRow(row) == MealLogMode.detailed) {
        detailedIds.add(_requiredString(row, 'id'));
      }
    }

    final itemsByEntry = <String, List<_PositionedItem>>{};
    if (detailedIds.isNotEmpty) {
      final itemRows = await _itemReadGateway.listItemRowsByEntryIds(detailedIds);
      final detailedIdSet = detailedIds.toSet();
      for (final itemRow in itemRows) {
        final parentId = _requiredString(itemRow, 'meal_log_entry_id');
        if (!detailedIdSet.contains(parentId)) {
          throw const FormatException(
            'Invalid MealLog item row: parent was not requested.',
          );
        }
        final position = _requiredInt(itemRow, 'position');
        if (position < 0) {
          throw const FormatException(
            'Invalid MealLog item row: position must be nonnegative.',
          );
        }
        final item = _decodeItemRow(itemRow, expectedParentId: parentId);
        final list = itemsByEntry.putIfAbsent(
          parentId,
          () => <_PositionedItem>[],
        );
        if (list.any((candidate) => candidate.position == position)) {
          throw FormatException(
            'Invalid MealLog item rows: duplicate position $position for $parentId.',
          );
        }
        list.add(_PositionedItem(position: position, item: item));
      }
      for (final list in itemsByEntry.values) {
        list.sort((left, right) => left.position.compareTo(right.position));
      }
    }

    return [
      for (final row in rows)
        _decodeRow(
          row,
          expectedUserId: expectedUserId,
          detailedItems: [
            for (final item in
                itemsByEntry[_requiredString(row, 'id')] ??
                    const <_PositionedItem>[])
              item.item,
          ],
        ),
    ];
  }

  static MealLogEntry _decodeRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
    required List<MealLogItemSnapshot> detailedItems,
  }) {
    _requireKeys(row);
    final userId = _requireExpectedUser(row, expectedUserId);
    final mode = _modeFromRow(row);
    final captureSource = _captureSourceFromRow(row);
    final timezoneId = _normalizeOptionalText(
      _nullableString(row, 'consumed_timezone_id'),
    );
    final utcOffsetMinutes = _nullableInt(row, 'consumed_utc_offset_minutes');
    if (timezoneId == null && utcOffsetMinutes == null) {
      throw const FormatException(
        'Invalid MealLog row: consumed timezone context is missing.',
      );
    }

    final id = _requiredString(row, 'id');
    final mealCategoryId = _requiredString(row, 'meal_category_id');
    final mealName = _nullableString(row, 'meal_name');
    final note = _nullableString(row, 'note');
    final consumedAt = _requiredDateTime(row, 'consumed_at');
    final consumedLocalDate = MealLogLocalDate.fromIso8601String(
      _requiredString(row, 'consumed_local_date'),
    );
    final revision = _requiredInt(row, 'revision');
    final createdAt = _requiredDateTime(row, 'created_at');
    final updatedAt = _requiredDateTime(row, 'updated_at');

    if (mode == MealLogMode.manual) {
      if (detailedItems.isNotEmpty) {
        throw const FormatException(
          'Invalid manual MealLog row: detailed items must be empty.',
        );
      }
      final snapshot = NutritionSnapshot.fromJson(
        _jsonObject(
          row['manual_nutrition_snapshot'],
          fieldName: 'manual_nutrition_snapshot',
        ),
      );
      return MealLogEntry.manual(
        id: id,
        userId: userId,
        mealCategoryId: mealCategoryId,
        mealName: mealName,
        note: note,
        consumedAt: consumedAt,
        consumedLocalDate: consumedLocalDate,
        consumedTimezoneId: timezoneId,
        consumedUtcOffsetMinutes: utcOffsetMinutes,
        captureSource: captureSource,
        manualNutritionSnapshot: snapshot,
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    if (row['manual_nutrition_snapshot'] != null) {
      throw const FormatException(
        'Invalid detailed MealLog row: manual_nutrition_snapshot must be null.',
      );
    }
    if (detailedItems.isEmpty) {
      throw const FormatException(
        'Invalid detailed MealLog row: at least one item snapshot is required.',
      );
    }
    return MealLogEntry.detailed(
      id: id,
      userId: userId,
      mealCategoryId: mealCategoryId,
      mealName: mealName,
      note: note,
      consumedAt: consumedAt,
      consumedLocalDate: consumedLocalDate,
      consumedTimezoneId: timezoneId,
      consumedUtcOffsetMinutes: utcOffsetMinutes,
      captureSource: captureSource,
      detailedItems: detailedItems,
      revision: revision,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static MealLogEntry _decodeManualRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    return _decodeRow(
      row,
      expectedUserId: expectedUserId,
      detailedItems: const <MealLogItemSnapshot>[],
    );
  }

  static MealLogItemSnapshot _decodeItemRow(
    Map<String, dynamic> row, {
    required String expectedParentId,
  }) {
    const requiredKeys = <String>{
      'id',
      'meal_log_entry_id',
      'position',
      'display_name',
      'brand_name',
      'quantity',
      'serving_unit',
      'nutrition_snapshot',
    };
    for (final key in requiredKeys) {
      if (!row.containsKey(key)) {
        throw FormatException('Invalid MealLog item row: missing $key.');
      }
    }
    final parentId = _requiredString(row, 'meal_log_entry_id');
    if (parentId != expectedParentId) {
      throw const FormatException(
        'Invalid MealLog item row: parent identity mismatch.',
      );
    }
    final quantity = row['quantity'];
    if (quantity is! num || !quantity.isFinite || quantity <= 0) {
      throw const FormatException(
        'Invalid MealLog item row: quantity must be positive and finite.',
      );
    }
    return MealLogItemSnapshot(
      id: _requiredString(row, 'id'),
      mealLogEntryId: parentId,
      displayName: _requiredString(row, 'display_name'),
      brandName: _nullableString(row, 'brand_name'),
      quantity: quantity,
      servingUnit: _requiredString(row, 'serving_unit'),
      nutritionSnapshot: NutritionSnapshot.fromJson(
        _jsonObject(
          row['nutrition_snapshot'],
          fieldName: 'nutrition_snapshot',
        ),
      ),
    );
  }

  static bool _matchesCreateInput(
    MealLogEntry entry,
    ManualMealLogCreate input,
  ) {
    return entry.mode == MealLogMode.manual &&
        entry.mealCategoryId == input.mealCategoryId &&
        entry.mealName == input.mealName &&
        entry.note == input.note &&
        entry.consumedAt == input.consumedAt.toUtc() &&
        entry.consumedLocalDate == input.consumedLocalDate &&
        entry.consumedTimezoneId == input.consumedTimezoneId &&
        entry.consumedUtcOffsetMinutes == input.consumedUtcOffsetMinutes &&
        entry.captureSource == input.captureSource &&
        entry.manualNutritionSnapshot == input.manualNutritionSnapshot;
  }

  static bool _matchesDetailedCreateInput(
    MealLogEntry entry,
    DetailedMealLogCreate input,
  ) {
    if (entry.mode != MealLogMode.detailed ||
        entry.mealCategoryId != input.mealCategoryId ||
        entry.mealName != input.mealName ||
        entry.note != input.note ||
        entry.consumedAt != input.consumedAt.toUtc() ||
        entry.consumedLocalDate != input.consumedLocalDate ||
        entry.consumedTimezoneId != input.consumedTimezoneId ||
        entry.consumedUtcOffsetMinutes != input.consumedUtcOffsetMinutes ||
        entry.captureSource != input.captureSource ||
        entry.detailedItems.length != input.items.length) {
      return false;
    }
    for (var index = 0; index < input.items.length; index++) {
      final durable = entry.detailedItems[index];
      final requested = input.items[index];
      if (durable.displayName != requested.displayName ||
          durable.brandName != requested.brandName ||
          durable.quantity != requested.quantity ||
          durable.servingUnit != requested.servingUnit ||
          durable.nutritionSnapshot != requested.nutritionSnapshot) {
        return false;
      }
    }
    return true;
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

  static String _requireExpectedUser(
    Map<String, dynamic> row,
    String expectedUserId,
  ) {
    final userId = _requiredString(row, 'user_id');
    if (userId != expectedUserId) {
      throw const FormatException(
        'Invalid MealLog row: user_id does not match the authenticated owner.',
      );
    }
    return userId;
  }

  static MealLogMode _modeFromRow(Map<String, dynamic> row) {
    final rawMode = _requiredString(row, 'mode');
    final mode = MealLogMode.fromStorageValue(rawMode);
    if (mode == null) {
      throw FormatException('Unsupported MealLog mode: $rawMode.');
    }
    return mode;
  }

  static MealLogCaptureSource? _captureSourceFromRow(
    Map<String, dynamic> row,
  ) {
    final rawCaptureSource = _nullableString(row, 'capture_source');
    if (rawCaptureSource == null) return null;
    final captureSource = MealLogCaptureSource.fromStorageValue(rawCaptureSource);
    if (captureSource == null) {
      throw FormatException(
        'Unsupported MealLog capture source: $rawCaptureSource.',
      );
    }
    return captureSource;
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

  static Map<String, Object?> _jsonObject(
    Object? value, {
    required String fieldName,
  }) {
    if (value is! Map<Object?, Object?>) {
      throw FormatException(
        'Invalid MealLog row: $fieldName must be an object.',
      );
    }

    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException(
          'Invalid MealLog row: $fieldName keys must be strings.',
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

final class _PositionedItem {
  const _PositionedItem({required this.position, required this.item});

  final int position;
  final MealLogItemSnapshot item;
}
