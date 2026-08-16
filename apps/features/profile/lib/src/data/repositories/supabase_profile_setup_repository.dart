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
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Cannot persist profile setup: user is not authenticated.');
    }

    final currentUser = _client.auth.currentUser;
    final email = currentUser?.email;
    final phone = currentUser?.phone;
    final dobIso = data.dateOfBirth.toIso8601String().split('T').first;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = {
      'id': userId,
      'name': data.name,
      'username': data.username,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'mobile': phone,
      'avatar_url': data.avatarUrl,
      'avatar_frame': data.avatarFrame,
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
      'is_onboarded': true,
      'is_active': true,
      'last_active_at': nowIso,
      'updated_at': nowIso,
    };

    try {
      await _client.from('users').upsert(payload);
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        payload.remove('plan');
        payload.remove('dob');
        payload.remove('profile_image');
        payload.remove('is_onboarded');
        payload.remove('email');
        payload.remove('mobile');
        payload.remove('primary_goal');
        payload.remove('timezone');
        payload.remove('is_active');
        payload.remove('last_active_at');
        await _client.from('users').upsert(payload);
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return Stream.value(null);
    }

    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return _mapRowToProfile(rows.first);
        });
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
    final avatarFrame = row['avatar_frame'] as String? ?? 'none';

    return ProfileSetupData(
      name: row['name'] as String? ?? '',
      username: row['username'] as String?,
      avatarUrl: row['avatar_url'] as String?,
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    await _client.from('users').update({
      'avatar_frame': frame,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }
}
