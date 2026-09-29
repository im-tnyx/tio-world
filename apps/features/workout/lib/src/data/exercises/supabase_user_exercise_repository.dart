import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/exercises/user_exercise_repository.dart';

typedef CurrentUserExerciseUserId = String? Function();

abstract interface class UserExerciseTableGateway {
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required bool includeArchived,
  });

  Future<void> insertRow(Map<String, dynamic> payload);

  Future<void> renameRow({
    required String userId,
    required String exerciseId,
    required String displayName,
  });

  Future<void> archiveRow({
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
        .select('id, display_name, status')
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
  Future<void> renameRow({
    required String userId,
    required String exerciseId,
    required String displayName,
  }) async {
    await _client
        .from(_table)
        .update({'display_name': displayName})
        .eq('user_id', userId)
        .eq('id', exerciseId);
  }

  @override
  Future<void> archiveRow({
    required String userId,
    required String exerciseId,
  }) async {
    await _client
        .from(_table)
        .update({'status': 'archived'})
        .eq('user_id', userId)
        .eq('id', exerciseId);
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
  }) async {
    final userId = _requireUserId();
    final exercise = Exercise(
      ref: id,
      displayName: displayName,
      status: ExerciseStatus.active,
    );

    await _gateway.insertRow({
      'id': id.value,
      'user_id': userId,
      'display_name': exercise.displayName,
      if (basedOnCatalogExercise != null)
        'based_on_catalog_exercise_id': basedOnCatalogExercise.value,
    });
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

    await _gateway.renameRow(
      userId: userId,
      exerciseId: id.value,
      displayName: exercise.displayName,
    );
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    final userId = _requireUserId();
    await _gateway.archiveRow(
      userId: userId,
      exerciseId: id.value,
    );
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save Exercises.');
    }
    return userId;
  }

  static Exercise _exerciseFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final displayName = row['display_name'];
    final status = row['status'];
    if (id is! String || displayName is! String || status is! String) {
      throw const FormatException('Invalid canonical user Exercise row.');
    }

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
      status: exerciseStatus,
    );
  }
}
