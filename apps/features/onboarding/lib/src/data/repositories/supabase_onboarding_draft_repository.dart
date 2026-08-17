import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/onboarding_draft_snapshot.dart';
import '../../domain/repositories/onboarding_draft_repository.dart';
import '../mappers/onboarding_draft_snapshot_dto_mapper.dart';

/// Supabase-backed implementation of [OnboardingDraftRepository].
///
/// Manages draft snapshots in `public.onboarding_drafts` protected by Row Level Security (RLS).
class SupabaseOnboardingDraftRepository implements OnboardingDraftRepository {
  SupabaseOnboardingDraftRepository({
    required SupabaseClient client,
    OnboardingDraftSnapshotDtoMapper? mapper,
  })  : _client = client,
        _mapper = mapper ?? const OnboardingDraftSnapshotDtoMapper();

  final SupabaseClient _client;
  final OnboardingDraftSnapshotDtoMapper _mapper;

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final row = await _client
        .from('onboarding_drafts')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;

    final payload = row['payload'] as Map<String, dynamic>?;
    if (payload == null) return null;

    return _mapper.fromJson(payload);
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Cannot persist onboarding draft: user is not authenticated.');
    }

    final payload = _mapper.toJson(snapshot);

    final record = {
      'user_id': userId,
      'schema_version': snapshot.schemaVersion,
      'payload': payload,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from('onboarding_drafts').upsert(record);
  }

  @override
  Future<void> clearDraft() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      await _client.from('onboarding_drafts').delete().eq('user_id', userId);
    } catch (_) {
      // Best-effort clear; completion remains authoritative.
    }
  }
}
