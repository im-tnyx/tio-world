import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/account_deletion_repository.dart';

typedef CurrentAccountDeletionUserId = String? Function();

abstract interface class AccountDeletionStorageGateway {
  Future<void> deleteUserOwnedObjects({required String userId});
}

abstract interface class AccountDeletionRpcGateway {
  Future<void> deleteCurrentUser();
}

final class SupabaseAccountDeletionStorageGateway
    implements AccountDeletionStorageGateway {
  const SupabaseAccountDeletionStorageGateway(
    this._client, {
    List<String> bucketIds = const ['avatars'],
  }) : _bucketIds = bucketIds;

  static const int _batchSize = 1000;

  final SupabaseClient _client;
  final List<String> _bucketIds;

  @override
  Future<void> deleteUserOwnedObjects({required String userId}) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw StateError('User is not authenticated');
    }

    for (final bucketId in _bucketIds) {
      final bucket = _client.storage.from(bucketId);
      while (true) {
        final objects = await bucket.list(
          path: normalizedUserId,
          searchOptions: const SearchOptions(limit: _batchSize),
        );
        if (objects.isEmpty) break;

        final paths = objects
            .map((object) => object.name.trim())
            .where((name) => name.isNotEmpty)
            .map((name) => '$normalizedUserId/$name')
            .toList(growable: false);
        if (paths.isEmpty) break;

        await bucket.remove(paths);

        if (objects.length < _batchSize) break;
      }
    }
  }
}

final class SupabaseAccountDeletionRpcGateway
    implements AccountDeletionRpcGateway {
  const SupabaseAccountDeletionRpcGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> deleteCurrentUser() async {
    await _client.rpc<void>('delete_user_account');
  }
}

class SupabaseAccountDeletionRepository implements AccountDeletionRepository {
  SupabaseAccountDeletionRepository({
    required SupabaseClient client,
    AccountDeletionStorageGateway? storageGateway,
    AccountDeletionRpcGateway? rpcGateway,
    CurrentAccountDeletionUserId? currentUserId,
  })  : _storageGateway =
            storageGateway ?? SupabaseAccountDeletionStorageGateway(client),
        _rpcGateway = rpcGateway ?? SupabaseAccountDeletionRpcGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final AccountDeletionStorageGateway _storageGateway;
  final AccountDeletionRpcGateway _rpcGateway;
  final CurrentAccountDeletionUserId _currentUserId;

  @override
  Future<void> deleteCurrentAccount() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in before deleting your account.');
    }

    await _storageGateway.deleteUserOwnedObjects(userId: userId);
    await _rpcGateway.deleteCurrentUser();
  }
}
