import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/exercises/user_exercise_definition.dart';
import '../../domain/exercises/user_exercise_repository.dart';

typedef CurrentUserExerciseUserId = String? Function();

abstract interface class UserExerciseTableGateway {
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required bool includeArchived,
  });

  Future<void> insertRow(Map<String, dynamic> payload);

  Future<bool> updateDefinitionRow({
    required String userId,
    required String exerciseId,
    required Map<String, dynamic> definition,
  });

  Future<bool> renameRow({
    required String userId,
    required String exerciseId,
    required String displayName,
  });

  Future<bool> archiveRow({
    required String userId,
    required String exerciseId,
  });
}

final class SupabaseUserExerciseTableGateway
    implements UserExerciseTableGateway {
  const SupabaseUserExerciseTableGateway(this._client);

  static const _table = 'user_workout_exercises';

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required bool includeArchived,
  }) async {
    var query = _client
        .from(_table)
        .select('id, display_name, status, description, exercise_type, '
            'primary_muscle, secondary_muscles, primary_equipment')
        .eq('user_id', userId);

    if (!includeArchived) {
      query = query.eq('status', 'active');
    }

    final rows = await query.order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> insertRow(Map<String, dynamic> payload) async {
    await _client.from(_table).insert(payload);
  }

  @override
  Future<bool> updateDefinitionRow({
    required String userId,
    required String exerciseId,
    required Map<String, dynamic> definition,
  }) async {
    final rows = await _client
        .from(_table)
        .update(definition)
        .eq('user_id', userId)
        .eq('id', exerciseId)
        .select('id');
    return rows.isNotEmpty;
  }

  @override
  Future<bool> renameRow({
    required String userId,
    required String exerciseId,
    required String displayName,
  }) async {
    final rows = await _client
        .from(_table)
        .update({'display_name': displayName})
        .eq('user_id', userId)
        .eq('id', exerciseId)
        .select('id');
    return rows.isNotEmpty;
  }

  @override
  Future<bool> archiveRow({
    required String userId,
    required String exerciseId,
  }) async {
    final rows = await _client
        .from(_table)
        .update({'status': 'archived'})
        .eq('user_id', userId)
        .eq('id', exerciseId)
        .select('id');
    return rows.isNotEmpty;
  }
}

/// Supabase adapter for user-owned canonical Exercise persistence.
final class SupabaseUserExerciseRepository implements UserExerciseRepository {
  SupabaseUserExerciseRepository({
    required SupabaseClient client,
    UserExerciseTableGateway? gateway,
    CurrentUserExerciseUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseUserExerciseTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final UserExerciseTableGateway _gateway;
  final CurrentUserExerciseUserId _currentUserId;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return const [];

    final rows = await _gateway.listRows(
      userId: userId,
      includeArchived: includeArchived,
    );
    return List<Exercise>.unmodifiable(rows.map(_exerciseFromRow));
  }

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {
    final userId = _requireUserId();
    final exercise = Exercise(
      ref: id,
      displayName: displayName,
      description: definition?.description,
      exerciseType: definition?.exerciseType,
      primaryMuscles: definition?.primaryMuscle == null
          ? const []
          : [definition!.primaryMuscle!],
      secondaryMuscles: definition?.secondaryMuscles ?? const [],
      primaryEquipment: definition?.primaryEquipment,
      status: ExerciseStatus.active,
    );

    await _gateway.insertRow({
      'id': id.value,
      'user_id': userId,
      'display_name': exercise.displayName,
      if (basedOnCatalogExercise != null)
        'based_on_catalog_exercise_id': basedOnCatalogExercise.value,
      if (definition != null) ..._definitionPayload(definition),
    });
  }

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {
    final userId = _requireUserId();
    final updated = await _gateway.updateDefinitionRow(
      userId: userId,
      exerciseId: id.value,
      definition: _definitionPayload(definition),
    );
    if (!updated) {
      throw StateError('User Exercise not found.');
    }
  }

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {
    final userId = _requireUserId();
    final exercise = Exercise(
      ref: id,
      displayName: displayName,
      status: ExerciseStatus.active,
    );

    final updated = await _gateway.renameRow(
      userId: userId,
      exerciseId: id.value,
      displayName: exercise.displayName,
    );
    if (!updated) {
      throw StateError('User Exercise not found.');
    }
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    final userId = _requireUserId();
    final updated = await _gateway.archiveRow(
      userId: userId,
      exerciseId: id.value,
    );
    if (!updated) {
      throw StateError('User Exercise not found.');
    }
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save Exercises.');
    }
    return userId;
  }

  static Map<String, dynamic> _definitionPayload(
    UserExerciseDefinition definition,
  ) =>
      {
        'description': definition.description,
        'exercise_type': definition.exerciseType?.storageValue,
        'primary_muscle': definition.primaryMuscle,
        'secondary_muscles': definition.secondaryMuscles,
        'primary_equipment': definition.primaryEquipment,
      };

  static Exercise _exerciseFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final displayName = row['display_name'];
    final status = row['status'];
    final description = row['description'];
    final exerciseType = row['exercise_type'];
    final primaryMuscle = row['primary_muscle'];
    final secondaryMuscles = row['secondary_muscles'];
    final primaryEquipment = row['primary_equipment'];
    if (id is! String || displayName is! String || status is! String) {
      throw const FormatException('Invalid canonical user Exercise row.');
    }

    if (description != null && description is! String ||
        exerciseType != null && exerciseType is! String ||
        primaryMuscle != null && primaryMuscle is! String ||
        primaryEquipment != null && primaryEquipment is! String ||
        secondaryMuscles is! List) {
      throw const FormatException(
          'Invalid canonical user Exercise definition.');
    }
    final secondary = secondaryMuscles.cast<Object?>();
    if (description is String && description.trim().isEmpty) {
      throw const FormatException(
          'Invalid canonical user Exercise description.');
    }
    if (secondary.any((value) => value is! String)) {
      throw const FormatException('Invalid canonical user Exercise muscles.');
    }
    final definition = UserExerciseDefinition(
      description: description as String?,
      exerciseType: exerciseType == null
          ? null
          : ExerciseType.fromStorageValue(exerciseType as String),
      primaryMuscle: primaryMuscle as String?,
      secondaryMuscles: secondary.cast<String>(),
      primaryEquipment: primaryEquipment as String?,
    );

    final exerciseStatus = switch (status) {
      'active' => ExerciseStatus.active,
      'archived' => ExerciseStatus.archived,
      _ => throw const FormatException(
          'Invalid canonical user Exercise status.',
        ),
    };

    return Exercise(
      ref: ExerciseRef.userCreated(id),
      displayName: displayName,
      description: definition.description,
      exerciseType: definition.exerciseType,
      primaryMuscles: definition.primaryMuscle == null
          ? const []
          : [definition.primaryMuscle!],
      secondaryMuscles: definition.secondaryMuscles,
      primaryEquipment: definition.primaryEquipment,
      status: exerciseStatus,
    );
  }
}
