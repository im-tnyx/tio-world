import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/program_repository.dart';

typedef CurrentProgramUserId = String? Function();

abstract interface class ProgramTableGateway {
  Future<List<Map<String, dynamic>>> listRows(String userId);

  Future<void> insertRow(Map<String, dynamic> payload);

  Future<void> renameRow({
    required String userId,
    required String programId,
    required String name,
  });
}

final class SupabaseProgramTableGateway implements ProgramTableGateway {
  const SupabaseProgramTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> listRows(String userId) async {
    final rows = await _client
        .from('user_workout_programs')
        .select('id, name')
        .eq('user_id', userId)
        .order('created_at');
    return rows;
  }

  @override
  Future<void> insertRow(Map<String, dynamic> payload) async {
    await _client.from('user_workout_programs').insert(payload);
  }

  @override
  Future<void> renameRow({
    required String userId,
    required String programId,
    required String name,
  }) async {
    await _client
        .from('user_workout_programs')
        .update({'name': name})
        .eq('user_id', userId)
        .eq('id', programId);
  }
}

/// Supabase adapter for user-owned Program persistence only.
final class SupabaseProgramRepository implements ProgramRepository {
  SupabaseProgramRepository({
    required SupabaseClient client,
    ProgramTableGateway? gateway,
    CurrentProgramUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseProgramTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final ProgramTableGateway _gateway;
  final CurrentProgramUserId _currentUserId;

  @override
  Future<List<Program>> list() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return const [];

    final rows = await _gateway.listRows(userId);
    return List.unmodifiable(rows.map(_programFromRow));
  }

  @override
  Future<void> create(Program program) async {
    final userId = _requireUserId();
    await _gateway.insertRow({
      'id': program.id.value,
      'user_id': userId,
      'name': program.name,
    });
  }

  @override
  Future<void> rename({
    required ProgramId id,
    required String name,
  }) async {
    final userId = _requireUserId();
    final validated = Program(id: id, name: name);
    await _gateway.renameRow(
      userId: userId,
      programId: id.value,
      name: validated.name,
    );
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save Programs.');
    }
    return userId;
  }

  Program _programFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final name = row['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Invalid canonical Program row.');
    }
    return Program(id: ProgramId(id), name: name);
  }
}
