import 'package:tio_shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/nutrition_targets_data.dart';
import '../../domain/models/additional_nutrient_goal.dart';
import '../../domain/repositories/nutrition_targets_repository.dart';
import '../additional_nutrient_goals_v1_codec.dart';

typedef CurrentNutritionTargetsUserId = String? Function();

/// The Additional Nutrient Goals column together with the row version that
/// produced it.
///
/// The version is the row's `updated_at`, which an existing BEFORE UPDATE
/// trigger refreshes on every write. Carrying it alongside the payload is what
/// lets a caller write only if nothing has changed since it read.
final class VersionedNutrientGoals {
  const VersionedNutrientGoals({required this.version, required this.goals});

  /// Opaque row version. Compared for equality only; never parsed.
  final String version;

  /// Raw `additional_nutrient_goals` value, exactly as stored.
  final Object? goals;
}

abstract interface class NutritionTargetsTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);

  /// Reads the goals column with the row version needed to write it back
  /// safely. Null when the row does not exist yet.
  Future<VersionedNutrientGoals?> readGoalsWithVersion(String userId);

  /// Writes [goals] only if the row is still at [expectedVersion].
  ///
  /// Returns false when it is not — another writer landed first — so the
  /// caller can re-read and rebuild its delta rather than clobbering them.
  Future<bool> compareAndSwapGoals({
    required String userId,
    required String expectedVersion,
    required Map<String, Object?> goals,
  });

  /// Creates the row with only [goals] set. Returns false when another client
  /// created it first, which is a race to be retried rather than an error.
  Future<bool> insertGoalsIfAbsent({
    required String userId,
    required Map<String, Object?> goals,
  });
}

final class SupabaseNutritionTargetsTableGateway
    implements NutritionTargetsTableGateway {
  const SupabaseNutritionTargetsTableGateway(this._client);

  /// PostgreSQL `unique_violation`. The primary key is `user_id`, so this is
  /// exactly the "another client created the row first" case.
  static const _uniqueViolation = '23505';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_nutrition_targets')
        .select(
          'calories_kcal, protein_grams, carbohydrate_grams, fat_grams, '
          'fiber_grams, customization_state, customized_fields, '
          'recommendation_metadata, additional_nutrient_goals',
        )
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_nutrition_targets')
        .upsert(payload, onConflict: 'user_id');
  }

  @override
  Future<VersionedNutrientGoals?> readGoalsWithVersion(String userId) async {
    final row = await _client
        .from('user_nutrition_targets')
        .select('additional_nutrient_goals, updated_at')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;

    final version = row['updated_at'];
    if (version is! String || version.isEmpty) {
      // The column is NOT NULL, so this means the shape changed underneath us.
      // Guessing a version would defeat the point of comparing one.
      throw const FormatException(
        'Invalid canonical updated_at: expected a timestamp.',
      );
    }
    return VersionedNutrientGoals(
      version: version,
      goals: row['additional_nutrient_goals'],
    );
  }

  @override
  Future<bool> compareAndSwapGoals({
    required String userId,
    required String expectedVersion,
    required Map<String, Object?> goals,
  }) async {
    // The version predicate is what makes this a compare-and-swap: an UPDATE
    // that matches no row wrote nothing, which is the signal to retry.
    final updated = await _client
        .from('user_nutrition_targets')
        .update({'additional_nutrient_goals': goals})
        .eq('user_id', userId)
        .eq('updated_at', expectedVersion)
        .select('user_id');
    return updated.length == 1;
  }

  @override
  Future<bool> insertGoalsIfAbsent({
    required String userId,
    required Map<String, Object?> goals,
  }) async {
    try {
      // Deliberately an INSERT rather than an upsert: an upsert would happily
      // overwrite a row another client just created, which is the same
      // last-writer-wins loss this whole path exists to prevent. Every other
      // column is nullable or defaulted, so this minimal row is valid.
      await _client.from('user_nutrition_targets').insert({
        'user_id': userId,
        'additional_nutrient_goals': goals,
      });
      return true;
    } on PostgrestException catch (error) {
      if (error.code == _uniqueViolation) return false;
      rethrow;
    }
  }
}

/// Supabase adapter for the canonical Nutrition Targets owner.
///
/// It never writes `user_nutrition_profiles.macro_targets` or the legacy
/// `user_targets` table and never mutates authentication state.
final class SupabaseNutritionTargetsRepository
    implements NutritionTargetsRepository {
  SupabaseNutritionTargetsRepository({
    required SupabaseClient client,
    NutritionTargetsTableGateway? gateway,
    CurrentNutritionTargetsUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseNutritionTargetsTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final NutritionTargetsTableGateway _gateway;
  final CurrentNutritionTargetsUserId _currentUserId;

  @override
  Future<NutritionTargetsData?> read() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return null;

    final row = await _gateway.readRow(userId);
    if (row == null) return null;

    final targets = NutritionTargetsData(
      caloriesKcal: _parseOptionalPositiveInt(
        row['calories_kcal'],
        'calories_kcal',
      ),
      proteinGrams: _parseOptionalNonnegativeDouble(
          row['protein_grams'], 'protein_grams'),
      carbohydrateGrams: _parseOptionalNonnegativeDouble(
        row['carbohydrate_grams'],
        'carbohydrate_grams',
      ),
      fatGrams: _parseOptionalNonnegativeDouble(row['fat_grams'], 'fat_grams'),
      fiberGrams:
          _parseOptionalNonnegativeDouble(row['fiber_grams'], 'fiber_grams'),
      customizationState: parseNutritionTargetCustomizationState(
        row['customization_state'],
      ),
      customizedFields: _parseRequiredStringSet(
        row['customized_fields'],
        'customized_fields',
      ),
      recommendationMetadata: _parseRequiredObjectMap(
        row['recommendation_metadata'],
        'recommendation_metadata',
      ),
      additionalNutrientGoals: AdditionalNutrientGoalsV1Codec.decode(
        row['additional_nutrient_goals'],
      ).goals,
    );

    try {
      targets.validate();
      return targets;
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid canonical user_nutrition_targets row: ${error.message}',
      );
    }
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    final userId = _requireUserId();
    targets.validate();

    final customizedFields = targets.customizedFields.toList(growable: false)
      ..sort();

    await _gateway.upsertRow({
      'user_id': userId,
      'calories_kcal': targets.caloriesKcal,
      'protein_grams': targets.proteinGrams,
      'carbohydrate_grams': targets.carbohydrateGrams,
      'fat_grams': targets.fatGrams,
      'fiber_grams': targets.fiberGrams,
      'customization_state': targets.customizationState.storageValue,
      'customized_fields': customizedFields,
      'recommendation_metadata':
          Map<String, Object?>.from(targets.recommendationMetadata),
      // Deliberately omitted: a core-five/old-client write must preserve the
      // existing additional_nutrient_goals value in PostgREST.
    });
  }

  /// Compare-and-swap attempts before giving up.
  ///
  /// Bounded on purpose. Each retry only loses to a *different* writer landing
  /// in between, so more than a handful means genuine sustained contention on
  /// one user's own row — and an unbounded loop there would hang the save
  /// rather than report it. Failing is recoverable; overwriting is not.
  static const maxWriteAttempts = 4;

  @override
  Future<void> updateAdditionalNutrientGoal(
    NutrientId nutrientId,
    AdditionalNutrientGoal? goal,
  ) async {
    final userId = _requireUserId();
    // Fail before any I/O: a delta whose key and goal disagree is a caller
    // bug, and reading the row first would only make the error later.
    AdditionalNutrientGoalsV1Codec.requireGoalIdentity(nutrientId, goal);

    // A read-modify-write of one JSONB column is not made safe by re-reading
    // first. Two clients can read the same envelope, each add a different
    // nutrient, and each write the whole column back — whichever lands last
    // erases the other. So every attempt re-reads with the row's version and
    // writes only if that version still holds.
    for (var attempt = 0; attempt < maxWriteAttempts; attempt++) {
      final current = await _gateway.readGoalsWithVersion(userId);
      final decoded = AdditionalNutrientGoalsV1Codec.decode(current?.goals);
      final payload = AdditionalNutrientGoalsV1Codec.encodeGoalDelta(
        decoded,
        nutrientId,
        goal,
      );

      if (current == null) {
        // No row yet. Two blind upserts here would race exactly as above, so
        // the insert is allowed to lose: losing means someone created the row,
        // and the next pass merges onto what they wrote.
        if (await _gateway.insertGoalsIfAbsent(
          userId: userId,
          goals: payload,
        )) {
          return;
        }
        continue;
      }

      if (await _gateway.compareAndSwapGoals(
        userId: userId,
        expectedVersion: current.version,
        goals: payload,
      )) {
        return;
      }
      // Lost the swap: the envelope this delta was computed against is stale.
      // Loop to re-read and recompute against what actually landed.
    }

    throw StateError(
      'Your Nutrition targets changed while saving. Please try again.',
    );
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save your Nutrition targets.');
    }
    return userId;
  }
}

int? _parseOptionalPositiveInt(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! num) {
    throw FormatException('Invalid canonical $key: expected integer or null.');
  }

  final numeric = raw.toDouble();
  if (!numeric.isFinite ||
      numeric != numeric.truncateToDouble() ||
      numeric <= 0) {
    throw FormatException('Invalid canonical $key: expected positive integer.');
  }
  return numeric.toInt();
}

double? _parseOptionalNonnegativeDouble(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! num) {
    throw FormatException('Invalid canonical $key: expected number or null.');
  }

  final numeric = raw.toDouble();
  if (!numeric.isFinite || numeric < 0) {
    throw FormatException(
      'Invalid canonical $key: expected finite nonnegative number.',
    );
  }
  return numeric;
}

Set<String> _parseRequiredStringSet(Object? raw, String key) {
  if (raw is! List) {
    throw FormatException('Invalid canonical $key: expected string array.');
  }

  final values = <String>{};
  for (final value in raw) {
    if (value is! String) {
      throw FormatException('Invalid canonical $key: expected string array.');
    }
    values.add(value);
  }
  return Set.unmodifiable(values);
}

Map<String, Object?> _parseRequiredObjectMap(Object? raw, String key) {
  if (raw is! Map) {
    throw FormatException('Invalid canonical $key: expected JSON object.');
  }

  final values = <String, Object?>{};
  for (final entry in raw.entries) {
    final mapKey = entry.key;
    if (mapKey is! String) {
      throw FormatException('Invalid canonical $key: expected string keys.');
    }
    values[mapKey] = entry.value;
  }
  return Map.unmodifiable(values);
}
