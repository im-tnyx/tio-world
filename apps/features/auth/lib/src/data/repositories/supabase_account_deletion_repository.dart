import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/account_deletion_repository.dart';

class SupabaseAccountDeletionRepository implements AccountDeletionRepository {
  const SupabaseAccountDeletionRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> deleteCurrentAccount() async {
    final user = _client.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      throw StateError('Please sign in before deleting your account.');
    }

    await _client.rpc<void>('delete_user_account');
  }
}
