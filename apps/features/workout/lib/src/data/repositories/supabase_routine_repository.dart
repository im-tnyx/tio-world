import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_repository.dart';

abstract interface class RoutineTableGateway {
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required String programId,
  });

  Future<void> insertRow(Map<String, dynamic> values);

  Future<void> renameRow({
    required String userId,
    required String routineId,
    required String name,
  });
}

final class SupabaseRoutineTableGateway implements RoutineTableGateway {
  SupabaseRoutineTableGateway(this._client);

  static const _table = 'user_workout_routines';

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required String programId,
  }) async {
    final rows = await _client
        .from(_table)
        .select('id, program_id, name')
        .eq('user_id', userId)
        .eq('program_id', programId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> insertRow(Map<String, dynamic> values) async {
    await _client.from(_table).insert(values);
  }

  @override
  Future<void> renameRow({
    required String userId,
    required String routineId,
    required String name,
  }) async {
    await _client
        .from(_table)
        .update({'name': name})
        .eq('user_id', userId)
        .eq('id', routineId);
  }
}

final class SupabaseRoutineRepository implements RoutineRepository {
  SupabaseRoutineRepository({
    required RoutineTableGateway gateway,
    required String? Function() currentUserId,
  }) : _gateway = gateway,
       _currentUserId = currentUserId;

  factory SupabaseRoutineRepository.fromClient(SupabaseClient client) =>
      SupabaseRoutineRepository(
        gateway: SupabaseRoutineTableGateway(client),
        currentUserId: () => client.auth.currentUser?.id,
      );

  final RoutineTableGateway _gateway;
  final String? Function() _currentUserId;

  @override
  Future<List<Routine>> list(ProgramId programId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const [];
    }

    final rows = await _gateway.listRows(
      userId: userId,
      programId: programId.value,
    );
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<void> create(Routine routine) async {
    final userId = _requireUserId();
    await _gateway.insertRow({
      'id': routine.id.value,
      'user_id': userId,
      'program_id': routine.programId.value,
      'name': routine.name,
    });
  }

  @override
  Future<void> rename({
    required RoutineId id,
    required String name,
  }) async {
    final userId = _requireUserId();
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'must contain at least one non-whitespace character',
      );
    }
    await _gateway.renameRow(
      userId: userId,
      routineId: id.value,
      name: name,
    );
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null) {
      throw StateError('Please sign in to save Routines.');
    }
    return userId;
  }

  static Routine _mapRow(Map<String, dynamic> row) {
    final id = row['id'];
    final programId = row['program_id'];
    final name = row['name'];
    if (id is! String || programId is! String || name is! String) {
      throw const FormatException('Malformed Routine row.');
    }
    return Routine(
      id: RoutineId(id),
      programId: ProgramId(programId),
      name: name,
    );
  }
}
