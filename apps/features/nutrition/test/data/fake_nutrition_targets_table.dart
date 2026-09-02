import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// An in-test stand-in for `public.user_nutrition_targets`.
///
/// Concurrency claims are only as good as the double they are proved against.
/// A fake that returns a canned row cannot distinguish "re-read before write"
/// from "atomic write", because the interesting interleaving is the one where
/// the other writer lands *after* this writer's read. So this models the four
/// table behaviours the safety of the write path actually rests on:
///
/// - one row per user, keyed by `user_id`;
/// - a version stamp that changes on every successful write, standing in for
///   the `updated_at` column and its BEFORE UPDATE trigger;
/// - a second INSERT for an existing key raising `23505`, as the primary key
///   would;
/// - an UPDATE whose version predicate fails matching *no* row, so the caller
///   sees that it wrote nothing rather than silently overwriting.
///
/// [onAfterRead] is the hook that makes the race deterministic: it fires in
/// the window between a reader's read and its write, which is exactly where a
/// competing writer has to land for last-writer-wins to bite.
class FakeNutritionTargetsTable implements NutritionTargetsTableGateway {
  FakeNutritionTargetsTable({Map<String, dynamic>? row}) : _row = row {
    // The seeded row gets its version from the same counter as every later
    // write. A hand-written literal here can collide with the first stamped
    // version, and a stale compare-and-swap would then pass — which would
    // make these tests certify the exact bug they exist to catch.
    if (_row != null) _stampVersion();
  }

  Map<String, dynamic>? _row;
  var _versionCounter = 0;

  /// Fires after each versioned read, before the write that follows it.
  /// Cleared before running so a concurrent writer's own read cannot recurse.
  Future<void> Function()? onAfterRead;

  /// Every gateway call, in order. Lets a test assert that a retry actually
  /// happened rather than inferring it from the final value.
  final List<String> operations = [];

  /// Payloads sent through the whole-row upsert, which the core-five write
  /// path still uses. Kept so those tests can assert the exact column set.
  final List<Map<String, dynamic>> upsertPayloads = [];

  /// Row version currently stored, or null when there is no row.
  String? get version => _row?['updated_at'] as String?;

  /// The stored row, or null. Copied, so a test cannot mutate the table.
  Map<String, dynamic>? get row =>
      _row == null ? null : Map<String, dynamic>.from(_row!);

  /// The stored goals column, exactly as written.
  Object? get storedGoals => _row?['additional_nutrient_goals'];

  /// The stored envelope's `goals` object, for concise assertions.
  Map<String, Object?> get storedGoalEntries {
    final envelope = storedGoals;
    if (envelope is! Map) return const {};
    final goals = envelope['goals'];
    return goals is Map ? goals.cast<String, Object?>() : const {};
  }

  /// Writes [goals] the way another client would: unconditionally, and
  /// bumping the version. Used to land a competing writer inside a race.
  void writeConcurrently(Map<String, Object?> goals) {
    _row = {...?_row, 'additional_nutrient_goals': goals};
    _stampVersion();
    operations.add('concurrent-write');
  }

  /// Simulates another client creating the row first.
  void createConcurrently(Map<String, Object?> goals) {
    _row = {'user_id': 'user-1', 'additional_nutrient_goals': goals};
    _stampVersion();
    operations.add('concurrent-create');
  }

  void _stampVersion() {
    _versionCounter++;
    _row!['updated_at'] = 'v$_versionCounter';
  }

  Future<void> _runAfterRead() async {
    final hook = onAfterRead;
    if (hook == null) return;
    onAfterRead = null;
    await hook();
  }

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    operations.add('readRow');
    return _row == null ? null : Map<String, dynamic>.from(_row!);
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    operations.add('upsertRow');
    upsertPayloads.add(Map<String, dynamic>.from(payload));
    _row = {...?_row, ...payload};
    _stampVersion();
  }

  @override
  Future<VersionedNutrientGoals?> readGoalsWithVersion(String userId) async {
    operations.add('read');
    final row = _row;
    if (row == null) {
      await _runAfterRead();
      return null;
    }
    final result = VersionedNutrientGoals(
      version: row['updated_at'] as String,
      goals: row['additional_nutrient_goals'],
    );
    await _runAfterRead();
    return result;
  }

  @override
  Future<bool> compareAndSwapGoals({
    required String userId,
    required String expectedVersion,
    required Map<String, Object?> goals,
  }) async {
    final row = _row;
    if (row == null || row['updated_at'] != expectedVersion) {
      operations.add('cas-conflict');
      return false;
    }
    row['additional_nutrient_goals'] = goals;
    _stampVersion();
    operations.add('cas-ok');
    return true;
  }

  @override
  Future<bool> insertGoalsIfAbsent({
    required String userId,
    required Map<String, Object?> goals,
  }) async {
    if (_row != null) {
      operations.add('insert-conflict');
      return false;
    }
    _row = {'user_id': userId, 'additional_nutrient_goals': goals};
    _stampVersion();
    operations.add('insert-ok');
    return true;
  }
}

/// A gateway whose insert surfaces a raw PostgREST failure that is *not* a
/// unique violation, to prove unrelated database errors are not swallowed by
/// the race-handling path.
class FailingInsertTargetsTable extends FakeNutritionTargetsTable {
  FailingInsertTargetsTable(this.error);

  final PostgrestException error;

  @override
  Future<bool> insertGoalsIfAbsent({
    required String userId,
    required Map<String, Object?> goals,
  }) async {
    operations.add('insert-error');
    throw error;
  }
}
