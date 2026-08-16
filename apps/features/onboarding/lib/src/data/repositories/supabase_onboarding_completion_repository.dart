import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/remote_onboarding_completion_state.dart';
import '../../domain/repositories/onboarding_completion_repository.dart';

/// Supabase-backed durable onboarding completion boundary.
class SupabaseOnboardingCompletionRepository
    implements OnboardingCompletionRepository {
  const SupabaseOnboardingCompletionRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async {
    final userId = _requireCurrentUserId();
    final row = await _client
        .from('users')
        .select('is_onboarded')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return RemoteOnboardingCompletionState.uninitialized;
    }

    return row['is_onboarded'] == true
        ? RemoteOnboardingCompletionState.completed
        : RemoteOnboardingCompletionState.incomplete;
  }

  @override
  Future<void> markCurrentCompleted() async {
    final userId = _requireCurrentUserId();
    final updatedRow = await _client
        .from('users')
        .update({
          'is_onboarded': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select('id')
        .maybeSingle();

    if (updatedRow == null) {
      throw StateError(
        'Cannot mark onboarding completed: backend application-user row is missing.',
      );
    }
  }

  String _requireCurrentUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError(
        'Cannot access onboarding completion state: user is not authenticated.',
      );
    }
    return userId;
  }
}
