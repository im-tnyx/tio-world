import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/profile_activity_level.dart';
import '../../domain/models/profile_gender.dart';
import '../../domain/models/profile_goal.dart';
import '../../domain/models/profile_health_condition.dart';
import '../../domain/models/profile_setup_data.dart';
import '../../domain/repositories/profile_setup_repository.dart';

/// Supabase-backed implementation of [ProfileSetupRepository].
///
/// Directly manages RLS-protected user profile records in Postgres.
class SupabaseProfileSetupRepository implements ProfileSetupRepository {
  const SupabaseProfileSetupRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) async {
    var userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      try {
        final res = await _client.auth.signInAnonymously();
        userId = res.user?.id ?? _client.auth.currentUser?.id;
      } catch (_) {}
    }
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in or create an account to save your profile.');
    }

    final currentUser = _client.auth.currentUser;
    final email = currentUser?.email;
    final phone = currentUser?.phone;
    final effectiveMobile = (data.mobile != null && data.mobile!.trim().isNotEmpty)
        ? data.mobile!.trim()
        : (phone != null && phone.isNotEmpty ? phone : null);
    final dobIso = data.dateOfBirth.toIso8601String().split('T').first;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'id': userId,
      'name': data.name,
      'username': data.username,
      if (email != null && email.isNotEmpty) 'email': email,
      if (effectiveMobile != null) 'mobile': effectiveMobile,
      if (data.isMobileVerified) 'mobile_verified_at': nowIso,
      'avatar_url': data.avatarUrl,
      'profile_image': data.avatarUrl,
      'plan': data.plan,
      'gender': data.gender.name,
      'primary_goal': data.goals.isNotEmpty ? data.goals.first.name : null,
      'goals': data.goals.map((g) => g.name).toList(),
      'date_of_birth': dobIso,
      'dob': dobIso,
      'height_cm': data.heightCm,
      'current_weight_kg': data.currentWeightKg,
      'target_weight_kg': data.targetWeightKg,
      'activity_level': data.activityLevel.name,
      'health_conditions': data.healthConditions.map((c) => c.name).toList(),
      'other_health_condition': data.otherHealthCondition,
      'timezone': DateTime.now().timeZoneName,
      'is_active': true,
      'last_active_at': nowIso,
      'updated_at': nowIso,
    };

    try {
      await _client.from('users').upsert(payload);
    } on PostgrestException catch (e) {
      if (e.code == '42703' || e.code == 'PGRST204') {
        final corePayload = <String, dynamic>{
          'id': userId,
          'name': data.name,
          'username': data.username,
          'gender': data.gender.name,
          'goals': data.goals.map((g) => g.name).toList(),
          'date_of_birth': dobIso,
          'height_cm': data.heightCm,
          'current_weight_kg': data.currentWeightKg,
          'target_weight_kg': data.targetWeightKg,
          'activity_level': data.activityLevel.name,
          'health_conditions': data.healthConditions.map((c) => c.name).toList(),
          'other_health_condition': data.otherHealthCondition,
          'updated_at': nowIso,
        };
        await _client.from('users').upsert(corePayload);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<ProfileSetupData?> getProfileSetup() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final row = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return _mapRowToProfile(row);
  }

  @override
  Stream<ProfileSetupData?> watchProfileSetup() {
    late final StreamController<ProfileSetupData?> controller;
    StreamSubscription<AuthState>? authSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? realtimeSubscription;
    RealtimeChannel? postgresChannel;

    void subscribeToUserStream(String userId) {
      realtimeSubscription?.cancel();
      postgresChannel?.unsubscribe();

      // 1. Initial snapshot fetch
      getProfileSetup().then((data) {
        if (!controller.isClosed) controller.add(data);
      }).catchError((_) {});

      // 2. Supabase SDK stream
      realtimeSubscription = _client
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .listen(
        (rows) {
          if (controller.isClosed) return;
          if (rows.isEmpty) {
            controller.add(null);
          } else {
            controller.add(_mapRowToProfile(rows.first));
          }
        },
        onError: (err) {
          // Fallback to getProfileSetup on stream error
          getProfileSetup().then((data) {
            if (!controller.isClosed) controller.add(data);
          }).catchError((_) {});
        },
      );

      // 3. Direct Postgres changes channel as secondary realtime listener
      postgresChannel = _client.channel('public:users:$userId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty && !controller.isClosed) {
              controller.add(_mapRowToProfile(newRecord));
            } else {
              getProfileSetup().then((data) {
                if (!controller.isClosed) controller.add(data);
              }).catchError((_) {});
            }
          },
        )
        ..subscribe();
    }

    controller = StreamController<ProfileSetupData?>.broadcast(
      onListen: () {
        final currentUserId = _client.auth.currentUser?.id;
        if (currentUserId != null && currentUserId.isNotEmpty) {
          subscribeToUserStream(currentUserId);
        } else {
          controller.add(null);
        }

        authSubscription = _client.auth.onAuthStateChange.listen((data) {
          final newUserId = data.session?.user.id ?? _client.auth.currentUser?.id;
          if (newUserId != null && newUserId.isNotEmpty) {
            subscribeToUserStream(newUserId);
          } else {
            realtimeSubscription?.cancel();
            postgresChannel?.unsubscribe();
            if (!controller.isClosed) controller.add(null);
          }
        });
      },
      onCancel: () {
        authSubscription?.cancel();
        realtimeSubscription?.cancel();
        postgresChannel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }

  ProfileSetupData _mapRowToProfile(Map<String, dynamic> row) {
    final genderStr = row['gender'] as String?;
    final gender = ProfileGender.values.firstWhere(
      (g) => g.name == genderStr,
      orElse: () => ProfileGender.other,
    );

    final goalsList = (row['goals'] as List<dynamic>?) ?? [];
    final goals = goalsList
        .map((g) => ProfileGoal.values.where((pg) => pg.name == g).firstOrNull)
        .whereType<ProfileGoal>()
        .toSet();

    final dobStr = row['date_of_birth'] as String?;
    final dob = dobStr != null
        ? DateTime.tryParse(dobStr) ?? DateTime(2000, 1, 1)
        : DateTime(2000, 1, 1);

    final height = (row['height_cm'] as num?)?.toDouble() ?? 170.0;
    final currentWeight =
        (row['current_weight_kg'] as num?)?.toDouble() ?? 70.0;
    final targetWeight = (row['target_weight_kg'] as num?)?.toDouble();

    final activityStr = row['activity_level'] as String?;
    final activity = ProfileActivityLevel.values.firstWhere(
      (a) => a.name == activityStr,
      orElse: () => ProfileActivityLevel.active,
    );

    final conditionsList =
        (row['health_conditions'] as List<dynamic>?) ?? [];
    final healthConditions = conditionsList
        .map((c) =>
            ProfileHealthCondition.values.where((hc) => hc.name == c).firstOrNull)
        .whereType<ProfileHealthCondition>()
        .toSet();

    final plan = row['plan'] as String? ?? 'free';
    final avatarFrame = switch (plan.toLowerCase()) {
      'plus' => 'plusRing',
      'pro' || 'premium' => 'proHexagon',
      _ => 'none',
    };

    return ProfileSetupData(
      name: row['name'] as String? ?? '',
      username: row['username'] as String?,
      avatarUrl: row['avatar_url'] as String? ?? row['profile_image'] as String?,
      avatarFrame: avatarFrame,
      plan: plan,
      gender: gender,
      goals: goals,
      dateOfBirth: dob,
      heightCm: height,
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      activityLevel: activity,
      healthConditions: healthConditions.isEmpty
          ? {ProfileHealthCondition.none}
          : healthConditions,
      otherHealthCondition: row['other_health_condition'] as String?,
      mobile: row['mobile'] as String?,
      isMobileVerified:
          row['mobile_verified_at'] != null || row['is_mobile_verified'] == true,
    );
  }

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('User is not authenticated');
    }

    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final storagePath = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    // Normalize mime type: Supabase expects 'image/jpeg' for '.jpg' files
    final mimeType = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/$ext';

    await _client.storage.from('avatars').uploadBinary(
          storagePath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );
    final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);

    await _client.from('users').update({
      'avatar_url': publicUrl,
      'profile_image': publicUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);

    return publicUrl;
  }

  @override
  Future<void> deleteAvatarImage() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    await _client.from('users').update({
      'avatar_url': null,
      'profile_image': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Future<void> updateAvatarFrame(String frame) async {
    // avatar_frame is dynamically plan-based, no direct column mutation needed.
  }
}
