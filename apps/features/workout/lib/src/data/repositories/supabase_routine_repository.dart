import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_composition_repository.dart';
import '../../domain/repositories/routine_repository.dart';
import 'supabase_routine_composition_repository.dart';

abstract interface class RoutineTableGateway {
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required String programId,
  });

  Future<void> insertRow(Map<String, dynamic> values);
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
        .select('id, program_id, name, composition_revision')
        .eq('user_id', userId)
        .eq('program_id', programId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> insertRow(Map<String, dynamic> values) async {
    await _client.from(_table).insert(values);
  }
}

/// Metadata listing is retained for existing consumers. New-client Rename
/// uses the versioned aggregate RPC, never Data API UPDATE(name).
final class SupabaseRoutineRepository
    implements RoutineRepository, RoutineVersionedRenameRepository {
  SupabaseRoutineRepository({
    required RoutineTableGateway gateway,
    required String? Function() currentUserId,
    RoutineAggregateUpdateRepository? aggregateUpdates,
  }) : _gateway = gateway,
       _currentUserId = currentUserId,
       _aggregateUpdates = aggregateUpdates;

  factory SupabaseRoutineRepository.fromClient(SupabaseClient client) =>
      SupabaseRoutineRepository(
        gateway: SupabaseRoutineTableGateway(client),
        currentUserId: () => client.auth.currentUser?.id,
        aggregateUpdates: SupabaseRoutineCompositionRepository.fromClient(client),
      );

  final RoutineTableGateway _gateway;
  final String? Function() _currentUserId;
  final RoutineAggregateUpdateRepository? _aggregateUpdates;

  @override
  Future<List<Routine>> list(ProgramId programId) async =>
      [for (final snapshot in await listVersioned(programId)) snapshot.routine];

  @override
  Future<List<RoutineMetadataRevision>> listVersioned(
      ProgramId programId) async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return const [];
    final rows = await _gateway.listRows(
      userId: userId,
      programId: programId.value,
    );
    _checkUser(userId);
    return List.unmodifiable(rows.map((row) {
      final routine = _mapRow(row);
      final revision = row['composition_revision'];
      if (routine.programId != programId || revision is! int || revision < 0) {
        throw const FormatException('Malformed Routine versioned row.');
      }
      return RoutineMetadataRevision(routine: routine, revision: revision);
    }));
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
    _checkUser(userId);
  }

  /// Historical unversioned API cannot prove the original Program/revision.
  /// Fail closed rather than issuing the legacy direct UPDATE(name) call.
  @override
  Future<void> rename({
    required RoutineId id,
    required String name,
  }) async {
    _requireUserId();
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'must contain at least one non-whitespace character',
      );
    }
    throw StateError('A versioned Routine snapshot is required to rename.');
  }

  @override
  Future<int> renameVersioned(RoutineAggregateUpdate command) async {
    final userId = _requireUserId();
    if (command.name == null || command.entries != null) {
      throw ArgumentError('Protected metadata Rename must be name-only.');
    }
    final updates = _aggregateUpdates;
    if (updates == null) {
      throw StateError('Protected Routine Rename is unavailable.');
    }
    final revision = await updates.updateAggregate(command);
    _checkUser(userId);
    return revision;
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save Routines.');
    }
    return userId;
  }

  void _checkUser(String userId) {
    if (_currentUserId()?.trim() != userId) {
      throw StateError('Please sign in to save Routines.');
    }
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
