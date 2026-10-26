import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/body_setup.dart';
import 'body_state_row_mapper.dart';


/// Narrow, injectable transport for auth-cycle races in A1. Production still
/// queries the canonical body_weight_logs table, never a second data owner.
/// No custom HTTP backend, privileged key, or Storage access is introduced.
abstract interface class BodyWeightLogTransport {
  Future<List<Map<String, dynamic>>> list({
    required String userId,
    required BodyWeightHistoryQuery query,
  });

  Future<bool> update({
    required String userId,
    required BodyWeightLogEdit edit,
  });

  Future<bool> delete({
    required String userId,
    required String id,
  });
}

final class _SupabaseBodyWeightLogTransport implements BodyWeightLogTransport {
  const _SupabaseBodyWeightLogTransport(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> list({
    required String userId,
    required BodyWeightHistoryQuery query,
  }) async {
    final from = query.fromInclusive.toUtc().toIso8601String();
    final to = query.toExclusive.toUtc().toIso8601String();
    var rowsQuery = _client
        .from('body_weight_logs')
        .select('id, weight_kg, measured_at, source, metadata')
        .eq('user_id', userId)
        .gte('measured_at', from)
        .lt('measured_at', to);

    final cursor = query.before;
    if (cursor != null) {
      // UUID validation disallows filter injection; UTC ISO has no commas.
      final instant = cursor.measuredAt.toUtc().toIso8601String();
      rowsQuery = rowsQuery.or(
        'measured_at.lt.$instant,'
        'and(measured_at.eq.$instant,id.lt.${cursor.id})',
      );
    }

    return await rowsQuery
        .order('measured_at', ascending: false)
        .order('id', ascending: false)
        .limit(query.limit + 1);
  }

  @override
  Future<bool> update({
    required String userId,
    required BodyWeightLogEdit edit,
  }) async {
    final updated = await _client
        .from('body_weight_logs')
        .update({
          'weight_kg': edit.weightKg,
          'measured_at': edit.measuredAt.toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('id', edit.id)
        .select('id')
        .maybeSingle();
    return updated != null;
  }

  @override
  Future<bool> delete({
    required String userId,
    required String id,
  }) async {
    final deleted = await _client
        .from('body_weight_logs')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select('id')
        .maybeSingle();
    return deleted != null;
  }
}

/// Supabase implementation of the canonical Body owner.
///
/// `body_weight_logs` owns current-weight history and `user_body_goals` owns
/// active/historical Body Goal plans. Legacy Profile/Nutrition mirrors are not
/// touched here.
class SupabaseBodySetupRepository implements BodyRepository {
  const SupabaseBodySetupRepository({
    required SupabaseClient client,
    BodyStateRowMapper stateMapper = const BodyStateRowMapper(),
    String? weightLoginCycleId,
    String? Function()? currentWeightLoginCycleId,
    BodyWeightLogTransport? weightLogTransport,
  })  : _client = client,
        _stateMapper = stateMapper,
        _weightLoginCycleId = weightLoginCycleId,
        _currentWeightLoginCycleId = currentWeightLoginCycleId,
        _weightLogTransport = weightLogTransport;

  final SupabaseClient _client;
  final BodyStateRowMapper _stateMapper;

  // These guards protect A1 History/Edit/Delete only. Existing Settings,
  // onboarding and Body Goal contracts are unchanged by this source slice.
  // App composition pins an authoritative login cycle to each repository and
  // supplies a *live* getter; a UID alone cannot detect A -> B -> A re-login.
  final String? _weightLoginCycleId;
  final String? Function()? _currentWeightLoginCycleId;
  final BodyWeightLogTransport? _weightLogTransport;

  BodyWeightLogTransport get _historyTransport =>
      _weightLogTransport ?? _SupabaseBodyWeightLogTransport(_client);

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to access Body data.');
    }
    return userId;
  }

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    final userId = _requireUserId();
    _validate(data);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final currentWeight = data.currentWeightKg;
    if (currentWeight != null) {
      await _saveOnboardingWeightSnapshot(
        userId: userId,
        weightKg: currentWeight,
        nowIso: nowIso,
      );
    }

    await _reconcileActiveGoal(
      userId: userId,
      data: data,
      nowIso: nowIso,
    );
  }

  @override
  Future<BodyState> getBodyState() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return const BodyState();
    }

    final latestWeightRow = await _client
        .from('body_weight_logs')
        .select('id, weight_kg, measured_at, source, metadata')
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final activeGoalRow = await _client
        .from('user_body_goals')
        .select(
          'goal_type, starting_weight_kg, target_weight_kg, '
          'weekly_weight_change_kg, intent_rank, started_at',
        )
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    return _stateMapper.map(
      latestWeightRow: latestWeightRow,
      activeGoalRow: activeGoalRow,
    );
  }

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    final userId = _requireUserId();
    _validateWeightRecord(record);

    // The A3 sheet supplies one stable UUID across attempts; legacy Settings
    // calls without a submissionId retain server-generated row identity.
    final cycle =
        record.submissionId == null ? null : _requireWeightSession(userId);
    final payload = <String, dynamic>{
      'user_id': userId,
      'weight_kg': record.weightKg,
      'measured_at': record.measuredAt.toUtc().toIso8601String(),
      'source': record.source.trim(),
      if (record.submissionId != null) 'id': record.submissionId,
      if (record.note?.trim().isNotEmpty == true)
        'metadata': <String, dynamic>{'note': record.note!.trim()},
    };
    try {
      await _client.from('body_weight_logs').insert(payload);
    } catch (error) {
      final id = record.submissionId;
      if (id == null) rethrow;

      // A narrowly allowlisted Postgres/PostgREST rejection proves this
      // particular insert did not commit. Exclude 23505: an earlier UNKNOWN
      // attempt with this UUID may already have inserted the same row.
      // Network, server, read-back and all unclassified errors stay UNKNOWN.
      if (error is PostgrestException &&
          const <String>{
            '42501', // permission / RLS rejection
            '23514', // check constraint
            '23502', // not-null constraint
            '23503', // foreign-key constraint
            '22003', // numeric value out of range
            '22P02', // invalid input representation
            'PGRST102', // invalid request body, rejected before SQL
          }.contains(error.code)) {
        _requireWeightSession(userId, expectedCycle: cycle);
        throw const BodyWeightSubmissionRejected();
      }

      // An ambiguous timeout may have already committed the insert. Verify
      // the exact owner row and payload before accepting a retry as saved.
      // Reusing the UUID makes duplicate committed measurements impossible.
      final existing = await _client
          .from('body_weight_logs')
          .select('weight_kg, measured_at, source, metadata')
          .eq('user_id', userId)
          .eq('id', id)
          .maybeSingle();
      _requireWeightSession(userId, expectedCycle: cycle);
      if (existing == null) rethrow;
      final mapped = _stateMapper.mapHistoryWeight({...existing, 'id': id});
      if (mapped.weightKg != record.weightKg ||
          !mapped.measuredAt.isAtSameMomentAs(record.measuredAt) ||
          mapped.source != record.source.trim() ||
          mapped.note != _normalizedNote(record.note)) {
        throw StateError('Weight submission ID belongs to another record.');
      }
      return;
    }
    if (cycle != null) _requireWeightSession(userId, expectedCycle: cycle);
  }

  String? _normalizedNote(String? value) {
    final note = value?.trim();
    return note == null || note.isEmpty ? null : note;
  }


  @override
  Future<BodyWeightHistoryPage> getWeightHistory(
    BodyWeightHistoryQuery query,
  ) async {
    query.validate();
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return const BodyWeightHistoryPage(entries: <BodyWeightEntry>[]);
    }

    final cycle = _requireWeightSession(userId);
    final rows = await _historyTransport.list(
      userId: userId,
      query: query,
    );
    _requireWeightSession(userId, expectedCycle: cycle);

    final hasMore = rows.length > query.limit;
    final entries = List<BodyWeightEntry>.unmodifiable(
      rows.take(query.limit).map(_stateMapper.mapHistoryWeight),
    );
    final last = entries.isEmpty ? null : entries.last;
    return BodyWeightHistoryPage(
      entries: entries,
      nextCursor: hasMore && last != null
          ? BodyWeightHistoryCursor(measuredAt: last.measuredAt, id: last.id!)
          : null,
    );
  }

  @override
  Future<bool> updateWeightLog(BodyWeightLogEdit edit) async {
    final userId = _requireUserId();
    edit.validate();
    final cycle = _requireWeightSession(userId);
    final updated = await _historyTransport.update(userId: userId, edit: edit);
    _requireWeightSession(userId, expectedCycle: cycle);
    return updated;
  }

  @override
  Future<bool> deleteWeightLog(String id) async {
    final userId = _requireUserId();
    BodyWeightLogIds.requireValid(id);
    final cycle = _requireWeightSession(userId);
    final deleted = await _historyTransport.delete(userId: userId, id: id);
    _requireWeightSession(userId, expectedCycle: cycle);
    return deleted;
  }

  String _requireWeightSession(String userId, {String? expectedCycle}) {
    final pinned = _weightLoginCycleId?.trim();
    final live = _currentWeightLoginCycleId?.call()?.trim();
    if (pinned == null || pinned.isEmpty ||
        live == null || live.isEmpty || pinned != live ||
        (expectedCycle != null && expectedCycle != live) ||
        _client.auth.currentUser?.id != userId) {
      throw StateError('Body data session changed or is unavailable.');
    }
    return live;
  }

  /// Delegates the entire same-goal/changed-goal lifecycle to the atomic
  /// `set_active_body_goal` Postgres RPC (TNYX-136) instead of a client-side
  /// supersede-then-insert request pair. The two-request sequence could
  /// leave an account with zero active goals if the process died between
  /// the two HTTP calls; the RPC runs as one database transaction, so a
  /// failure always leaves the previously committed state unchanged.
  ///
  /// This Dart-side check is narrow defense-in-depth for fast/offline
  /// feedback only -- the RPC is itself an authenticated API boundary and
  /// independently re-validates every canonical invariant server-side.
  @override
  Future<void> setActiveBodyGoal(BodyGoalUpdate update) async {
    _requireUserId();
    _validateGoalUpdate(update);

    await _client.rpc<void>(
      'set_active_body_goal',
      params: {
        'p_goal_type': update.goalType.storageValue,
        'p_target_weight_kg': update.targetWeightKg,
        'p_weekly_weight_change_kg': update.weeklyWeightChangeKg,
      },
    );
  }

  void _validateGoalUpdate(BodyGoalUpdate update) {
    if (update.goalType == BodyGoalType.recomposition) {
      throw ArgumentError.value(
        update.goalType,
        'goalType',
        'Explicit Body Goal editing offers Lose/Gain/Maintain only.',
      );
    }
    final target = update.targetWeightKg;
    if (target != null && target <= 0) {
      throw ArgumentError.value(
        target,
        'targetWeightKg',
        'Target weight must be greater than zero.',
      );
    }
    final pace = update.weeklyWeightChangeKg;
    if (pace != null && pace < 0) {
      throw ArgumentError.value(
        pace,
        'weeklyWeightChangeKg',
        'Goal pace must be nonnegative.',
      );
    }
    final isDirectional = update.goalType == BodyGoalType.loseWeight ||
        update.goalType == BodyGoalType.gainWeight;
    if (!isDirectional && (target != null || pace != null)) {
      throw ArgumentError(
        'Maintain cannot persist Target Weight or Goal Pace.',
      );
    }
    if (isDirectional && (target == null || pace == null)) {
      throw ArgumentError(
        'Lose/Gain requires both Target Weight and Goal Pace.',
      );
    }
  }

  void _validate(BodySetupData data) {
    final currentWeight = data.currentWeightKg;
    if (currentWeight != null && currentWeight <= 0) {
      throw ArgumentError.value(
        currentWeight,
        'currentWeightKg',
        'Current weight must be greater than zero.',
      );
    }
    final goal = data.activeGoal;
    if (goal != null) {
      _validateGoal(goal);
    }
  }

  Future<void> _saveOnboardingWeightSnapshot({
    required String userId,
    required double weightKg,
    required String nowIso,
  }) async {
    final existing = await _client
        .from('body_weight_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('source', BodyWeightSources.onboardingSetup)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final payload = <String, dynamic>{
      'user_id': userId,
      'weight_kg': weightKg,
      'measured_at': nowIso,
      'source': BodyWeightSources.onboardingSetup,
      'metadata': const <String, dynamic>{'context': 'product_onboarding'},
    };

    final existingId = existing?['id'] as String?;
    if (existingId == null || existingId.isEmpty) {
      await _client.from('body_weight_logs').insert(payload);
      return;
    }

    await _client.from('body_weight_logs').update(payload).eq('id', existingId);
  }

  Future<void> _reconcileActiveGoal({
    required String userId,
    required BodySetupData data,
    required String nowIso,
  }) async {
    final requested = data.activeGoal;
    final activeRow = await _client
        .from('user_body_goals')
        .select('id, goal_type, starting_weight_kg')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    if (requested == null) {
      final activeId = activeRow?['id'] as String?;
      if (activeId != null && activeId.isNotEmpty) {
        await _client.from('user_body_goals').update({
          'status': 'superseded',
          'ended_at': nowIso,
        }).eq('id', activeId);
      }
      return;
    }

    final goalStorage = requested.goalType.storageValue;
    final activeId = activeRow?['id'] as String?;
    final activeType = activeRow?['goal_type'] as String?;

    if (activeId != null && activeId.isNotEmpty && activeType == goalStorage) {
      await _client.from('user_body_goals').update({
        if (activeRow?['starting_weight_kg'] == null &&
            data.currentWeightKg != null)
          'starting_weight_kg': data.currentWeightKg,
        'target_weight_kg': requested.targetWeightKg,
        'weekly_weight_change_kg': requested.weeklyWeightChangeKg,
        'intent_rank': requested.intentRank,
        'updated_at': nowIso,
      }).eq('id', activeId);
      return;
    }

    if (activeId != null && activeId.isNotEmpty) {
      await _client.from('user_body_goals').update({
        'status': 'superseded',
        'ended_at': nowIso,
      }).eq('id', activeId);
    }

    await _client.from('user_body_goals').insert({
      'user_id': userId,
      'goal_type': goalStorage,
      'starting_weight_kg': data.currentWeightKg,
      'target_weight_kg': requested.targetWeightKg,
      'weekly_weight_change_kg': requested.weeklyWeightChangeKg,
      'intent_rank': requested.intentRank,
      'status': 'active',
      'started_at': nowIso,
    });
  }

  void _validateGoal(BodyGoalSetupData goal) {
    final rank = goal.intentRank;
    if (rank != null && rank != 1 && rank != 2) {
      throw ArgumentError.value(rank, 'intentRank', 'Expected 1, 2, or null.');
    }
    final target = goal.targetWeightKg;
    if (target != null && target <= 0) {
      throw ArgumentError.value(
        target,
        'targetWeightKg',
        'Target weight must be greater than zero.',
      );
    }
    final pace = goal.weeklyWeightChangeKg;
    if (pace != null && pace < 0) {
      throw ArgumentError.value(
        pace,
        'weeklyWeightChangeKg',
        'Goal pace must be nonnegative.',
      );
    }
    final isDirectional = goal.goalType == BodyGoalType.loseWeight ||
        goal.goalType == BodyGoalType.gainWeight;
    if (!isDirectional && (target != null || pace != null)) {
      throw ArgumentError(
        'Maintain/Recomposition cannot persist Target Weight or Goal Pace.',
      );
    }
  }

  void _validateWeightRecord(BodyWeightRecord record) {
    record.validateNoteAndSubmission();
    if (!record.weightKg.isFinite || record.weightKg <= 0) {
      throw ArgumentError.value(
        record.weightKg,
        'weightKg',
        'Current weight must be greater than zero.',
      );
    }
    final source = record.source.trim();
    if (source.isEmpty) {
      throw ArgumentError.value(
        record.source,
        'source',
        'Weight provenance source is required.',
      );
    }
    if (source == BodyWeightSources.onboardingSetup) {
      throw ArgumentError.value(
        record.source,
        'source',
        'onboarding_setup is reserved for saveBodySetup reconciliation.',
      );
    }
  }
}
