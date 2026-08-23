import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';

/// Account-owned subset needed by Profile display surfaces.
final class ProfileAccountSnapshot {
  const ProfileAccountSnapshot({
    required this.plan,
    this.username,
    this.avatarUrl,
    this.mobile,
    this.isMobileVerified = false,
  });

  final String plan;
  final String? username;
  final String? avatarUrl;
  final String? mobile;
  final bool isMobileVerified;
}

abstract interface class ProfileAccountSnapshotReader {
  Future<ProfileAccountSnapshot?> read();
}

/// Reads only Account-owned Profile display metadata from `public.users`.
///
/// Profile and Body mirror columns are intentionally not selected. The legacy
/// `profile_image` column remains an avatar-only fallback until the dedicated
/// avatar cleanup gate retires it.
final class SupabaseProfileAccountSnapshotReader
    implements ProfileAccountSnapshotReader {
  const SupabaseProfileAccountSnapshotReader({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  @override
  Future<ProfileAccountSnapshot?> read() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    final row = await _client
        .from('users')
        .select(
          'username, avatar_url, profile_image, plan, mobile, '
          'mobile_verified_at',
        )
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;

    final rawPlan = row['plan'];
    if (rawPlan is! String || rawPlan.trim().isEmpty) {
      throw const FormatException(
        'Invalid canonical account plan: expected non-empty string.',
      );
    }

    String? optionalString(String key) {
      final raw = row[key];
      if (raw == null) return null;
      if (raw is! String) {
        throw FormatException('Invalid account $key: expected string or null.');
      }
      final normalized = raw.trim();
      return normalized.isEmpty ? null : normalized;
    }

    final avatarUrl = optionalString('avatar_url');
    final legacyAvatar = optionalString('profile_image');

    return ProfileAccountSnapshot(
      username: optionalString('username'),
      avatarUrl: avatarUrl ?? legacyAvatar,
      plan: rawPlan.trim(),
      mobile: optionalString('mobile'),
      isMobileVerified: row['mobile_verified_at'] != null,
    );
  }
}

/// Composes the legacy Profile display DTO from canonical semantic owners.
///
/// `ProfileSetupData.goals` is intentionally left empty because that legacy
/// field is not a canonical owner. Body Goal semantics remain in [BodyState]
/// and Workout Goal semantics remain in the Workout owner.
final class CanonicalProfileDataReader {
  const CanonicalProfileDataReader({
    required UserProfileRepository profileRepository,
    required BodyRepository bodyRepository,
    required ProfileAccountSnapshotReader accountReader,
  })  : _profileRepository = profileRepository,
        _bodyRepository = bodyRepository,
        _accountReader = accountReader;

  final UserProfileRepository _profileRepository;
  final BodyRepository _bodyRepository;
  final ProfileAccountSnapshotReader _accountReader;

  Future<ProfileSetupData?> read() async {
    final profile = await _profileRepository.read();
    if (profile == null) return null;

    final body = await _bodyRepository.getBodyState();
    final latestWeight = body.latestWeight;
    if (latestWeight == null) {
      throw StateError(
        'Canonical Current Weight is not initialized for the current account.',
      );
    }

    final account = await _accountReader.read();
    if (account == null) return null;

    return ProfileSetupData(
      name: profile.name,
      username: account.username,
      avatarUrl: account.avatarUrl,
      plan: account.plan,
      gender: profile.gender,
      goals: const <ProfileGoal>{},
      dateOfBirth: profile.dateOfBirth,
      heightCm: profile.heightCm,
      currentWeightKg: latestWeight.weightKg,
      targetWeightKg: body.activeGoal?.targetWeightKg,
      unitPreferences: profile.unitPreferences,
      activityLevel: profile.activityLevel,
      healthConditions: profile.healthConditions,
      otherHealthCondition: profile.otherHealthCondition,
      mobile: account.mobile,
      isMobileVerified: account.isMobileVerified,
    );
  }
}

/// Realtime invalidation bridge for the canonical Profile display composition.
///
/// Table events are only refresh signals. Semantic parsing remains delegated to
/// [CanonicalProfileDataReader] and its canonical owner repositories.
final class CanonicalSupabaseProfileDataStream {
  const CanonicalSupabaseProfileDataStream({
    required SupabaseClient client,
    required CanonicalProfileDataReader reader,
  })  : _client = client,
        _reader = reader;

  final SupabaseClient _client;
  final CanonicalProfileDataReader _reader;

  Stream<ProfileSetupData?> watch() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return Stream<ProfileSetupData?>.value(null);
    }

    late final StreamController<ProfileSetupData?> controller;
    final channels = <RealtimeChannel>[];
    var cancelled = false;
    var refreshInFlight = false;
    var refreshQueued = false;

    Future<void> refresh() async {
      if (cancelled) return;
      if (refreshInFlight) {
        refreshQueued = true;
        return;
      }
      refreshInFlight = true;
      try {
        do {
          refreshQueued = false;
          try {
            final value = await _reader.read();
            if (!cancelled) controller.add(value);
          } catch (error, stackTrace) {
            if (!cancelled) controller.addError(error, stackTrace);
          }
        } while (refreshQueued && !cancelled);
      } finally {
        refreshInFlight = false;
      }
    }

    void subscribe({required String table, required String userColumn}) {
      final channel = _client.channel('profile-canonical:$table:$userId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: userColumn,
            value: userId,
          ),
          callback: (_) => unawaited(refresh()),
        )
        ..subscribe();
      channels.add(channel);
    }

    controller = StreamController<ProfileSetupData?>(
      onListen: () {
        subscribe(table: 'users', userColumn: 'id');
        subscribe(table: 'user_profiles', userColumn: 'user_id');
        subscribe(table: 'body_weight_logs', userColumn: 'user_id');
        subscribe(table: 'user_body_goals', userColumn: 'user_id');
        unawaited(refresh());
      },
      onCancel: () async {
        cancelled = true;
        for (final channel in channels) {
          await channel.unsubscribe();
        }
        if (!controller.isClosed) {
          await controller.close();
        }
      },
    );

    return controller.stream;
  }
}
