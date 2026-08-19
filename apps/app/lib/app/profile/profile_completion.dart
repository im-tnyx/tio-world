import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_feature_profile/profile.dart';

import '../network_providers.dart';

class ProfileCompletionReminderScope {
  const ProfileCompletionReminderScope({
    required this.userId,
    required this.loginCycleId,
  });

  final String userId;
  final String loginCycleId;

  String get storageValue => '$userId|$loginCycleId';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileCompletionReminderScope &&
            userId == other.userId &&
            loginCycleId == other.loginCycleId;
  }

  @override
  int get hashCode => Object.hash(userId, loginCycleId);
}

class ProfileCompletionReminderPreference {
  const ProfileCompletionReminderPreference();

  static const _dismissedScopeKey =
      'profile_completion_reminder_dismissed_scope_v1';

  Future<bool> isDismissed(ProfileCompletionReminderScope scope) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_dismissedScopeKey) == scope.storageValue;
  }

  Future<void> dismiss(ProfileCompletionReminderScope scope) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_dismissedScopeKey, scope.storageValue);
  }
}

final profileCompletionReminderPreferenceProvider =
    Provider<ProfileCompletionReminderPreference>((ref) {
  return const ProfileCompletionReminderPreference();
});

/// Reads only the persisted/auth fields that participate in the Profile
/// completion reminder. Display fallbacks in [ProfileSetupData] are deliberately
/// not used as evidence that Gender or DOB were actually supplied.
final profileCompletionSummaryProvider =
    FutureProvider<ProfileCompletionSummary?>((ref) async {
  ref.watch(authSessionStateProvider);
  final client = ref.watch(supabaseClientProvider);
  final user = client?.auth.currentUser;
  if (client == null || user == null || user.id.isEmpty) return null;

  final row = await client
      .from('users')
      .select('name,username,mobile,gender,date_of_birth')
      .eq('id', user.id)
      .maybeSingle();

  final gender = (row?['gender'] as String?)?.trim() ?? '';
  final dob = (row?['date_of_birth'] as String?)?.trim() ?? '';

  return ProfileCompletionSummary.fromFields(
    name: row?['name'] as String?,
    username: row?['username'] as String?,
    email: user.email,
    mobile: row?['mobile'] as String?,
    hasGender: gender.isNotEmpty,
    hasDateOfBirth: dob.isNotEmpty && DateTime.tryParse(dob) != null,
  );
});

/// Stable for token refreshes, but changes after a real Supabase sign-in.
final profileCompletionReminderScopeProvider =
    Provider<ProfileCompletionReminderScope?>((ref) {
  ref.watch(authSessionStateProvider);
  final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
  if (user == null || user.id.isEmpty) return null;

  final lastSignInAt = user.lastSignInAt?.trim();
  final loginCycleId = lastSignInAt != null && lastSignInAt.isNotEmpty
      ? lastSignInAt
      : user.createdAt;

  return ProfileCompletionReminderScope(
    userId: user.id,
    loginCycleId: loginCycleId,
  );
});

final profileCompletionReminderDismissedProvider =
    FutureProvider.family<bool, ProfileCompletionReminderScope>(
  (ref, scope) {
    final preference = ref.watch(profileCompletionReminderPreferenceProvider);
    return preference.isDismissed(scope);
  },
);
